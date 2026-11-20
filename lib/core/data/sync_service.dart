import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import 'local_store.dart';
import 'repository.dart';

/// The optional Firebase mirror on top of [LocalStore].
///
/// [init] tries to bring Firebase up and **swallows the failure**. With no
/// `google-services.json` / `firebase_options.dart` in the project — which is
/// the state the app ships in today — `Firebase.initializeApp()` throws, sync
/// stays [isEnabled] `false`, and NooLure runs as a purely local app with no
/// degraded behaviour. Drop a Firebase config in and the same code lights up:
/// no call sites change.
///
/// When enabled, records live under `/users/<uid>/<collection>/<id>` so two
/// accounts don't share one list, and Firebase's own disk persistence queues
/// writes made while offline and replays them on reconnect.
class SyncService {
  SyncService._();

  static final SyncService instance = SyncService._();

  DatabaseReference? _root;
  String? _userId;
  final Map<String, Repository<dynamic>> _repositories = {};
  final List<StreamSubscription<DatabaseEvent>> _subscriptions = [];
  bool _online = false;
  int _pendingWrites = 0;
  Future<void>? _initializing;
  bool _bound = false;

  bool get isEnabled => _root != null;
  bool get isSyncing => isEnabled && _userId != null;

  /// Whether this device currently has a live connection to the Firebase
  /// backend — backed by RTDB's own `.info/connected` special path, so no
  /// extra connectivity package is needed.
  bool get isOnline => _online;

  /// Whether a push from this session is still in flight (not yet
  /// server-acked). Only tracks writes made since this app launch — it
  /// can't see a write Firebase's disk persistence queued in a prior
  /// session that never got a chance to flush.
  bool get hasPendingWrites =>
      isEnabled &&
      (_pendingWrites > 0 || LocalStore.box(LocalStore.pendingSync).isNotEmpty);

  /// Exposes the shared root reference so other services (e.g. trips, which
  /// live outside the per-user `/users/<uid>` tree this class owns) can reuse
  /// the same `Firebase.initializeApp()`/persistence setup without
  /// duplicating it.
  DatabaseReference? get root => _root;

  /// Call once at startup, before `runApp`.
  Future<void> init() => _initializing ??= _initialize();

  Future<void> _initialize() async {
    try {
      await Firebase.initializeApp();
      final db = FirebaseDatabase.instance;
      // Durable offline cache: reads are served from disk and writes made
      // offline are queued and flushed on reconnect.
      db.setPersistenceEnabled(true);
      _root = db.ref();
      // Lives for the whole app process — never cancelled, same as this
      // singleton itself never disposes.
      db.ref('.info/connected').onValue.listen((event) {
        _online = event.snapshot.value == true;
        if (_online && _bound) unawaited(_flushPending());
      });
    } catch (error) {
      _root = null;
      debugPrint(
        'NooLure: no Firebase config found, running local-only. ($error)',
      );
    }
  }

  void register(Repository<dynamic> repository) {
    _repositories[repository.collection] = repository;
  }

  void prepareUser(String uid) {
    _userId = uid;
  }

  /// Start mirroring for a signed-in user: reconcile what's on disk against
  /// what's on the server, then stay subscribed for live updates.
  Future<void> bind(String userId) async {
    if (!isEnabled || (_userId == userId && _bound)) return;
    await unbind();
    _userId = userId;
    await _flushPending();
    for (final repository in _repositories.values) {
      await _reconcile(repository);
      _listen(repository);
    }
    _bound = true;
    if (_online) unawaited(_flushPending());
  }

