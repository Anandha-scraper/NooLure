import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';

import '../../models/user_model.dart';
import '../utils/date_labels.dart';

/// Real Google Sign-In + Firebase Auth backend. Relies on Android's
/// `google-services.json` for the Android OAuth client (matched by package
/// name + signing certificate), but the Web client id below must still be
/// passed explicitly — see [_serverClientId].
class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _initialized = false;

  // The "Web client (auto created by Google Service)" id from
  // google-services.json's client_type: 3 entry. Unlike the legacy
  // google_sign_in API, the Credential Manager-based v7 API doesn't
  // auto-detect this from google-services.json on Android — omitting it
  // throws GoogleSignInExceptionCode.clientConfigurationError
  // ("serverClientId must be provided on Android") on every sign-in attempt.
  static const _serverClientId =
      '429362243986-jfk698b540vkopr0bgp7q8b4u8nd31cs.apps.googleusercontent.com';

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _googleSignIn.initialize(serverClientId: _serverClientId);
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
