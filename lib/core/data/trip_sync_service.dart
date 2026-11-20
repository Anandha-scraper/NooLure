import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../models/trip_model.dart';
import 'sync_service.dart';
import 'local_store.dart';

/// Shared, realtime-only sync for Trip Planner.
///
/// Trips are group-owned data — several uids read/write the same record —
/// which doesn't fit [SyncService]'s per-user `/users/<uid>/<collection>`
/// layout (its `pruneMissing` would delete a trip locally for every member
/// the instant it's absent from *their own* subtree). This talks to a
/// parallel tree instead, rooted outside `/users/<uid>/...`:
///
/// ```
/// /trips/{tripId}                          full trip document
/// /tripInviteCodes/{code} -> tripId         reverse index + uniqueness anchor
/// /userTrips/{uid}/{tripId} -> true         "which trips am I in" index
/// ```
///
/// There is no on-device Hive cache here — trips are unavailable offline
/// (an empty list, not stale-but-usable data), which is the accepted
/// trade-off for genuinely live shared state.
class TripSyncService {
  TripSyncService._();

  static final TripSyncService instance = TripSyncService._();

  static const _codeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const _uuid = Uuid();

  DatabaseReference? get _root => SyncService.instance.root;

  bool get isEnabled => _root != null;

  String? _uid;
  StreamSubscription<DatabaseEvent>? _connectedSub;
  StreamSubscription<DatabaseEvent>? _userTripsSub;
  final Map<String, StreamSubscription<DatabaseEvent>> _tripSubs = {};
  final Map<String, TripModel> _cache = {};
  final StreamController<List<TripModel>> _controller =
      StreamController<List<TripModel>>.broadcast();
  final StreamController<String?> _errorController =
      StreamController<String?>.broadcast();

  /// Live feed of every trip the currently bound uid belongs to.
  Stream<List<TripModel>> get tripsStream => _controller.stream;

  /// Fires with a message whenever a trip listener errors out (e.g. a rules
  /// rejection), and with `null` once a subsequent read succeeds — lets
  /// [TripProvider] tell "no trips" apart from "trips failed to load."
  Stream<String?> get errorStream => _errorController.stream;

  List<TripModel> get currentTrips => _cache.values.toList();

  void prepareUser(String uid) {
    if (_uid == uid) return;
    _uid = uid;
    _cache.clear();
    final box = LocalStore.box(LocalStore.tripCache);
    for (final key in box.keys) {
      final id = key.toString();
      if (!id.startsWith('$uid/')) continue;
      try {
        _cache[id.substring(uid.length + 1)] = TripModel.fromJson(
          id.substring(uid.length + 1),
          jsonDecode(box.get(id)!) as Map<String, dynamic>,
        );
      } catch (_) {}
    }
    _controller.add(currentTrips);
  }

  void _putCache(TripModel trip) {
    final uid = _uid;
    if (uid == null) return;
    _cache[trip.id] = trip;
    unawaited(
      LocalStore.box(
        LocalStore.tripCache,
      ).put('$uid/${trip.id}', jsonEncode(trip.toJson())),
    );
    _controller.add(currentTrips);
  }

  Future<void> _queueUpdate(Map<String, Object?> updates) async {
    final uid = _uid;
    if (uid == null) return;
    final box = LocalStore.box(LocalStore.pendingSync);
    await box.put(
      'trip:${_uuid.v4()}',
      jsonEncode({'uid': uid, 'updates': updates}),
    );
    if (SyncService.instance.isOnline) unawaited(_flushTripUpdates());
  }

  Future<void>? _flushFuture;
  Future<void> _flushTripUpdates() => _flushFuture ??= _doFlushTripUpdates()
      .whenComplete(() => _flushFuture = null);

  Future<void> _doFlushTripUpdates() async {
    final root = _root;
    final uid = _uid;
    if (root == null || uid == null || !SyncService.instance.isOnline) return;
    final box = LocalStore.box(LocalStore.pendingSync);
    for (final key in box.keys.toList()) {
      if (!key.toString().startsWith('trip:')) continue;
      final raw = box.get(key);
      if (raw == null) continue;
      final op = jsonDecode(raw) as Map<String, dynamic>;
      if (op['uid'] != uid) continue;
      try {
        await root.update(Map<String, Object?>.from(op['updates'] as Map));
        if (box.get(key) == raw) await box.delete(key);
      } catch (error) {
        debugPrint('NooLure: trip edit retry later — $error');
        break;
      }
    }
  }

