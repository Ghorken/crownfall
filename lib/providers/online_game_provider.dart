// lib/providers/online_game_provider.dart
//
// Provider per la partita online contro un avversario specifico.
// Sincronizza lo stato della partita con Firestore in tempo reale.
//
// Differenze rispetto a GameProvider (locale):
//  - Ogni giocatore controlla solo i propri pezzi (myRole)
//  - Le mosse vengono inviate a Firestore invece di essere applicate direttamente
//  - Lo stream Firestore aggiorna la board quando l'avversario muove
//  - Player1 genera la board iniziale quando player2 si unisce

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:crownfall/models/board.dart';
import 'package:crownfall/models/piece.dart';
import 'package:crownfall/models/piece_definitions.dart';
import 'package:crownfall/models/player_profile.dart';
import 'package:crownfall/providers/game_provider.dart';
import 'package:crownfall/services/combat_service.dart';
import 'package:crownfall/services/movement_service.dart';
import 'package:crownfall/services/network_service.dart';
import 'package:crownfall/services/serialization_service.dart';

class OnlineGameProvider extends ChangeNotifier {
  // ─── Identità ────────────────────────────────
  final PlayerSide myRole; // player1 o player2
  final String sessionId;

  // ─── Profili ─────────────────────────────────
  final PlayerProfile myProfile;
  PlayerProfile opponentProfile;

  // ─── Stato partita ────────────────────────────
  late Board board;
  GamePhase phase;
  PlayerSide currentTurn;
  Position? selectedPosition;
  List<Position> validMoves = [];
  TurnAction turnAction = TurnAction.none;
  String? lastCombatLog;
  int myCoinsEarned = 0;
  bool boardReady = false; // true quando la board è stata inizializzata
  bool opponentDisconnected = false;

  StreamSubscription<SessionSnapshot>? _sessionSub;
  String? _lastActionTimestamp; // per evitare di processare lo stesso evento due volte

  OnlineGameProvider({
    required this.myRole,
    required this.sessionId,
    required this.myProfile,
    required this.opponentProfile,
  })  : board = Board(),
        currentTurn = PlayerSide.player1,
        phase = GamePhase.waitingForOpponent {
    _listenToSession();
  }

  // ─── Getters utili ────────────────────────────

  bool get isMyTurn => currentTurn == myRole && phase != GamePhase.waitingForOpponent && phase != GamePhase.gameOver && boardReady;
  bool get canMove => isMyTurn && (turnAction == TurnAction.none || turnAction == TurnAction.usedAbility);
  bool get canUseAbility => isMyTurn && (turnAction == TurnAction.none || turnAction == TurnAction.moved);

  // Il lato "in basso" nella UI è sempre il mio lato
  PlayerSide get bottomSide => myRole;
  PlayerSide get topSide => myRole == PlayerSide.player1 ? PlayerSide.player2 : PlayerSide.player1;

  // ─── Stream Firestore ─────────────────────────

  void _listenToSession() {
    _sessionSub = NetworkService.sessionStream(sessionId).listen(
      _onSessionUpdate,
      onError: (e) {
        opponentDisconnected = true;
        notifyListeners();
      },
    );
  }

  void _onSessionUpdate(SessionSnapshot snapshot) {
    // Partita finita da server
    if (snapshot.status == SessionStatus.finished && snapshot.winner != null) {
      _applyGameOver(snapshot.winner!);
      return;
    }

    // Player2 si è appena unito: player1 genera la board e la scrive su Firestore
    if (myRole == PlayerSide.player1 &&
        snapshot.status == SessionStatus.active &&
        snapshot.player2Profile != null &&
        snapshot.boardState == null) {
      _initializeBoardAsPlayer1(snapshot);
      return;
    }

    // Board pronta: aggiorna stato locale
    if (snapshot.boardState != null) {
      final newBoard = SerializationService.boardFromJson(snapshot.boardState!);
      board = newBoard;
      boardReady = true;

      // Aggiorna il profilo avversario se è arrivato
      if (myRole == PlayerSide.player1 && snapshot.player2Profile != null) {
        opponentProfile = SerializationService.profileFromJson(snapshot.player2Profile!);
      }

      // Determina di chi è il turno
      currentTurn = snapshot.currentTurn == 'player1' ? PlayerSide.player1 : PlayerSide.player2;
      if (snapshot.winner != null) {
        _applyGameOver(snapshot.winner!);
        return;
      }

      // Aggiorna log combattimento se c'è una nuova azione
      final actionTs = snapshot.lastAction?['timestamp']?.toString();
      if (actionTs != _lastActionTimestamp && snapshot.lastAction != null) {
        _lastActionTimestamp = actionTs;
        final log = snapshot.lastAction?['combatLog'] as String?;
        if (log != null) lastCombatLog = log;
      }

      // Aggiorna la fase
      if (currentTurn == myRole) {
        phase = GamePhase.myTurn;
        turnAction = TurnAction.none;
        selectedPosition = null;
        validMoves = [];
      } else {
        phase = GamePhase.waitingForOpponent;
      }

      notifyListeners();
    }
  }

