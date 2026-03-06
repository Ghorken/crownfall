// lib/screens/online_menu_screen.dart
//
// Punto di ingresso per il multiplayer online.
// Gestisce login/registrazione e mostra la scelta
// tra "Crea partita" e "Unisciti".

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crownfall/models/player_profile.dart';
import 'package:crownfall/services/auth_service.dart';
import 'package:crownfall/screens/create_game_screen.dart';
import 'package:crownfall/screens/join_game_screen.dart';

class OnlineMenuScreen extends StatefulWidget {
  const OnlineMenuScreen({super.key});

  @override
  State<OnlineMenuScreen> createState() => _OnlineMenuScreenState();
}

class _OnlineMenuScreenState extends State<OnlineMenuScreen> {
  bool _showRegister = false;
  bool _loading = false;
  String? _error;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  // ─── Auth handlers ────────────────────────────

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_showRegister) {
        await AuthService.register(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
          displayName: _nameCtrl.text,
        );
      } else {
        await AuthService.signIn(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = AuthService.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    await AuthService.signOut();
    setState(() {});
  }

  // ─── Build ────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('GIOCA ONLINE', style: TextStyle(color: Colors.amber, letterSpacing: 2)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (AuthService.isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: _signOut,
            ),
        ],
      ),
      body: AuthService.isLoggedIn ? _buildLobby(context) : _buildAuthForm(),
    );
  }

  // ─── Lobby (utente loggato) ───────────────────

  Widget _buildLobby(BuildContext context) {
    final profile = context.watch<PlayerProfile>();
    final user = AuthService.currentUser!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi, color: Colors.green, size: 48),
            const SizedBox(height: 12),
            Text(
              'Ciao, ${user.displayName ?? profile.name}!',
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              user.email ?? '',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 40),

            // Crea partita
            _LobbyButton(
              icon: Icons.add_circle_outline,
              label: 'CREA PARTITA',
              subtitle: 'Genera un codice e invita un amico',
              color: Colors.amber,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider<PlayerProfile>.value(
                    value: profile,
                    child: const CreateGameScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Unisciti
            _LobbyButton(
              icon: Icons.login,
              label: 'UNISCITI CON CODICE',
              subtitle: 'Inserisci il codice del tuo avversario',
              color: Colors.cyan,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider<PlayerProfile>.value(
                    value: profile,
                    child: const JoinGameScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Form login/registrazione ─────────────────

  Widget _buildAuthForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          const Icon(Icons.lock_outline, color: Colors.amber, size: 56),
          const SizedBox(height: 16),
          Text(
            _showRegister ? 'Crea account' : 'Accedi',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),

          if (_showRegister) ...[
            _Field(controller: _nameCtrl, label: 'Nome utente', icon: Icons.person),
            const SizedBox(height: 12),
          ],
          _Field(controller: _emailCtrl, label: 'Email', icon: Icons.email, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 12),
          _Field(controller: _passwordCtrl, label: 'Password', icon: Icons.lock, obscure: true),
          const SizedBox(height: 8),

          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13), textAlign: TextAlign.center),
            ),

          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(
                      _showRegister ? 'REGISTRATI' : 'ACCEDI',
                      style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => setState(() {
              _showRegister = !_showRegister;
              _error = null;
            }),
            child: Text(
              _showRegister ? 'Hai già un account? Accedi' : 'Non hai un account? Registrati',
              style: const TextStyle(color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets locali ───────────────────────────────

class _LobbyButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _LobbyButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color.withValues(alpha: 0.6), size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white38),
        filled: true,
        fillColor: const Color(0xFF16213E),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white24)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white24)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.amber)),
      ),
    );
  }
}
