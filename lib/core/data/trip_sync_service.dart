import 'dart:async';
import 'dart:math';

import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';

import '../../models/trip_model.dart';
import 'sync_service.dart';

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
  StreamSubscription<DatabaseEvent>? _userTripsSub;
  final Map<String, StreamSubscription<DatabaseEvent>> _tripSubs = {};
  final Map<String, TripModel> _cache = {};
  final StreamController<List<TripModel>> _controller =
      StreamController<List<TripModel>>.broadcast();

  /// Live feed of every trip the currently bound uid belongs to.
  Stream<List<TripModel>> get tripsStream => _controller.stream;

  List<TripModel> get currentTrips => _cache.values.toList();

  Future<void> bind(String uid) async {
    if (_uid == uid) return;
    await unbind();
    _uid = uid;
    final root = _root;
    if (root == null) return;
    _userTripsSub = root.child('userTrips').child(uid).onValue.listen((event) {
      _reconcileTripSubs(_idsFromSnapshot(event.snapshot.value));
    });
  }

  Future<void> unbind() async {
    await _userTripsSub?.cancel();
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
      _tripSubs[id] = root.child('trips').child(id).onValue.listen((event) {
        final value = event.snapshot.value;
        if (value is Map) {
          _cache[id] = TripModel.fromJson(id, Map<String, dynamic>.from(value));
        } else {
          _cache.remove(id);
        }
        _controller.add(_cache.values.toList());
      });
    }

    for (final id in _tripSubs.keys.toList()) {
      if (!ids.contains(id)) {
        _tripSubs.remove(id)?.cancel();
        _cache.remove(id);
      }
    }
    _controller.add(_cache.values.toList());
  }

  static Set<String> _idsFromSnapshot(Object? value) =>
      value is Map ? value.keys.map((k) => k.toString()).toSet() : <String>{};

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
        creatorUid: TripMember(uid: creatorUid, name: creatorName, joinedAt: now),
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
    final root = _root;
    if (root == null) return;

    final itemId = _uuid.v4();
    final now = DateTime.now();
    await root.update({
      'trips/$tripId/items/$itemId': TripItem(
        id: itemId,
        title: title,
        createdAt: now,
        updatedAt: now,
      ).toJson(),
      'trips/$tripId/updatedAt': now.toIso8601String(),
    });
  }

  Future<void> deleteItem(String tripId, String itemId) async {
    await _root?.child('trips').child(tripId).child('items').child(itemId).remove();
  }

  /// Any member may call this for their own [uid] — not admin-gated.
  Future<void> toggleResponse(String tripId, String itemId, String uid) async {
    final ref = _root
        ?.child('trips')
        .child(tripId)
        .child('items')
        .child(itemId)
        .child('responses')
        .child(uid);
    if (ref == null) return;
    final snap = await ref.get();
    if (snap.exists) {
      await ref.remove();
    } else {
      await ref.set(DateTime.now().toIso8601String());
    }
  }
}