  Future<void> unbind() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    _userId = null;
    _bound = false;
  }

  /// Merge the server's copy with the local one, newest `updatedAt` winning,
  /// then upload anything the server is missing or has an older copy of. This
  /// is what carries data created *before* Firebase was configured up to the
  /// server the first time a user connects one.
  Future<void> _reconcile(Repository<dynamic> repository) async {
    final ref = _collectionRef(repository.collection);
    if (ref == null) return;

    final snapshot = await ref.get();
    final remote = _asRecordMap(snapshot.value);

    for (final entry in remote.entries) {
      if (hasPending(collection: repository.collection, id: entry.key))
        continue;
      await repository.mergeRemote(entry.key, entry.value);
      await _markSeen(repository.collection, entry.key);
    }

    if (_online) await _pruneKnown(repository, remote.keys.toSet());

    for (final entry in repository.rawEntries().entries) {
      final remoteRecord = remote[entry.key];
      if (remoteRecord == null && _wasSeen(repository.collection, entry.key))
        continue;
      if (remoteRecord == null ||
          _updatedAt(entry.value).isAfter(_updatedAt(remoteRecord))) {
        if (!hasPending(collection: repository.collection, id: entry.key)) {
          await ref.child(entry.key).set(entry.value);
          await _markSeen(repository.collection, entry.key);
        }
      }
    }
  }

  void _listen(Repository<dynamic> repository) {
    final ref = _collectionRef(repository.collection);
    if (ref == null) return;

    _subscriptions.add(
      ref.onValue.listen((event) async {
        final remote = _asRecordMap(event.snapshot.value);
        for (final entry in remote.entries) {
          if (hasPending(collection: repository.collection, id: entry.key))
            continue;
          await repository.mergeRemote(entry.key, entry.value);
          await _markSeen(repository.collection, entry.key);
        }
        // A cached or incomplete offline snapshot must never erase local data.
        if (_online) await _pruneKnown(repository, remote.keys.toSet());
      }, onError: (Object error) => debugPrint('NooLure: sync error — $error')),
    );
  }

  Future<void> push(
    String collection,
    String id,
    Map<String, dynamic> json,
  ) async {
    await _enqueue(collection, id, json);
  }

  Future<void> pushDelete(String collection, String id) async {
    await _enqueue(collection, id, null);
  }

  bool hasPending({required String collection, required String id}) =>
      LocalStore.box(LocalStore.pendingSync).containsKey('$collection/$id');

  String _seenKey(String collection, String id) => '$_userId/$collection/$id';
  bool _wasSeen(String collection, String id) =>
      LocalStore.box(LocalStore.syncSeen).containsKey(_seenKey(collection, id));
  Future<void> _markSeen(String collection, String id) =>
      LocalStore.box(LocalStore.syncSeen).put(_seenKey(collection, id), '1');

  Future<void> _pruneKnown(
    Repository<dynamic> repository,
    Set<String> remoteIds,
  ) async {
    final seen = LocalStore.box(LocalStore.syncSeen);
    final prefix = '$_userId/${repository.collection}/';
    for (final key in seen.keys.toList()) {
      final name = key.toString();
      if (!name.startsWith(prefix)) continue;
      final id = name.substring(prefix.length);
      if (remoteIds.contains(id) ||
          hasPending(collection: repository.collection, id: id))
        continue;
      await repository.removeLocal(id);
      await seen.delete(key);
    }
  }

  Future<void> _enqueue(
    String collection,
    String id,
    Map<String, dynamic>? value,
  ) async {
    final uid = _userId;
    if (uid == null) return;
    await LocalStore.box(LocalStore.pendingSync).put(
      '$collection/$id',
      jsonEncode({
        'uid': uid,
        'collection': collection,
        'id': id,
        'value': value,
      }),
    );
    if (_online && _bound) unawaited(_flushPending());
  }

  Future<void>? _flushing;
  Future<void> _flushPending() =>
      _flushing ??= _doFlush().whenComplete(() => _flushing = null);

  Future<void> _doFlush() async {
    final uid = _userId;
    if (uid == null || _root == null || !_online) return;
    final box = LocalStore.box(LocalStore.pendingSync);
    for (final key in box.keys.toList()) {
      if (key.toString().startsWith('trip:')) continue;
      final raw = box.get(key);
      if (raw == null) continue;
      final op = jsonDecode(raw) as Map<String, dynamic>;
      if (op['uid'] != uid) continue;
      final ref = _collectionRef(
        op['collection'] as String,
      )?.child(op['id'] as String);
      if (ref == null) continue;
      _pendingWrites++;
      try {
        await ref.set(op['value']);
        if (op['value'] == null) {
          await LocalStore.box(
            LocalStore.syncSeen,
          ).delete(_seenKey(op['collection'] as String, op['id'] as String));
        } else {
          await _markSeen(op['collection'] as String, op['id'] as String);
        }
        if (box.get(key) == raw) await box.delete(key);
      } catch (error) {
        debugPrint('NooLure: pending sync retry later — $error');
        break;
      } finally {
        _pendingWrites--;
      }
    }
  }

  Future<void> pushProfileName(String name) async {
    final root = _root;
    final userId = _userId;
    if (root == null || userId == null) return;
    await root
        .child('users')
        .child(userId)
        .child('profile')
        .child('name')
        .set(name);
  }

  Future<String?> fetchProfileName() async {
    final root = _root;
    final userId = _userId;
    if (root == null || userId == null) return null;
    final snapshot = await root
        .child('users')
        .child(userId)
        .child('profile')
        .child('name')
        .get();
    final value = snapshot.value;
    return value is String && value.isNotEmpty ? value : null;
  }

  /// Wipes everything this user has mirrored to the server — used when a
  /// user deletes their account.
  Future<void> deleteRemoteUserData(String userId) async {
    await _root?.child('users').child(userId).remove();
  }

  DatabaseReference? _collectionRef(String collection) {
    final root = _root;
    final userId = _userId;
    if (root == null || userId == null) return null;
    return root.child('users').child(userId).child(collection);
  }

  static Map<String, Map<String, dynamic>> _asRecordMap(Object? value) {
    if (value is! Map) return {};
    return {
      for (final entry in value.entries)
        if (entry.value is Map)
          entry.key.toString(): Map<String, dynamic>.from(entry.value as Map),
    };
  }

  static DateTime _updatedAt(Map<String, dynamic> json) =>
      DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
      DateTime.fromMillisecondsSinceEpoch(0);
}
