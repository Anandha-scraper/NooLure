import '../core/utils/date_labels.dart';

/// A saved password entry. [encryptedBlob] is the only place the actual
/// title/username/password/url/secret live — see [PasswordEntryData] for the
/// decrypted shape used in memory while the vault is unlocked.
///
/// [toJson] must only ever emit [id]/[encryptedBlob]/[tag]/timestamps — never
/// plaintext — since that JSON is exactly what gets written to Hive and
/// mirrored to Firebase. `tag` (category) stays plaintext for filter chips,
/// the same minor metadata trade-off Notes already makes with its own tag.
class PasswordModel {
  const PasswordModel({
    required this.id,
    required this.encryptedBlob,
    required this.tag,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String encryptedBlob;
  final String tag;
  final DateTime createdAt;

  /// Drives last-write-wins when a remote copy comes back from sync.
  final DateTime updatedAt;

  /// 'just now' / '2h ago' / 'Mar 3' — derived, never stored.
  String get editedLabel => DateLabels.relativeLabel(updatedAt);

  PasswordModel copyWith({
    String? encryptedBlob,
    String? tag,
    DateTime? updatedAt,
  }) => PasswordModel(
    id: id,
    encryptedBlob: encryptedBlob ?? this.encryptedBlob,
    tag: tag ?? this.tag,
    createdAt: createdAt,
    updatedAt: updatedAt ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'encryptedBlob': encryptedBlob,
    'tag': tag,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory PasswordModel.fromJson(Map<String, dynamic> json) {
    final created = _parseDate(json['createdAt']) ?? DateTime.now();
    return PasswordModel(
      id: json['id'] as String,
      encryptedBlob: (json['encryptedBlob'] as String?) ?? '',
      tag: (json['tag'] as String?) ?? 'General',
      createdAt: created,
      updatedAt: _parseDate(json['updatedAt']) ?? created,
    );
  }
}

DateTime? _parseDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

/// The decrypted shape of one entry — built in memory only while the vault is
/// unlocked, and what gets JSON-encoded into / decoded out of
/// [PasswordModel.encryptedBlob]. Never persisted on its own.
///
/// No title field: [PasswordModel.tag] (plaintext, already needed for filter
/// chips) doubles as the entry's display name, so there's no separate
/// encrypted title to keep in sync with it.
class PasswordEntryData {
  const PasswordEntryData({
    required this.username,
    required this.password,
    this.url = '',
    this.secret = '',
  });

  final String username;
  final String password;
  final String url;

  /// Optional secondary secret — a passcode, PIN, or longer recovery/backup
  /// phrase associated with this same entry. Single- or multi-line.
  final String secret;

  Map<String, dynamic> toJson() => {
    'username': username,
    'password': password,
    'url': url,
    'secret': secret,
  };

  factory PasswordEntryData.fromJson(Map<String, dynamic> json) =>
      PasswordEntryData(
        username: (json['username'] as String?) ?? '',
        password: (json['password'] as String?) ?? '',
        url: (json['url'] as String?) ?? '',
        secret: (json['secret'] as String?) ?? '',
      );
}
