import 'dart:async';
import 'dart:convert';

import 'package:hive_ce_flutter/hive_flutter.dart';

import 'local_store.dart';
import 'sync_service.dart';

/// Local-first CRUD over one Hive box, with an optional Firebase mirror.
///
/// Reads and writes always resolve against the local box, so the UI never
/// waits on a network round-trip and works offline. [watch] is fed by
/// `box.watch()`, which means a write from anywhere in the app — or an update
/// arriving from sync — pushes straight to every listening screen.
class Repository<T> {
  Repository({
    required this.collection,
    required this.fromJson,
    required this.toJson,
    required this.idOf,
    SyncService? sync,
  }) : _sync = sync ?? SyncService.instance {
    _sync.register(this);
  }

  final String collection;
  final T Function(Map<String, dynamic>) fromJson;
  final Map<String, dynamic> Function(T) toJson;
  final String Function(T) idOf;
  final SyncService _sync;

  Box<String> get _box => LocalStore.box(collection);

  List<T> all() {
    final items = <T>[];
    for (final raw in _box.values) {
      final decoded = _decode(raw);
      if (decoded != null) items.add(decoded);
    }
    return items;
  }

  T? byId(String id) {
    final raw = _box.get(id);
    return raw == null ? null : _decode(raw);
  }

  /// Emits the current contents immediately, then again on every change.
  Stream<List<T>> watch() async* {
    yield all();
    yield* _box.watch().map((_) => all());
  }

  Future<void> save(T item) async {
    final id = idOf(item);
    final json = toJson(item);
    await _box.put(id, jsonEncode(json));
    await _sync.push(collection, id, json);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
    await _sync.pushDelete(collection, id);
  }

  // --- Sync-facing surface ------------------------------------------------

  /// Raw JSON of everything on disk, keyed by id — what [SyncService] uploads
  /// when it first connects to a backend.
  Map<String, Map<String, dynamic>> rawEntries() => {
    for (final key in _box.keys)
      key.toString():
          jsonDecode(_box.get(key.toString())!) as Map<String, dynamic>,
  };

  /// Accept a record from the server, but only if it's newer than ours.
  Future<void> mergeRemote(String id, Map<String, dynamic> remote) async {
    final localRaw = _box.get(id);
    if (localRaw != null) {
      final local = jsonDecode(localRaw) as Map<String, dynamic>;
      if (!_updatedAt(remote).isAfter(_updatedAt(local))) return;
    }
    await _box.put(id, jsonEncode(remote));
  }

  /// Drop local records the server no longer has — i.e. deleted on another
  /// device. Only ever called while actively synced.
  Future<void> pruneMissing(Set<String> remoteIds) async {
    final stale = _box.keys
        .map((k) => k.toString())
        .where((id) => !remoteIds.contains(id))
        .toList();
    if (stale.isNotEmpty) await _box.deleteAll(stale);
  }

  T? _decode(String raw) {
    try {
      return fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // A record we can't parse (schema drift, partial write) shouldn't take
      // the whole list down with it.
      return null;
    }
  }

  static DateTime _updatedAt(Map<String, dynamic> json) =>
      DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
      DateTime.fromMillisecondsSinceEpoch(0);
}
