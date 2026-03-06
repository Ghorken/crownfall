// lib/screens/join_game_screen.dart
//
// Schermata per il giocatore che si unisce con un codice invito.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crownfall/models/piece.dart';
import 'package:crownfall/models/player_profile.dart';
import 'package:crownfall/providers/online_game_provider.dart';
import 'package:crownfall/screens/online_game_screen.dart';
import 'package:crownfall/services/auth_service.dart';
import 'package:crownfall/services/network_service.dart';
import 'package:crownfall/services/serialization_service.dart';

class JoinGameScreen extends StatefulWidget {
  const JoinGameScreen({super.key});

  @override
  State<JoinGameScreen> createState() => _JoinGameScreenState();
}

class _JoinGameScreenState extends State<JoinGameScreen> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length != 6) {
      setState(() => _error = 'Il codice deve essere di 6 caratteri.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final profile = context.read<PlayerProfile>();

    try {
      final snapshot = await NetworkService.joinSession(
        inviteCode: code,
        playerId: AuthService.currentUserId!,
        playerProfile: SerializationService.profileToJson(profile),
      );

      if (snapshot == null) {
        if (!mounted) return;
        setState(() {
          _error = 'Codice non trovato o partita già iniziata.';
          _loading = false;
        });
        return;
      }

      // Recupera il profilo di player1
      final p1Profile = snapshot.player1Profile != null
          ? SerializationService.profileFromJson(snapshot.player1Profile!)
          : PlayerProfile(name: 'Avversario');

      if (!mounted) return;

      // Naviga alla schermata di gioco online
      // La board verrà inizializzata da player1: aspettiamo via stream
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (_) => OnlineGameProvider(
              myRole: PlayerSide.player2,
              sessionId: snapshot.sessionId,
              myProfile: profile,
              opponentProfile: p1Profile,
            ),
            child: const OnlineGameScreen(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Errore: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('UNISCITI', style: TextStyle(color: Colors.cyan, letterSpacing: 2)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.link, color: Colors.cyan, size: 56),
              const SizedBox(height: 16),
              const Text(
                'Inserisci il codice',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Chiedi il codice al tuo avversario e inseriscilo qui sotto.',
                style: TextStyle(color: Colors.white54, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Input codice
              TextField(
                controller: _codeCtrl,
                textCapitalization: TextCapitalization.characters,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                  fontFamily: 'monospace',
                ),
                decoration: InputDecoration(
                  hintText: 'ABC123',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.15), fontSize: 32, letterSpacing: 8),
                  counterText: '',
                  filled: true,
                  fillColor: const Color(0xFF16213E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.cyan, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.cyan.withValues(alpha: 0.5), width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.cyan, width: 2),
                  ),
                ),
                onChanged: (_) => setState(() => _error = null),
                onSubmitted: (_) => _join(),
              ),

              const SizedBox(height: 16),

              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13), textAlign: TextAlign.center),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _join,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Text('UNISCITI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 2)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
