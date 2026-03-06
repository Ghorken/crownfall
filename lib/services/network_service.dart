// lib/services/network_service.dart
//
// Gestisce tutte le operazioni Firestore per il multiplayer online:
// - Creazione e join di sessioni di gioco
// - Stream real-time sulla sessione attiva
// - Invio mosse e aggiornamento stato

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crownfall/models/board.dart';
import 'package:crownfall/services/serialization_service.dart';

/// Stato di una sessione online.
enum SessionStatus { waiting, active, finished }

/// Snapshot di una sessione letto da Firestore.
class SessionSnapshot {
  final String sessionId;
  final String inviteCode;
  final SessionStatus status;
  final String player1Id;
  final String? player2Id;
  final Map<String, dynamic>? player1Profile;
  final Map<String, dynamic>? player2Profile;
  final String currentTurn; // "player1" | "player2"
  final List<dynamic>? boardState; // null finché la partita non inizia
  final Map<String, dynamic>? lastAction;
  final String? winner; // "player1" | "player2" | null

  const SessionSnapshot({
    required this.sessionId,
    required this.inviteCode,
    required this.status,
    required this.player1Id,
    this.player2Id,
    this.player1Profile,
    this.player2Profile,
    required this.currentTurn,
    this.boardState,
    this.lastAction,
    this.winner,
  });

  factory SessionSnapshot.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SessionSnapshot(
      sessionId: doc.id,
      inviteCode: d['inviteCode'] as String,
      status: _parseStatus(d['status'] as String),
      player1Id: d['player1Id'] as String,
      player2Id: d['player2Id'] as String?,
      player1Profile: d['player1Profile'] != null
          ? Map<String, dynamic>.from(d['player1Profile'] as Map)
          : null,
      player2Profile: d['player2Profile'] != null
          ? Map<String, dynamic>.from(d['player2Profile'] as Map)
          : null,
      currentTurn: d['currentTurn'] as String? ?? 'player1',
      boardState: d['boardState'] as List<dynamic>?,
      lastAction: d['lastAction'] != null
          ? Map<String, dynamic>.from(d['lastAction'] as Map)
          : null,
      winner: d['winner'] as String?,
    );
  }

  static SessionStatus _parseStatus(String s) => switch (s) {
        'waiting' => SessionStatus.waiting,
        'active' => SessionStatus.active,
        'finished' => SessionStatus.finished,
        _ => SessionStatus.waiting,
      };
}

class NetworkService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─────────────────────────────────────────────
  // CREA SESSIONE (Player 1)
  // ─────────────────────────────────────────────

  /// Crea una nuova sessione e ritorna [sessionId].
  /// Il board iniziale viene lasciato null finché player2 non si unisce.
  static Future<String> createSession({
    required String playerId,
    required Map<String, dynamic> playerProfile,
  }) async {
    final inviteCode = _generateInviteCode();
    final ref = await _db.collection('sessions').add({
      'inviteCode': inviteCode,
      'status': 'waiting',
      'player1Id': playerId,
      'player2Id': null,
      'player1Profile': playerProfile,
      'player2Profile': null,
      'currentTurn': 'player1',
      'boardState': null,
      'lastAction': null,
      'winner': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  // ─────────────────────────────────────────────
  // UNISCITI ALLA SESSIONE (Player 2)
  // ─────────────────────────────────────────────

  /// Cerca una sessione con [inviteCode] in attesa e vi si unisce.
  /// Ritorna il [SessionSnapshot] o null se non trovata.
  static Future<SessionSnapshot?> joinSession({
    required String inviteCode,
    required String playerId,
    required Map<String, dynamic> playerProfile,
  }) async {
    final query = await _db
        .collection('sessions')
        .where('inviteCode', isEqualTo: inviteCode.trim().toUpperCase())
        .where('status', isEqualTo: 'waiting')
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    final doc = query.docs.first;
    await doc.reference.update({
      'player2Id': playerId,
      'player2Profile': playerProfile,
      'status': 'active', // player1 riceverà l'update e genererà la board
    });

    // Rilegge il documento aggiornato
    final updated = await doc.reference.get();
    return SessionSnapshot.fromDoc(updated);
  }

  // ─────────────────────────────────────────────
  // INIZIALIZZA BOARD (Player 1, dopo che P2 si è unito)
  // ─────────────────────────────────────────────

  /// Scrive la board iniziale quando player2 si è appena unito.
  static Future<void> initializeBoard({
    required String sessionId,
    required Board board,
  }) async {
    await _db.collection('sessions').doc(sessionId).update({
      'boardState': SerializationService.boardToJson(board),
    });
  }

  // ─────────────────────────────────────────────
  // INVIA MOSSA
  // ─────────────────────────────────────────────

  static Future<void> sendMove({
    required String sessionId,
    required Position from,
    required Position to,
    required Board newBoard,
    required String nextTurn, // "player1" | "player2"
    String? combatLog,
  }) async {
    await _db.collection('sessions').doc(sessionId).update({
      'boardState': SerializationService.boardToJson(newBoard),
      'currentTurn': nextTurn,
      'lastAction': {
        'type': 'move',
        'from': {'row': from.row, 'col': from.col},
        'to': {'row': to.row, 'col': to.col},
        'combatLog': combatLog,
        'timestamp': FieldValue.serverTimestamp(),
      },
    });
  }

  // ─────────────────────────────────────────────
  // FINE PARTITA
  // ─────────────────────────────────────────────

  static Future<void> setWinner({
    required String sessionId,
    required String winner, // "player1" | "player2"
  }) async {
    await _db.collection('sessions').doc(sessionId).update({
      'winner': winner,
      'status': 'finished',
    });
  }

  // ─────────────────────────────────────────────
  // STREAM REAL-TIME
  // ─────────────────────────────────────────────

  static Stream<SessionSnapshot> sessionStream(String sessionId) {
    return _db
        .collection('sessions')
        .doc(sessionId)
        .snapshots()
        .where((doc) => doc.exists)
        .map(SessionSnapshot.fromDoc);
  }

  // ─────────────────────────────────────────────
  // UTILITIES
  // ─────────────────────────────────────────────

  static String _generateInviteCode() {
    // 6 caratteri alfanumerici, escluse lettere/numeri ambigui
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }
}
