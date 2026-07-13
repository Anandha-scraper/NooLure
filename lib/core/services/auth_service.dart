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
}
