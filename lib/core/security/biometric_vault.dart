import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The vault key is wrapped by an Android Keystore key that requires strong
/// biometric authentication for every read. Nothing biometric is synced.
class BiometricVault {
  static const _marker = 'noolure_biometric_vault';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions.biometric(
      enforceBiometrics: true,
      biometricType: AndroidBiometricType.strongBiometricOnly,
      biometricPromptTitle: 'Unlock NooLure passwords',
      biometricPromptNegativeButton: 'Use PIN instead',
    ),
  );

  static Future<bool> get available async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      return (await LocalAuthentication().getAvailableBiometrics()).contains(
        BiometricType.fingerprint,
      );
    } catch (_) {
      return false;
    }
  }

  static Future<bool> get enabled async =>
      (await SharedPreferences.getInstance()).getBool(_marker) ?? false;

  static Future<void> enable(List<int> key, String canary) async {
    await _storage.write(
      key: _marker,
      value: jsonEncode({'key': base64Encode(key), 'canary': canary}),
    );
    await (await SharedPreferences.getInstance()).setBool(_marker, true);
  }

  static Future<List<int>?> read(String canary) async {
    if (!await available || !await enabled) return null;
    try {
      final raw = await _storage.read(key: _marker);
      if (raw == null) return null;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (data['canary'] != canary) return null;
      return base64Decode(data['key'] as String);
    } catch (_) {
      return null;
    }
  }

  static Future<void> disable() async {
    await (await SharedPreferences.getInstance()).setBool(_marker, false);
    try {
      await _storage.delete(key: _marker);
    } catch (_) {}
  }
}
