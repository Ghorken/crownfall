// lib/services/auth_service.dart
//
// Gestisce autenticazione Firebase (email + password).
// NOTA: Richiede che Firebase sia configurato nel progetto
//       tramite `flutterfire configure`.

import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;
  static String? get currentUserId => _auth.currentUser?.uid;
  static bool get isLoggedIn => _auth.currentUser != null;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Registrazione con email, password e nome display.
  static Future<UserCredential> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await cred.user?.updateDisplayName(displayName.trim());
    return cred;
  }

  /// Login con email e password.
  static Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Logout.
  static Future<void> signOut() => _auth.signOut();

  /// Messaggio di errore leggibile dall'utente.
  static String errorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Nessun account trovato con questa email.';
      case 'wrong-password':
        return 'Password errata.';
      case 'email-already-in-use':
        return 'Email già registrata. Prova ad accedere.';
      case 'invalid-email':
        return 'Email non valida.';
      case 'weak-password':
        return 'Password troppo debole (minimo 6 caratteri).';
      case 'network-request-failed':
        return 'Errore di rete. Controlla la connessione.';
      default:
        return 'Errore: ${e.message}';
    }
  }
}
