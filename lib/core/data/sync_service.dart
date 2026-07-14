import 'dart:async';

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

  bool get isEnabled => _root != null;
  bool get isSyncing => isEnabled && _userId != null;

  /// Call once at startup, before `runApp`.
  Future<void> init() async {
    try {
      await Firebase.initializeApp();
      final db = FirebaseDatabase.instance;
      // Durable offline cache: reads are served from disk and writes made
      // offline are queued and flushed on reconnect.
      db.setPersistenceEnabled(true);
      _root = db.ref();
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

  /// Start mirroring for a signed-in user: reconcile what's on disk against
  /// what's on the server, then stay subscribed for live updates.
  Future<void> bind(String userId) async {
    if (!isEnabled || _userId == userId) return;
    await unbind();
    _userId = userId;

    for (final repository in _repositories.values) {
      await _reconcile(repository);
      _listen(repository);
    }
  }

  Future<void> unbind() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    _userId = null;
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
      await repository.mergeRemote(entry.key, entry.value);
    }

    for (final entry in repository.rawEntries().entries) {
      final remoteRecord = remote[entry.key];
      if (remoteRecord == null ||
          _updatedAt(entry.value).isAfter(_updatedAt(remoteRecord))) {
        await ref.child(entry.key).set(entry.value);
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
          await repository.mergeRemote(entry.key, entry.value);
        }
        await repository.pruneMissing(remote.keys.toSet());
      }, onError: (Object error) => debugPrint('NooLure: sync error — $error')),
    );
  }

  Future<void> push(
    String collection,
    String id,
    Map<String, dynamic> json,
  ) async {
    await _collectionRef(collection)?.child(id).set(json);
  }

  Future<void> pushDelete(String collection, String id) async {
    await _collectionRef(collection)?.child(id).remove();
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
