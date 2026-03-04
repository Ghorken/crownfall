// lib/providers/game_provider.dart

import 'package:flutter/foundation.dart';
import 'package:crownfall/models/board.dart';
import 'package:crownfall/models/piece.dart';
import 'package:crownfall/models/piece_definitions.dart';
import 'package:crownfall/models/player_profile.dart';
import 'package:crownfall/services/movement_service.dart';
import 'package:crownfall/services/combat_service.dart';

enum GamePhase { myTurn, opponentTurn, combat, gameOver, waitingForOpponent }

enum TurnAction { none, moved, usedAbility }

class GameProvider extends ChangeNotifier {
  late Board board;
  late PlayerProfile myProfile;
  late PlayerProfile opponentProfile; // in local multiplayer

  GamePhase phase = GamePhase.myTurn;
  PlayerSide currentTurn = PlayerSide.player1;
  Position? selectedPosition;
  List<Position> validMoves = [];
  TurnAction turnAction = TurnAction.none;

  bool get canMove => turnAction == TurnAction.none || turnAction == TurnAction.usedAbility;
  bool get canUseAbility => turnAction == TurnAction.none || turnAction == TurnAction.moved;

  String? lastCombatLog;
  int myCoinsEarned = 0;

  GameProvider({required this.myProfile, required this.opponentProfile}) {
    _initBoard();
  }

  void _initBoard() {
    board = Board();
    _setupArmy(opponentProfile, PlayerSide.player2, isTop: true);
    _setupArmy(myProfile, PlayerSide.player1, isTop: false);
  }

  void _setupArmy(PlayerProfile profile, PlayerSide side, {required bool isTop}) {
    final config = profile.armyConfig;
    final pieces = <PieceType>[];
    config.composition.forEach((type, count) {
      for (int i = 0; i < count; i++) {
        pieces.add(type);
      }
    });

    // Posizionamento semplificato: pedoni in riga 2, resto in riga 1 (o specchiato)
    final pawnRow = isTop ? 1 : 6;
    final backRow = isTop ? 0 : 7;

    final pawns = pieces.where((t) => pieceDefinitions[t]!.baseType == PieceBaseType.pawn).toList();
    final backPieces = pieces.where((t) => pieceDefinitions[t]!.baseType != PieceBaseType.pawn).toList();

    for (int i = 0; i < pawns.length && i < 8; i++) {
      _placePiece(pawns[i], Position(pawnRow, i), side, profile);
    }

    // Ordine standard: torre, cavallo, alfiere, regina, re, alfiere, cavallo, torre
    final backOrder = [
      PieceBaseType.rook,
      PieceBaseType.knight,
      PieceBaseType.bishop,
      PieceBaseType.queen,
      PieceBaseType.king,
      PieceBaseType.bishop,
      PieceBaseType.knight,
      PieceBaseType.rook
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

  void selectPosition(Position pos) {
    final isMyTurn = (currentTurn == PlayerSide.player1 && phase == GamePhase.myTurn);
    if (!isMyTurn) return;

    final piece = board.getPiece(pos);

    // Se ho già selezionato un pezzo e clicco su una mossa valida
    if (selectedPosition != null && validMoves.contains(pos)) {
      _executeMove(selectedPosition!, pos);
      return;
    }

    // Seleziona il pezzo se è mio
    if (piece != null && piece.side == PlayerSide.player1 && canMove) {
      selectedPosition = pos;
      validMoves = MovementService.getValidMoves(board, pos);
    } else {
      selectedPosition = null;
      validMoves = [];
    }
    notifyListeners();
  }

  void _executeMove(Position from, Position to) {
    final attacker = board.getPiece(from)!;
    final defender = board.getPiece(to);

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

      lastCombatLog = _buildCombatLog(attacker, defender, result);
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

    // Controlla vittoria
    _checkGameOver();

    // Se il turno è completato (mossa + abilità usata o solo mossa)
    if (turnAction == TurnAction.moved) {
      _checkEndTurn();
    }

    notifyListeners();
  }

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

  void useAbility(Position piecePos) {
    if (!canUseAbility) return;
    final piece = board.getPiece(piecePos);
    if (piece == null || piece.side != PlayerSide.player1) return;
    if (piece.specialAbility == null || !piece.specialAbility!.isReady) return;

    // TODO: implementare effetti delle abilità specifiche
    // Per ora segnala solo che è stata usata
    turnAction = TurnAction.usedAbility;
    notifyListeners();
  }

  void endTurn() {
    _checkEndTurn();
  }

  void _checkEndTurn() {
    turnAction = TurnAction.none;
    currentTurn = currentTurn == PlayerSide.player1 ? PlayerSide.player2 : PlayerSide.player1;
    phase = currentTurn == PlayerSide.player1 ? GamePhase.myTurn : GamePhase.opponentTurn;

    // In local multiplayer, qui si passerebbe il controllo al player 2
    // In futuro: notifica server per multiplayer online
    notifyListeners();
  }

  void _checkGameOver() {
    final myKing = board.findKing(PlayerSide.player1);
    final oppKing = board.findKing(PlayerSide.player2);

    if (myKing == null) {
      phase = GamePhase.gameOver;
      myProfile.losses++;
      myProfile.coins += 10; // premio piccolo per la sconfitta
    } else if (oppKing == null) {
      phase = GamePhase.gameOver;
      myProfile.wins++;
      myProfile.coins += 200; // premio vittoria
    }
  }
}
