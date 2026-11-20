import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/data/local_store.dart';
import '../core/data/sync_service.dart';
import '../core/data/trip_sync_service.dart';
import '../core/services/auth_service.dart';
import '../models/user_model.dart';
import '../core/utils/date_labels.dart';
import '../core/security/biometric_vault.dart';

enum AuthStatus { unknown, unauthenticated, authenticating, authenticated }

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? authService})
    : _authService = authService ?? AuthService() {
    _restoreSession();
  }

  final AuthService _authService;
  static const _sessionKey = 'noolure_signed_in';
  static const _displayNameKey = 'noolure_display_name';
  static const _cachedIdKey = 'noolure_cached_uid';
  static const _cachedEmailKey = 'noolure_cached_email';

  AuthStatus status = AuthStatus.unknown;
  UserModel? currentUser;
  String? errorMessage;

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final signedIn = prefs.getBool(_sessionKey) ?? false;
    // A passive local lookup, not the interactive Google Sign-In flow — this
    // is what makes "stay logged in" actually mean once, not every launch.
    var cachedId = prefs.getString(_cachedIdKey);
    if (signedIn && cachedId == null) {
      await SyncService.instance.init();
      final legacyUser = _authService.currentCachedUser();
      if (legacyUser != null) {
        cachedId = legacyUser.id;
        await prefs.setString(_cachedIdKey, legacyUser.id);
        await prefs.setString(_cachedEmailKey, legacyUser.email);
        await prefs.setString(_displayNameKey, legacyUser.name);
      }
    }
    final cachedUser = signedIn && cachedId != null
        ? UserModel(
            id: cachedId,
            name: prefs.getString(_displayNameKey) ?? '',
            email: prefs.getString(_cachedEmailKey) ?? '',
            initials: DateLabels.initialsOf(
              prefs.getString(_displayNameKey) ?? '',
            ),
          )
        : null;
    debugPrint(
      'NooLure: restoreSession — signedIn=$signedIn, '
      'cachedUser=${cachedUser?.id ?? 'null'}',
    );
    if (cachedUser != null) {
      var user = cachedUser;
      // A name edited in Profile is a local override of whatever the
      // identity provider reports, so it has to outlive the session.
      final savedName = prefs.getString(_displayNameKey);
      if (savedName != null && savedName.isNotEmpty) {
        user = user.copyWith(name: savedName);
      }
      currentUser = user;
      // The user is already genuinely signed in (Firebase Auth's own
      // persisted session says so) — a hiccup mirroring that session to the
      // live backend must not strand them on an infinite splash screen, so
      // it's caught and logged rather than left to propagate and skip the
      // `status = authenticated` / `notifyListeners()` below.
      status = AuthStatus.authenticated;
      SyncService.instance.prepareUser(user.id);
      TripSyncService.instance.prepareUser(user.id);
      _startSync(user.id);
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

  Future<void> _startSync(String uid) async {
    try {
      await SyncService.instance.init();
      if (currentUser?.id != uid) return;
      final firebaseUser = _authService.currentCachedUser();
      if (firebaseUser?.id != uid) return;
      await SyncService.instance.bind(uid);
      await TripSyncService.instance.bind(uid);
    } catch (e) {
      debugPrint('NooLure: background sync failed — $e');
    }
  }

  Future<void> signInWithGoogle() async {
    status = AuthStatus.authenticating;
    errorMessage = null;
    notifyListeners();

    try {
      await SyncService.instance.init();
      final user = await _authService.signInWithGoogle();
      currentUser = user;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_sessionKey, true);
      await prefs.setString(_cachedIdKey, user.id);
      await prefs.setString(_cachedEmailKey, user.email);
      await prefs.setString(_displayNameKey, user.name);
      // The sign-in itself has now genuinely succeeded and is persisted —
      // status flips to authenticated regardless of what happens next, so a
      // sync hiccup below can't masquerade as a failed login and bounce the
      // user back to the Login screen with a false "Sign-in failed".
      status = AuthStatus.authenticated;

      SyncService.instance.prepareUser(user.id);
      TripSyncService.instance.prepareUser(user.id);
      _startSync(user.id);
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
    await SyncService.instance.pushProfileName(trimmed);
  }

  /// Returns `false` (without signing out) if there's a write from this
  /// session still unsynced and no connection to flush it — switching
  /// accounts while that's true would either lose the change or, worse,
  /// merge it into the next signed-in account's local data. See
  /// [LocalStore.clearAll], which this calls on an actual sign-out so the
  /// next account doesn't inherit this one's on-device tasks/notes.
  Future<bool> signOut() async {
    if (SyncService.instance.hasPendingWrites) {
      errorMessage =
          "You have changes that haven't synced yet. Wait for sync to finish "
          'before switching accounts.';
      notifyListeners();
      return false;
    }

    await _authService.signOut();
    await BiometricVault.disable();
    await SyncService.instance.unbind();
    await TripSyncService.instance.unbind();
    await LocalStore.clearAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sessionKey, false);
    await prefs.remove(_cachedIdKey);
    await prefs.remove(_cachedEmailKey);
    currentUser = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
    return true;
  }

  /// Permanently deletes the account and all of its data — remote mirror
  /// first (while still authenticated enough for the `auth.uid === $uid`
  /// rule to allow it), then local, then the identity itself.
  Future<void> deleteAccount() async {
    final user = currentUser;
    if (user == null) return;

    await SyncService.instance.deleteRemoteUserData(user.id);
    await LocalStore.clearAll();
    await BiometricVault.disable();
    await _authService.deleteAccount();
    await SyncService.instance.unbind();
    await TripSyncService.instance.unbind();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sessionKey, false);
    await prefs.remove(_cachedIdKey);
    await prefs.remove(_cachedEmailKey);
    await prefs.remove(_displayNameKey);

    currentUser = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
