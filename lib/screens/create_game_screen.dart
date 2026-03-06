// lib/screens/create_game_screen.dart
//
// Schermata per il giocatore che crea la partita.
// Mostra il codice invito e attende che l'avversario si unisca.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:crownfall/models/piece.dart';
import 'package:crownfall/models/player_profile.dart';
import 'package:crownfall/providers/online_game_provider.dart';
import 'package:crownfall/screens/online_game_screen.dart';
import 'package:crownfall/services/auth_service.dart';
import 'package:crownfall/services/network_service.dart';
import 'package:crownfall/services/serialization_service.dart';

class CreateGameScreen extends StatefulWidget {
  const CreateGameScreen({super.key});

  @override
  State<CreateGameScreen> createState() => _CreateGameScreenState();
}

class _CreateGameScreenState extends State<CreateGameScreen> {
  String? _sessionId;
  String? _inviteCode;
  bool _loading = true;
  String? _error;
  StreamSubscription<SessionSnapshot>? _sub;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _createSession());
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _createSession() async {
    final profile = context.read<PlayerProfile>();
    try {
      final sessionId = await NetworkService.createSession(
        playerId: AuthService.currentUserId!,
        playerProfile: SerializationService.profileToJson(profile),
      );

      // Leggi il codice generato
      final stream = NetworkService.sessionStream(sessionId);
      final first = await stream.first;

      if (!mounted) return;
      setState(() {
        _sessionId = sessionId;
        _inviteCode = first.inviteCode;
        _loading = false;
      });

      // Ascolta finché player2 si unisce e la board è pronta
      _sub = stream.listen(_onSessionUpdate);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Errore nella creazione della sessione: $e';
        _loading = false;
      });
    }
  }

  void _onSessionUpdate(SessionSnapshot snapshot) {
    if (_navigated) return;
    if (snapshot.status == SessionStatus.active && snapshot.boardState != null) {
      _navigated = true;
      final profile = context.read<PlayerProfile>();
      final opponentProfile = snapshot.player2Profile != null
          ? SerializationService.profileFromJson(snapshot.player2Profile!)
          : PlayerProfile(name: 'Avversario');

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (_) => OnlineGameProvider(
              myRole: PlayerSide.player1,
              sessionId: snapshot.sessionId,
              myProfile: profile,
              opponentProfile: opponentProfile,
            ),
            child: const OnlineGameScreen(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('NUOVA PARTITA', style: TextStyle(color: Colors.amber, letterSpacing: 2)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: _loading
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.amber),
                    SizedBox(height: 16),
                    Text('Creazione partita...', style: TextStyle(color: Colors.white54)),
                  ],
                )
              : _error != null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 12),
                        Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                        const SizedBox(height: 20),
                        ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Indietro')),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Partita creata!',
                          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Condividi questo codice con il tuo avversario:',
                          style: TextStyle(color: Colors.white54, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // Codice invito grande
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: _inviteCode!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Codice copiato negli appunti!'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16213E),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.amber, width: 2),
                              boxShadow: [BoxShadow(color: Colors.amber.withValues(alpha: 0.2), blurRadius: 20)],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  _inviteCode ?? '------',
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 8,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.copy, color: Colors.white38, size: 14),
                                    SizedBox(width: 4),
                                    Text('Tocca per copiare', style: TextStyle(color: Colors.white38, fontSize: 11)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyan),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'In attesa dell\'avversario...',
                              style: TextStyle(color: Colors.cyan, fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}
