import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Thrown when sign-in fails. [message] is a user-facing Turkish string that is
/// safe to show directly.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => 'AuthException: $message';
}

/// Wraps Firebase Auth for the email + password login model and exposes the
/// signed-in state as a [ChangeNotifier] so the UI can gate on it via provider.
///
/// The session is persisted by Firebase, so the user signs in once and stays
/// signed in across app launches. [isReady] flips true once the first auth
/// event arrives, letting the UI show a splash instead of a login flash while
/// the persisted session rehydrates on cold start.
class AuthService extends ChangeNotifier {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance {
    _user = _auth.currentUser;
    _sub = _auth.authStateChanges().listen(_onAuthChanged);
  }

  final FirebaseAuth _auth;
  late final StreamSubscription<User?> _sub;

  User? _user;
  bool _ready = false;

  /// Whether the persisted session has been restored at least once.
  bool get isReady => _ready;

  /// The currently signed-in user, or null.
  User? get user => _user;

  bool get isSignedIn => _user != null;

  void _onAuthChanged(User? user) {
    _user = user;
    _ready = true;
    notifyListeners();
  }

  /// Sign into Firebase with an email + password. The session is persisted, so
  /// this is only needed once. Throws [AuthException] with a Turkish message on
  /// any failure.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    } catch (_) {
      throw const AuthException('Giriş yapılamadı. Bağlantını kontrol et.');
    }
  }

  Future<void> signOut() => _auth.signOut();

  String _messageFor(FirebaseAuthException e) {
    switch (e.code) {
      case 'network-request-failed':
        return 'İnternet bağlantısı yok.';
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'E-posta veya şifre hatalı.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi.';
      case 'too-many-requests':
        return 'Çok fazla deneme. Biraz sonra tekrar dene.';
      case 'user-disabled':
        return 'Bu hesap devre dışı.';
      default:
        return 'Giriş yapılamadı. Tekrar dene.';
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
