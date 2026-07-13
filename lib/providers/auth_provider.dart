import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final signedIn = prefs.getBool(_sessionKey) ?? false;
    if (signedIn) {
      var user = await _authService.signInWithGoogle();
      // A name edited in Profile is a local override of whatever the identity
      // provider reports, so it has to outlive the session.
      final savedName = prefs.getString(_displayNameKey);
      if (savedName != null && savedName.isNotEmpty) {
        user = user.copyWith(name: savedName);
      }
      currentUser = user;
      await SyncService.instance.bind(user.id);
      status = AuthStatus.authenticated;
    } else {
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    status = AuthStatus.authenticating;
    notifyListeners();

    final user = await _authService.signInWithGoogle();
    currentUser = user;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sessionKey, true);

    // No-op unless a Firebase config is present; local data is already usable.
    await SyncService.instance.bind(user.id);

    status = AuthStatus.authenticated;
    notifyListeners();
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
}