  Future<void> bind(String uid) async {
    if (_userTripsSub != null && _uid == uid) return;
    if (_uid != uid) prepareUser(uid);
    final root = _root;
    if (root == null) return;
    _connectedSub = root.child('.info/connected').onValue.listen((event) {
      if (event.snapshot.value == true) unawaited(_flushTripUpdates());
    });
    _userTripsSub = root
        .child('userTrips')
        .child(uid)
        .onValue
        .listen(
          (event) {
            _errorController.add(null);
            _reconcileTripSubs(_idsFromSnapshot(event.snapshot.value));
          },
          onError: (Object error) {
            debugPrint('NooLure: trip list sync error — $error');
            _errorController.add(error.toString());
          },
        );
  }

  Future<void> unbind() async {
    await _userTripsSub?.cancel();
    await _connectedSub?.cancel();
    _connectedSub = null;
    _userTripsSub = null;
    for (final sub in _tripSubs.values) {
      await sub.cancel();
    }
    _tripSubs.clear();
    _cache.clear();
    _uid = null;
    _controller.add(const []);
  }

  void _reconcileTripSubs(Set<String> ids) {
    final root = _root;
    if (root == null) return;

    for (final id in ids) {
      if (_tripSubs.containsKey(id)) continue;
      _tripSubs[id] = root
          .child('trips')
          .child(id)
          .onValue
          .listen(
            (event) {
              _errorController.add(null);
              final value = event.snapshot.value;
              if (value is Map) {
                if (!_hasPendingForTrip(id)) {
                  _putCache(
                    TripModel.fromJson(id, Map<String, dynamic>.from(value)),
                  );
                }
              } else if (SyncService.instance.isOnline &&
                  !_hasPendingForTrip(id)) {
                _cache.remove(id);
                if (_uid != null)
                  unawaited(
                    LocalStore.box(LocalStore.tripCache).delete('$_uid/$id'),
                  );
              }
              _controller.add(_cache.values.toList());
            },
            onError: (Object error) {
              debugPrint('NooLure: trip sync error ($id) — $error');
              _errorController.add(error.toString());
            },
          );
    }

    for (final id in _tripSubs.keys.toList()) {
      if (!SyncService.instance.isOnline || _hasPendingForTrip(id)) continue;
      if (!ids.contains(id)) {
        _tripSubs.remove(id)?.cancel();
        _cache.remove(id);
        if (_uid != null)
          unawaited(LocalStore.box(LocalStore.tripCache).delete('$_uid/$id'));
      }
    }
    _controller.add(_cache.values.toList());
  }

  static Set<String> _idsFromSnapshot(Object? value) =>
      value is Map ? value.keys.map((k) => k.toString()).toSet() : <String>{};

  bool _hasPendingForTrip(String id) =>
      LocalStore.box(LocalStore.pendingSync).values.any((raw) {
        if (!raw.contains('"updates"')) return false;
        try {
          final op = jsonDecode(raw) as Map<String, dynamic>;
          return op['uid'] == _uid &&
              (op['updates'] as Map).keys.any(
                (path) => path.toString().startsWith('trips/$id/'),
              );
        } catch (_) {
          return false;
        }
      });

  Future<TripModel?> createTrip({
    required String name,
    required String destination,
    required DateTime startDate,
    required DateTime endDate,
    required String creatorUid,
    required String creatorName,
  }) async {
    final root = _root;
    if (root == null) return null;

    final tripId = _uuid.v4();
    final code = await _claimUniqueCode(root, tripId);
    if (code == null) return null;

    final now = DateTime.now();
    final trip = TripModel(
      id: tripId,
      name: name,
      destination: destination,
      startDate: startDate,
      endDate: endDate,
      inviteCode: code,
      createdByUid: creatorUid,
      createdByName: creatorName,
      members: {
        creatorUid: TripMember(
          uid: creatorUid,
          name: creatorName,
          joinedAt: now,
        ),
      },
      createdAt: now,
      updatedAt: now,
    );

    await root.update({
      'trips/$tripId': trip.toJson(),
      'userTrips/$creatorUid/$tripId': true,
    });
    return trip;
  }

