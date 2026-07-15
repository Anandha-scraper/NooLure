import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/data/repositories.dart';
import '../core/data/repository.dart';
import '../models/birthday_model.dart';

class BirthdayProvider extends ChangeNotifier {
  BirthdayProvider({Repository<BirthdayModel>? repository})
    : _repository = repository ?? Repositories.birthdays {
    _apply(_repository.all());
    _subscription = _repository.watch().skip(1).listen(_apply);
  }

  // Soonest birthday first — the countdown is recomputed from month/day on
  // every emission, so the order stays correct as days pass.
  void _apply(List<BirthdayModel> birthdays) {
    _birthdays = birthdays..sort((a, b) => a.daysUntil.compareTo(b.daysUntil));
    notifyListeners();
  }

  final Repository<BirthdayModel> _repository;
  static const _uuid = Uuid();

  StreamSubscription<List<BirthdayModel>>? _subscription;
  List<BirthdayModel> _birthdays = [];

  List<BirthdayModel> get birthdays => List.unmodifiable(_birthdays);

  List<BirthdayModel> get upcoming => _birthdays.take(4).toList();

  BirthdayModel? byId(String id) {
    for (final b in _birthdays) {
      if (b.id == id) return b;
    }
    return null;
  }

  Future<void> addReminderDay(String id, int daysBefore) async {
    final birthday = byId(id);
    if (birthday == null || birthday.reminderDaysBefore.contains(daysBefore)) {
      return;
    }
    final days = [...birthday.reminderDaysBefore, daysBefore]
      ..sort((a, b) => b.compareTo(a));
    await _repository.save(birthday.copyWith(reminderDaysBefore: days));
  }

  Future<void> removeReminderDay(String id, int daysBefore) async {
    final birthday = byId(id);
    if (birthday == null) return;
    await _repository.save(
      birthday.copyWith(
        reminderDaysBefore: [
          for (final d in birthday.reminderDaysBefore)
            if (d != daysBefore) d,
        ],
      ),
    );
  }

  Future<void> addBirthday({
    required String name,
    required String relation,
    required int month,
    required int day,
    int? birthYear,
    String notes = '',
    List<String> giftIdeas = const [],
  }) async {
    final now = DateTime.now();
    await _repository.save(
      BirthdayModel(
        id: _uuid.v4(),
        name: name,
        relation: relation,
        month: month,
        day: day,
        birthYear: birthYear,
        notes: notes,
        giftIdeas: giftIdeas,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> updateBirthday(BirthdayModel birthday) =>
      _repository.save(birthday);

  Future<void> deleteBirthday(String id) => _repository.delete(id);

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
