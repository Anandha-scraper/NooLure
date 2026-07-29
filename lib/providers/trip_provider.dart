import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/data/trip_sync_service.dart';
import '../models/trip_model.dart';

class TripProvider extends ChangeNotifier {
  TripProvider({TripSyncService? sync}) : _sync = sync ?? TripSyncService.instance {
    _trips = List.of(_sync.currentTrips);
    _subscription = _sync.tripsStream.listen((trips) {
      _trips = List.of(trips)..sort((a, b) => a.startDate.compareTo(b.startDate));
      notifyListeners();
    });
    _errorSubscription = _sync.errorStream.listen((error) {
      _loadError = error;
      notifyListeners();
    });
  }

  final TripSyncService _sync;
  StreamSubscription<List<TripModel>>? _subscription;
  StreamSubscription<String?>? _errorSubscription;
  List<TripModel> _trips = [];
  String? _loadError;

  List<TripModel> get trips => List.unmodifiable(_trips);

  /// Set when a trip listener errored (e.g. a permission rejection), cleared
  /// once reads succeed again — lets the UI tell "no trips" apart from
  /// "trips failed to load."
  String? get loadError => _loadError;

  TripModel? byId(String id) {
    for (final t in _trips) {
      if (t.id == id) return t;
    }
    return null;
  }

  Future<TripModel?> createTrip({
    required String name,
    required String destination,
    required DateTime startDate,
    required DateTime endDate,
    required String creatorUid,
    required String creatorName,
  }) => _sync.createTrip(
    name: name,
    destination: destination,
    startDate: startDate,
    endDate: endDate,
    creatorUid: creatorUid,
    creatorName: creatorName,
  );

  Future<bool> joinTrip(
    String code, {
    required String uid,
    required String name,
  }) async {
    final tripId = await _sync.joinByCode(code, uid: uid, name: name);
    return tripId != null;
  }

  Future<void> deleteTrip(String tripId, {required String requestingUid}) async {
    final trip = byId(tripId);
    if (trip == null || !trip.isAdmin(requestingUid)) return;
    await _sync.deleteTrip(trip);
  }

  /// Self-leave when `memberUid == requestingUid`; admin-kick otherwise.
  Future<void> removeMember(
    String tripId,
    String memberUid, {
    required String requestingUid,
  }) async {
    final trip = byId(tripId);
    if (trip == null) return;
    if (memberUid != requestingUid && !trip.isAdmin(requestingUid)) return;
    await _sync.removeMember(trip, memberUid);
  }

  Future<void> addItem(
    String tripId,
    String title, {
    required String requestingUid,
  }) async {
    final trip = byId(tripId);
    if (trip == null || !trip.isAdmin(requestingUid)) return;
    await _sync.addItem(tripId, title);
  }

  Future<void> deleteItem(
    String tripId,
    String itemId, {
    required String requestingUid,
  }) async {
    final trip = byId(tripId);
    if (trip == null || !trip.isAdmin(requestingUid)) return;
    await _sync.deleteItem(tripId, itemId);
  }

  /// Not admin-gated — any member toggles their own response.
  Future<void> toggleResponse(String tripId, String itemId, String uid) =>
      _sync.toggleResponse(tripId, itemId, uid);

  @override
  void dispose() {
    _subscription?.cancel();
    _errorSubscription?.cancel();
    super.dispose();
  }
}
