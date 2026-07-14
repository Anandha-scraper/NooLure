import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/data/local_store.dart';
import '../core/data/sync_service.dart';
import '../core/services/auth_service.dart';
import '../models/user_model.dart';

enum AuthStatus { unknown, unauthenticated, authenticating, authenticated }

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? authService})
    : _authService = authService ?? AuthService() {
    _restoreSession();
  }

  final AuthService _authService;
  static const _sessionKey = 'noolure_signed_in';
  static const _displayNameKey = 'noolure_display_name';

  AuthStatus status = AuthStatus.unknown;
  UserModel? currentUser;
  String? errorMessage;

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final signedIn = prefs.getBool(_sessionKey) ?? false;
    // A passive local lookup, not the interactive Google Sign-In flow — this
    // is what makes "stay logged in" actually mean once, not every launch.
    final cachedUser = signedIn ? _authService.currentCachedUser() : null;
    if (cachedUser != null) {
      var user = cachedUser;
      // A name edited in Profile is a local override of whatever the
      // identity provider reports, so it has to outlive the session.
      final savedName = prefs.getString(_displayNameKey);
      if (savedName != null && savedName.isNotEmpty) {
        user = user.copyWith(name: savedName);
      }
      currentUser = user;
      await SyncService.instance.bind(user.id);
      status = AuthStatus.authenticated;
    } else {
      if (signedIn) {
        // Our flag says signed in, but Firebase has no cached session —
        // a real reinstall or cleared app storage. Drop the stale flag so
        // this doesn't loop; the user gets exactly one real sign-in prompt.
        await prefs.setBool(_sessionKey, false);
      }
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    status = AuthStatus.authenticating;
    errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.signInWithGoogle();
      currentUser = user;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_sessionKey, true);

      // No-op unless a Firebase config is present; local data is already usable.
      await SyncService.instance.bind(user.id);

      status = AuthStatus.authenticated;
    } catch (e) {
      // Without this, any failure (dialog cancelled, no cached Google
      // credential, network hiccup) leaves `status` stuck at
      // `authenticating` forever — AuthGate shows a spinner with no way
      // back to the login button, so a retry is impossible.
      debugPrint('Google sign-in failed: $e');
      status = AuthStatus.unauthenticated;
      // In release builds testers only ever see this snackbar, with no way
      // to relay a stack trace — so in debug/profile builds the raw error
      // (e.g. an ApiException: 10 SHA-1 mismatch) rides along in the
      // message instead of disappearing into debugPrint alone.
      errorMessage = kReleaseMode
          ? 'Sign-in failed. Please try again.'
          : 'Sign-in failed: $e';
    }
    notifyListeners();
  }

  void clearError() {
    errorMessage = null;
  }

  Future<void> updateName(String name) async {
    final user = currentUser;
    final trimmed = name.trim();
    if (user == null || trimmed.isEmpty) return;
    currentUser = user.copyWith(name: trimmed);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_displayNameKey, trimmed);
  }

  Future<void> signOut() async {
    await _authService.signOut();
    await SyncService.instance.unbind();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sessionKey, false);
    currentUser = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Permanently deletes the account and all of its data — remote mirror
  /// first (while still authenticated enough for the `auth.uid === $uid`
  /// rule to allow it), then local, then the identity itself.
  Future<void> deleteAccount() async {
    final user = currentUser;
    if (user == null) return;

    await SyncService.instance.deleteRemoteUserData(user.id);
    await LocalStore.clearAll();
    await _authService.deleteAccount();
    await SyncService.instance.unbind();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sessionKey, false);
    await prefs.remove(_displayNameKey);

    currentUser = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
