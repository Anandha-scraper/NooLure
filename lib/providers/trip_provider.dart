import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/trip_model.dart';

class TripProvider extends ChangeNotifier {
  TripProvider() {
    _trips = List.of(_mockTrips);
  }

  List<TripModel> _trips = [];

  List<TripModel> get trips => List.unmodifiable(_trips);

  TripModel? byId(String id) {
    for (final t in _trips) {
      if (t.id == id) return t;
    }
    return null;
  }

  TripModel? byInviteCode(String code) {
    final lower = code.toLowerCase();
    for (final t in _trips) {
      if (t.inviteCode.toLowerCase() == lower) return t;
    }
    return null;
  }

  void addTrip({
    required String name,
    required String destination,
    required DateTime startDate,
    required DateTime endDate,
    required String createdBy,
  }) {
    _trips.add(
      TripModel(
        id: _uid(),
        name: name,
        destination: destination,
        startDate: startDate,
        endDate: endDate,
        inviteCode: _generateCode(),
        createdBy: createdBy,
        members: [createdBy],
        items: [],
      ),
    );
    notifyListeners();
  }

  bool joinTrip(String inviteCode, String memberName) {
    final trip = byInviteCode(inviteCode);
    if (trip == null) return false;
    if (trip.members.contains(memberName)) return true;
    final i = _trips.indexOf(trip);
    _trips[i] = trip.copyWith(members: [...trip.members, memberName]);
    notifyListeners();
    return true;
  }

  void deleteTrip(String id) {
    _trips.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  void toggleItem(String tripId, String itemId) {
    final trip = byId(tripId);
    if (trip == null) return;
    final i = _trips.indexOf(trip);
    _trips[i] = trip.copyWith(
      items: [
        for (final item in trip.items)
          item.id == itemId ? item.copyWith(done: !item.done) : item,
      ],
    );
    notifyListeners();
  }

  void addItem(String tripId, String title) {
    final trip = byId(tripId);
    if (trip == null) return;
    final i = _trips.indexOf(trip);
    _trips[i] = trip.copyWith(
      items: [...trip.items, TripItem(id: _uid(), title: title)],
    );
    notifyListeners();
  }

  static String _uid() =>
      DateTime.now().microsecondsSinceEpoch.toRadixString(36);

  static String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }
}

final _mockTrips = [
  TripModel(
    id: 'trip_1',
    name: 'Goa Beach Getaway',
    destination: 'Goa, India',
    startDate: DateTime(2026, 8, 15),
    endDate: DateTime(2026, 8, 20),
    inviteCode: 'GOA2026',
    createdBy: 'Anandha',
    members: ['Anandha', 'Ravi', 'Priya'],
    items: [
      TripItem(id: 'ti_1', title: 'Book flights', done: true),
      TripItem(id: 'ti_2', title: 'Reserve hotel'),
      TripItem(id: 'ti_3', title: 'Pack sunscreen'),
      TripItem(id: 'ti_4', title: 'Rent scooters'),
    ],
  ),
  TripModel(
    id: 'trip_2',
    name: 'Ooty Hills Weekend',
    destination: 'Ooty, Tamil Nadu',
    startDate: DateTime(2026, 9, 5),
    endDate: DateTime(2026, 9, 7),
    inviteCode: 'OOTY26',
    createdBy: 'Anandha',
    members: ['Anandha', 'Kumar'],
    items: [
      TripItem(id: 'ti_5', title: 'Book train tickets'),
      TripItem(id: 'ti_6', title: 'Plan trekking route'),
    ],
  ),
  TripModel(
    id: 'trip_3',
    name: 'Tokyo Adventure',
    destination: 'Tokyo, Japan',
    startDate: DateTime(2026, 12, 20),
    endDate: DateTime(2026, 12, 30),
    inviteCode: 'TKY26X',
    createdBy: 'Priya',
    members: ['Priya', 'Anandha', 'Deepa', 'Raj'],
    items: [
      TripItem(id: 'ti_7', title: 'Apply for visa'),
      TripItem(id: 'ti_8', title: 'Book Airbnb'),
      TripItem(id: 'ti_9', title: 'Get travel insurance', done: true),
      TripItem(id: 'ti_10', title: 'Plan Shibuya day'),
      TripItem(id: 'ti_11', title: 'Reserve teamLab tickets'),
    ],
  ),
];
