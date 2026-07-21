/// One record per user, fixed [id] — presence of this record is how the app
/// knows whether a PIN has been set up yet. Holds only the PBKDF2 salt and an
/// encrypted canary blob (see `vault_crypto.dart`); never the PIN or the
/// derived key.
class PasswordVaultModel {
  const PasswordVaultModel({
    required this.id,
    required this.saltBase64,
    required this.canaryBase64,
    required this.updatedAt,
  });

  static const String vaultId = 'vault';

  final String id;
  final String saltBase64;
  final String canaryBase64;

  /// Drives last-write-wins when a remote copy comes back from sync.
  final DateTime updatedAt;

  PasswordVaultModel copyWith({
    String? saltBase64,
    String? canaryBase64,
    DateTime? updatedAt,
  }) => PasswordVaultModel(
    id: id,
    saltBase64: saltBase64 ?? this.saltBase64,
    canaryBase64: canaryBase64 ?? this.canaryBase64,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'saltBase64': saltBase64,
    'canaryBase64': canaryBase64,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory PasswordVaultModel.fromJson(Map<String, dynamic> json) {
    return PasswordVaultModel(
      id: json['id'] as String? ?? vaultId,
      saltBase64: (json['saltBase64'] as String?) ?? '',
      canaryBase64: (json['canaryBase64'] as String?) ?? '',
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