  /// Player1 costruisce la board con entrambi gli eserciti e la scrive su Firestore.
  Future<void> _initializeBoardAsPlayer1(SessionSnapshot snapshot) async {
    final p2Profile = SerializationService.profileFromJson(snapshot.player2Profile!);
    opponentProfile = p2Profile;

    board = Board();
    _setupArmy(myProfile, PlayerSide.player1, isTop: false);
    _setupArmy(opponentProfile, PlayerSide.player2, isTop: true);
    boardReady = true;

    await NetworkService.initializeBoard(sessionId: sessionId, board: board);

    currentTurn = PlayerSide.player1;
    phase = GamePhase.myTurn;
    turnAction = TurnAction.none;
    notifyListeners();
  }

  // ─── Setup esercito (identico a GameProvider) ─

  void _setupArmy(PlayerProfile profile, PlayerSide side, {required bool isTop}) {
    final config = profile.armyConfig;
    final pieces = <PieceType>[];
    config.composition.forEach((type, count) {
      for (int i = 0; i < count; i++) {
        pieces.add(type);
      }
    });

    final pawnRow = isTop ? 1 : 6;
    final backRow = isTop ? 0 : 7;

    final pawns = pieces.where((t) => pieceDefinitions[t]!.baseType == PieceBaseType.pawn).toList();
    final backPieces = pieces.where((t) => pieceDefinitions[t]!.baseType != PieceBaseType.pawn).toList();

    for (int i = 0; i < pawns.length && i < 8; i++) {
      _placePiece(pawns[i], Position(pawnRow, i), side, profile);
    }

    final backOrder = [
      PieceBaseType.rook,
      PieceBaseType.knight,
      PieceBaseType.bishop,
      PieceBaseType.queen,
      PieceBaseType.king,
      PieceBaseType.bishop,
      PieceBaseType.knight,
      PieceBaseType.rook,
    ];

    int backIdx = 0;
    for (final baseType in backOrder) {
      final match = backPieces.firstWhere(
        (t) => pieceDefinitions[t]!.baseType == baseType,
        orElse: () => _defaultForBase(baseType),
      );
      if (backIdx < 8) {
        _placePiece(match, Position(backRow, backIdx), side, profile);
        backPieces.remove(match);
        backIdx++;
      }
    }
  }

  PieceType _defaultForBase(PieceBaseType base) => switch (base) {
        PieceBaseType.pawn => PieceType.pawn,
        PieceBaseType.rook => PieceType.rook,
        PieceBaseType.knight => PieceType.knight,
        PieceBaseType.bishop => PieceType.bishop,
        PieceBaseType.queen => PieceType.queen,
        PieceBaseType.king => PieceType.king,
      };

  void _placePiece(PieceType type, Position pos, PlayerSide side, PlayerProfile profile) {
    final def = pieceDefinitions[type]!;
    final stats = profile.getStatsForPiece(type);
    final piece = Piece(
      id: '${side.name}_${type.name}_${pos.row}_${pos.col}',
      type: type,
      baseType: def.baseType,
      side: side,
      stats: stats,
      specialAbility: def.abilityFactory?.call(),
    );
    board.setPiece(pos, piece);
  }

  // ─── Interazione utente ───────────────────────

  void selectPosition(Position pos) {
    if (!isMyTurn) return;
    if (!boardReady) return;

    final piece = board.getPiece(pos);

    // Esegui la mossa se la destinazione è valida
    if (selectedPosition != null && validMoves.contains(pos)) {
      _executeAndSendMove(selectedPosition!, pos);
      return;
    }

    // Seleziona il pezzo se appartiene a me
    if (piece != null && piece.side == myRole && canMove) {
      selectedPosition = pos;
      validMoves = MovementService.getValidMoves(board, pos);
    } else {
      selectedPosition = null;
      validMoves = [];
    }
    notifyListeners();
  }