  /// Guarded by a transaction on `/tripInviteCodes/{code}` so two
  /// simultaneous creators can never claim the same code — a plain
  /// read-then-write has a TOCTOU gap a transaction closes, since Firebase
  /// re-runs the handler against the latest server value on conflict.
  Future<String?> _claimUniqueCode(
    DatabaseReference root,
    String tripId, {
    int maxAttempts = 10,
  }) async {
    final rng = Random();
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final code = List.generate(
        6,
        (_) => _codeAlphabet[rng.nextInt(_codeAlphabet.length)],
      ).join();
      final ref = root.child('tripInviteCodes').child(code);
      final result = await ref.runTransaction((currentData) {
        if (currentData != null) return Transaction.abort();
        return Transaction.success(tripId);
      });
      if (result.committed) return code;
    }
    return null;
  }

  Future<String?> joinByCode(
    String rawCode, {
    required String uid,
    required String name,
  }) async {
    final root = _root;
    if (root == null) return null;

    final code = rawCode.trim().toUpperCase();
    final snapshot = await root.child('tripInviteCodes').child(code).get();
    final tripId = snapshot.value as String?;
    if (tripId == null) return null;

    final now = DateTime.now();
    await root.update({
      'trips/$tripId/members/$uid': TripMember(
        uid: uid,
        name: name,
        joinedAt: now,
      ).toJson(),
      'trips/$tripId/updatedAt': now.toIso8601String(),
      'userTrips/$uid/$tripId': true,
    });
    return tripId;
  }

  /// Self-leave (uid == the requester) and admin-kick both funnel through
  /// here — admin gating happens one layer up in `TripProvider`; the real
  /// enforcement boundary is the RTDB rules.
  Future<void> removeMember(TripModel trip, String uid) async {
    final root = _root;
    if (root == null) return;

    final updates = <String, Object?>{
      'trips/${trip.id}/members/$uid': null,
      'userTrips/$uid/${trip.id}': null,
      'trips/${trip.id}/updatedAt': DateTime.now().toIso8601String(),
    };
    for (final item in trip.items.values) {
      if (item.responses.containsKey(uid)) {
        updates['trips/${trip.id}/items/${item.id}/responses/$uid'] = null;
      }
    }
    await root.update(updates);
  }

  Future<void> deleteTrip(TripModel trip) async {
    final root = _root;
    if (root == null) return;

    final updates = <String, Object?>{
      'trips/${trip.id}': null,
      'tripInviteCodes/${trip.inviteCode}': null,
    };
    for (final uid in trip.members.keys) {
      updates['userTrips/$uid/${trip.id}'] = null;
    }
    await root.update(updates);
  }

  Future<void> addItem(String tripId, String title) async {
    final itemId = _uuid.v4();
    final now = DateTime.now();
    final item = TripItem(
      id: itemId,
      title: title,
      createdAt: now,
      updatedAt: now,
    );
    final trip = _cache[tripId];
    if (trip != null)
      _putCache(
        trip.copyWith(items: {...trip.items, itemId: item}, updatedAt: now),
      );
    await _queueUpdate({
      'trips/$tripId/items/$itemId': item.toJson(),
      'trips/$tripId/updatedAt': now.toIso8601String(),
    });
  }

  Future<void> deleteItem(String tripId, String itemId) async {
    final trip = _cache[tripId];
    if (trip != null)
      _putCache(trip.copyWith(items: {...trip.items}..remove(itemId)));
    await _queueUpdate({'trips/$tripId/items/$itemId': null});
  }

  /// Any member may call this for their own [uid] — not admin-gated.
  Future<void> toggleResponse(String tripId, String itemId, String uid) async {
    final trip = _cache[tripId];
    final item = trip?.items[itemId];
    if (trip == null || item == null) return;
    final responses = {...item.responses};
    final now = DateTime.now();
    final value = responses.containsKey(uid) ? null : now.toIso8601String();
    if (value == null) {
      responses.remove(uid);
    } else {
      responses[uid] = now;
    }
    _putCache(
      trip.copyWith(
        items: {
          ...trip.items,
          itemId: item.copyWith(responses: responses, updatedAt: now),
        },
      ),
    );
    await _queueUpdate({'trips/$tripId/items/$itemId/responses/$uid': value});
  }
}
