import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

/// PIN-derived encryption for the Passwords vault.
///
/// Nothing here ever touches disk or Firebase directly — callers persist the
/// salt and the canary blob (both safe to store; neither reveals the PIN or
/// the derived key), and re-derive the AES key from the PIN on every unlock.
/// The derived key itself is never persisted in any form.
class VaultCrypto {
  VaultCrypto._();

  static final Pbkdf2 _kdf = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    // Keeps unlock in the ~100-300ms range on-device while meaningfully
    // slowing offline brute force of the inherently small (10,000-value)
    // 4-digit PIN space against a stolen ciphertext dump.
    iterations: 200000,
    bits: 256,
  );

  static final AesGcm _cipher = AesGcm.with256bits();

  /// Fixed plaintext checked on unlock — ties PIN verification directly to
  /// decryption capability instead of storing a separate PIN hash.
  static const Map<String, String> _canaryPlaintext = {
    'check': 'noolure-vault-v1',
  };

  static List<int> generateSalt() =>
      List<int>.generate(16, (_) => Random.secure().nextInt(256));

  static Future<SecretKey> deriveKey(String pin, List<int> salt) {
    return _kdf.deriveKeyFromPassword(password: pin, nonce: salt);
  }

  /// Base64 of `nonce || ciphertext || macTag` — a fresh random nonce is
  /// generated for every call. Never reuse a nonce with the same key.
  static Future<String> encryptJson(
    Map<String, dynamic> data,
    SecretKey key,
  ) async {
    final box = await _cipher.encrypt(
      utf8.encode(jsonEncode(data)),
      secretKey: key,
    );
    return base64Encode([...box.nonce, ...box.cipherText, ...box.mac.bytes]);
  }

  /// Throws [SecretBoxAuthenticationError] when the MAC doesn't match — i.e.
  /// tampered data, or (in practice, for this app) a wrong PIN.
  static Future<Map<String, dynamic>> decryptJson(
    String blob,
    SecretKey key,
  ) async {
    final bytes = base64Decode(blob);
    const nonceLength = 12;
    const macLength = 16;
    final nonce = bytes.sublist(0, nonceLength);
    final mac = bytes.sublist(bytes.length - macLength);
    final cipherText = bytes.sublist(nonceLength, bytes.length - macLength);
    final box = SecretBox(cipherText, nonce: nonce, mac: Mac(mac));
    final clear = await _cipher.decrypt(box, secretKey: key);
    return jsonDecode(utf8.decode(clear)) as Map<String, dynamic>;
  }

  static Future<String> buildCanary(SecretKey key) =>
      encryptJson(_canaryPlaintext, key);

  /// Returns `true` only if [key] decrypts [canaryBlob] back to the exact
  /// expected plaintext — a wrong key either throws (MAC failure) or, in the
  /// astronomically unlikely case it doesn't, won't match.
  static Future<bool> verifyCanary(String canaryBlob, SecretKey key) async {
    try {
      final decoded = await decryptJson(canaryBlob, key);
      return decoded['check'] == _canaryPlaintext['check'];
    } catch (_) {
      return false;
    }
  }
}
