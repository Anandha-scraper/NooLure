import 'package:flutter_test/flutter_test.dart';
import 'package:noolure/models/password_model.dart';

/// Exercises [PasswordEntryData]'s JSON round-trip, in particular that a
/// blob encrypted before `secret` existed still decodes cleanly.
void main() {
  group('PasswordEntryData', () {
    test('round-trips every field, including secret, through JSON', () {
      const data = PasswordEntryData(
        username: 'you@example.com',
        password: 'hunter2',
        url: 'https://example.com',
        secret: 'recovery phrase\nline two',
      );

      final decoded = PasswordEntryData.fromJson(data.toJson());

      expect(decoded.username, data.username);
      expect(decoded.password, data.password);
      expect(decoded.url, data.url);
      expect(decoded.secret, data.secret);
    });

    test('decodes a pre-existing blob with no secret key to an empty string', () {
      final decoded = PasswordEntryData.fromJson({
        'username': 'you@example.com',
        'password': 'hunter2',
        'url': '',
      });

      expect(decoded.secret, '');
    });
  });
}
