import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';

import '../../models/user_model.dart';
import '../utils/date_labels.dart';

/// Real Google Sign-In + Firebase Auth backend. Relies on Android's
/// `google-services.json` for OAuth client config — as long as Google Sign-In
/// was enabled for this Firebase project (which auto-creates the required web
/// OAuth client), no client ID needs to be passed here.
class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _googleSignIn.initialize();
    _initialized = true;
  }

  /// Passive, local-only lookup — no network call, no account picker.
  /// Firebase Auth persists the signed-in user across app restarts on its
  /// own, independent of Google Sign-In's own session, so app launch should
  /// read this instead of re-running the interactive [signInWithGoogle].
  UserModel? currentCachedUser() {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final name = user.displayName ?? '';
    return UserModel(
      id: user.uid,
      name: name,
      email: user.email ?? '',
      initials: DateLabels.initialsOf(name),
    );
  }

  Future<UserModel> signInWithGoogle() async {
    await _ensureInitialized();

    final account = await _googleSignIn.authenticate();
    final idToken = account.authentication.idToken;
    final credential = firebase_auth.GoogleAuthProvider.credential(
      idToken: idToken,
    );
    final userCredential = await firebase_auth.FirebaseAuth.instance
        .signInWithCredential(credential);
    final user = userCredential.user!;
    final name = user.displayName ?? account.displayName ?? '';

    return UserModel(
      id: user.uid,
      name: name,
      email: user.email ?? account.email,
      initials: DateLabels.initialsOf(name),
    );
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await firebase_auth.FirebaseAuth.instance.signOut();
  }

  /// Permanently deletes the Firebase Auth user. Account deletion is a
  /// sensitive operation Firebase only allows on a *recent* sign-in — if the
  /// session has aged out, silently re-run the Google sign-in flow to get a
  /// fresh credential and retry once before giving up.
  Future<void> deleteAccount() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await user.delete();
    } on firebase_auth.FirebaseAuthException catch (error) {
      if (error.code != 'requires-recent-login') rethrow;
      await _ensureInitialized();
      final account = await _googleSignIn.authenticate();
      final credential = firebase_auth.GoogleAuthProvider.credential(
        idToken: account.authentication.idToken,
      );
      await user.reauthenticateWithCredential(credential);
      await user.delete();
    }
    await _googleSignIn.signOut();
  }
}
