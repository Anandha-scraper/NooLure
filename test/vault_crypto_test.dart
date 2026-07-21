import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noolure/core/security/vault_crypto.dart';

/// Exercises the crypto invariants the Passwords vault depends on: a correct
/// PIN round-trips, a wrong PIN is rejected (never silently "succeeds" with
/// garbage), and encrypting the same data twice never reuses a nonce.
void main() {
  group('VaultCrypto', () {
    test('encrypt/decrypt round-trips with the correct key', () async {
      final salt = VaultCrypto.generateSalt();
      final key = await VaultCrypto.deriveKey('1234', salt);

      final blob = await VaultCrypto.encryptJson({
        'title': 'Gmail',
        'password': 'hunter2',
      }, key);

      final decoded = await VaultCrypto.decryptJson(blob, key);
      expect(decoded['title'], 'Gmail');
      expect(decoded['password'], 'hunter2');
    });

    test('a different PIN cannot decrypt data encrypted with another', () async {
      final salt = VaultCrypto.generateSalt();
      final rightKey = await VaultCrypto.deriveKey('1234', salt);
      final wrongKey = await VaultCrypto.deriveKey('9999', salt);

      final blob = await VaultCrypto.encryptJson({'secret': 'value'}, rightKey);

      expect(
        () => VaultCrypto.decryptJson(blob, wrongKey),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
    });

    test('canary verifies the correct PIN and rejects a wrong one', () async {
      final salt = VaultCrypto.generateSalt();
      final key = await VaultCrypto.deriveKey('4242', salt);
      final canary = await VaultCrypto.buildCanary(key);

      expect(await VaultCrypto.verifyCanary(canary, key), isTrue);

      final wrongKey = await VaultCrypto.deriveKey('0000', salt);
      expect(await VaultCrypto.verifyCanary(canary, wrongKey), isFalse);
    });

    test('encrypting the same data twice never reuses a nonce', () async {
      final salt = VaultCrypto.generateSalt();
      final key = await VaultCrypto.deriveKey('1234', salt);

      final blobA = await VaultCrypto.encryptJson({'x': 1}, key);
      final blobB = await VaultCrypto.encryptJson({'x': 1}, key);

      // Same plaintext, same key — ciphertexts must still differ because the
      // nonce is fresh every call. If this ever fails, AES-GCM's
      // confidentiality guarantee is broken.
      expect(blobA, isNot(equals(blobB)));
    });
  });
}