  Future<void> _executeAndSendMove(Position from, Position to) async {
    final attacker = board.getPiece(from)!;
    final defender = board.getPiece(to);
    String? combatLog;

    if (defender != null && defender.side != attacker.side) {
      // COMBATTIMENTO
      final result = CombatService.resolveCombat(
        attacker: attacker,
        defender: defender,
        attackerPos: from,
        defenderPos: to,
        board: board,
      );

      myCoinsEarned += result.coinsEarned;
      myProfile.coins += result.coinsEarned;

      board.setPiece(from, null);
      board.setPiece(to, null);

      if (result.survivingDefender != null) {
        board.setPiece(to, result.survivingDefender);
      }
      if (result.survivingAttacker != null && result.attackerNewPosition != null) {
        board.setPiece(result.attackerNewPosition!, result.survivingAttacker);
      }

      combatLog = _buildCombatLog(attacker, defender, result);
      lastCombatLog = combatLog;
    } else {
      // SPOSTAMENTO SEMPLICE
      board.movePiece(from, to);
      final movedPiece = board.getPiece(to);
      if (movedPiece != null) {
        board.setPiece(to, movedPiece.copyWith(hasMoved: true));
      }
    }

    selectedPosition = null;
    validMoves = [];
    turnAction = TurnAction.moved;

    // Controlla fine partita localmente
    final gameOverWinner = _checkGameOverWinner();
    if (gameOverWinner != null) {
      phase = GamePhase.gameOver;
      notifyListeners();
      // Aggiorna Firestore con vincitore
      await NetworkService.setWinner(sessionId: sessionId, winner: gameOverWinner);
      return;
    }

    // Passa il turno all'avversario su Firestore
    final nextTurn = myRole == PlayerSide.player1 ? 'player2' : 'player1';
    phase = GamePhase.waitingForOpponent;
    notifyListeners();

    await NetworkService.sendMove(
      sessionId: sessionId,
      from: from,
      to: to,
      newBoard: board,
      nextTurn: nextTurn,
      combatLog: combatLog,
    );
  }

  void useAbility(Position piecePos) {
    if (!canUseAbility) return;
    final piece = board.getPiece(piecePos);
    if (piece == null || piece.side != myRole) return;
    if (piece.specialAbility == null || !piece.specialAbility!.isReady) return;

    // TODO: implementare effetti delle abilità e sincronizzarli
    turnAction = TurnAction.usedAbility;
    notifyListeners();
  }

  Future<void> endTurn() async {
    if (!isMyTurn) return;
    final nextTurn = myRole == PlayerSide.player1 ? 'player2' : 'player1';
    phase = GamePhase.waitingForOpponent;
    turnAction = TurnAction.none;
    notifyListeners();

    await NetworkService.sendMove(
      sessionId: sessionId,
      from: const Position(0, 0), // placeholder per "fine turno senza mossa"
      to: const Position(0, 0),
      newBoard: board,
      nextTurn: nextTurn,
    );
  }

  // ─── Controlli fine partita ───────────────────

  String? _checkGameOverWinner() {
    final p1King = board.findKing(PlayerSide.player1);
    final p2King = board.findKing(PlayerSide.player2);
    if (p1King == null) return 'player2';
    if (p2King == null) return 'player1';
    return null;
  }

  void _applyGameOver(String winnerStr) {
    phase = GamePhase.gameOver;
    final iWon = (winnerStr == 'player1' && myRole == PlayerSide.player1) ||
        (winnerStr == 'player2' && myRole == PlayerSide.player2);
    if (iWon) {
      myProfile.wins++;
      myProfile.coins += 200;
    } else {
      myProfile.losses++;
      myProfile.coins += 10;
    }
    notifyListeners();
  }

  // ─── Log combattimento ────────────────────────

  String _buildCombatLog(Piece attacker, Piece defender, CombatResult result) {
    if (result.survivingAttacker == null && result.survivingDefender == null) {
      return 'Entrambi i pezzi si sono eliminati!';
    } else if (result.survivingAttacker != null && result.survivingDefender == null) {
      return '${pieceDefinitions[attacker.type]!.displayName} ha eliminato '
          '${pieceDefinitions[defender.type]!.displayName}! +${result.coinsEarned} monete';
    } else if (result.survivingAttacker == null) {
      return '${pieceDefinitions[defender.type]!.displayName} ha respinto l\'attacco!';
    } else {
      return 'Scontro! Entrambi i pezzi sopravvivono.';
    }
  }

  @override
  void dispose() {
    _sessionSub?.cancel();
    super.dispose();
  }
}
