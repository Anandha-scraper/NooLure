import 'dart:async';
import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';

import '../core/data/repositories.dart';
import '../core/data/repository.dart';
import '../core/security/vault_crypto.dart';
import '../models/password_model.dart';
import '../models/password_vault_model.dart';

/// Drives the Passwords vault: PIN setup/unlock, and CRUD over decrypted
/// entries once unlocked. The derived AES key ([_key]) lives only in memory
/// for the lifetime of this provider instance — never persisted — and is
/// dropped by [lock], which the Passwords screen calls from `dispose()` so
/// leaving the section (back button or switching via the drawer) always
/// re-locks it.
class PasswordProvider extends ChangeNotifier {
  PasswordProvider({
    Repository<PasswordModel>? repository,
    Repository<PasswordVaultModel>? vaultRepository,
  }) : _repository = repository ?? Repositories.passwords,
       _vaultRepository = vaultRepository ?? Repositories.passwordVault {
    _applyEntries(_repository.all());
    _applyVault(_vaultRepository.all());
    _entriesSubscription = _repository.watch().skip(1).listen(_applyEntries);
    _vaultSubscription = _vaultRepository.watch().skip(1).listen(_applyVault);
  }

  final Repository<PasswordModel> _repository;
  final Repository<PasswordVaultModel> _vaultRepository;

  StreamSubscription<List<PasswordModel>>? _entriesSubscription;
  StreamSubscription<List<PasswordVaultModel>>? _vaultSubscription;

  List<PasswordModel> _rawEntries = [];
  PasswordVaultModel? _vault;
  SecretKey? _key;
  List<({PasswordModel meta, PasswordEntryData data})> _decrypted = [];

  bool get hasVault => _vault != null;
  bool get isLocked => _key == null;

  List<({PasswordModel meta, PasswordEntryData data})> get entries =>
      List.unmodifiable(_decrypted);

  void _applyEntries(List<PasswordModel> items) {
    _rawEntries = items..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    if (!isLocked) _redecryptAll();
    notifyListeners();
  }

  void _applyVault(List<PasswordVaultModel> items) {
    _vault = items.isEmpty
        ? null
        : items.firstWhere(
            (v) => v.id == PasswordVaultModel.vaultId,
            orElse: () => items.first,
          );
    notifyListeners();
  }

  Future<void> _redecryptAll() async {
    final key = _key;
    if (key == null) return;
    final next = <({PasswordModel meta, PasswordEntryData data})>[];
    for (final meta in _rawEntries) {
      try {
        final json = await VaultCrypto.decryptJson(meta.encryptedBlob, key);
        next.add((meta: meta, data: PasswordEntryData.fromJson(json)));
      } catch (_) {
        // Skip an entry that fails to decrypt (corrupt write) rather than
        // taking the whole list down with it.
      }
    }
    _decrypted = next;
  }

  /// First-time setup: derives a fresh salt + key from [pin], stores a
  /// canary so future unlock attempts can be verified, and unlocks.
  Future<void> setupPin(String pin) async {
    final salt = VaultCrypto.generateSalt();
    final key = await VaultCrypto.deriveKey(pin, salt);
    final canary = await VaultCrypto.buildCanary(key);
    final now = DateTime.now();
    await _vaultRepository.save(
      PasswordVaultModel(
        id: PasswordVaultModel.vaultId,
        saltBase64: base64Encode(salt),
        canaryBase64: canary,
        updatedAt: now,
      ),
    );
    _key = key;
    await _redecryptAll();
    notifyListeners();
  }

  /// Returns `true` and unlocks on a correct PIN; `false` on a wrong one.
  Future<bool> unlock(String pin) async {
    final vault = _vault;
    if (vault == null) return false;
    final salt = base64Decode(vault.saltBase64);
    final key = await VaultCrypto.deriveKey(pin, salt);
    final ok = await VaultCrypto.verifyCanary(vault.canaryBase64, key);
    if (!ok) return false;
    _key = key;
    await _redecryptAll();
    notifyListeners();
    return true;
  }

  void lock() {
    if (isLocked) return;
    _key = null;
    _decrypted = [];
    notifyListeners();
  }

  /// "Forgot PIN": wipes every entry and the vault record itself — the only
  /// way to recover, and destructive by design, since nothing but the PIN
  /// can reconstruct the key that encrypted the old entries anyway.
  Future<void> resetVault() async {
    for (final entry in _repository.all()) {
      await _repository.delete(entry.id);
    }
    final vault = _vault;
    if (vault != null) await _vaultRepository.delete(vault.id);
    lock();
  }

  /// Upserts an entry under [id] — used for both creating and autosaving an
  /// entry, since the screen picks a stable id upfront (existing id when
  /// editing, a fresh one when creating) the same way `NoteProvider`'s
  /// autosaving note editor does. A no-op call with an id that hasn't been
  /// saved yet just creates it.
  Future<void> updateEntry(
    String id,
    PasswordEntryData data, {
    String tag = 'General',
  }) async {
    final key = _key;
    if (key == null) return; // Only callable while unlocked.
    final blob = await VaultCrypto.encryptJson(data.toJson(), key);
    final now = DateTime.now();
    final existing = _rawEntries.where((e) => e.id == id).firstOrNull;
    await _repository.save(
      PasswordModel(
        id: id,
        encryptedBlob: blob,
        tag: tag,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      ),
    );
  }

  Future<void> deleteEntry(String id) => _repository.delete(id);

  @override
  void dispose() {
    _entriesSubscription?.cancel();
    _vaultSubscription?.cancel();
    super.dispose();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
