import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/data/repositories.dart';
import '../core/data/repository.dart';
import '../core/utils/date_labels.dart';
import '../models/calendar_model.dart';

class CalendarProvider extends ChangeNotifier {
  CalendarProvider({Repository<CalendarEventModel>? repository})
    : _repository = repository ?? Repositories.calendarEvents {
    _subscription = _repository.watch().listen((events) {
      _events = events..sort((a, b) => a.startAt.compareTo(b.startAt));
      notifyListeners();
    });
  }

  final Repository<CalendarEventModel> _repository;
  static const _uuid = Uuid();

  StreamSubscription<List<CalendarEventModel>>? _subscription;
  List<CalendarEventModel> _events = [];

  /// Read fresh each time rather than cached at class-load, so a session left
  /// open overnight doesn't keep highlighting yesterday.
  DateTime get today => DateLabels.dateOnly(DateTime.now());

  DateTime? _displayedMonth;
  DateTime get displayedMonth =>
      _displayedMonth ??= DateTime(today.year, today.month);

  CalendarView selectedView = CalendarView.month;

  List<CalendarEventModel> get events => List.unmodifiable(_events);

  List<CalendarEventModel> get todaysEvents =>
      eventsOn(today).where((e) => !e.allDay).toList();

  List<CalendarEventModel> eventsOn(DateTime day) =>
      _events.where((e) => DateLabels.isSameDay(e.startAt, day)).toList();

  bool hasEvent(DateTime day) =>
      _events.any((e) => DateLabels.isSameDay(e.startAt, day));

  void nextMonth() {
    _displayedMonth = DateTime(displayedMonth.year, displayedMonth.month + 1);
    notifyListeners();
  }

  void previousMonth() {
    _displayedMonth = DateTime(displayedMonth.year, displayedMonth.month - 1);
    notifyListeners();
  }

  void setView(CalendarView view) {
    selectedView = view;
    notifyListeners();
  }

  Future<void> addEvent({
    required String title,
    required DateTime startAt,
    DateTime? endAt,
    bool allDay = false,
    String colorKey = 'accent',
  }) async {
    final now = DateTime.now();
    await _repository.save(
      CalendarEventModel(
        id: _uuid.v4(),
        title: title,
        startAt: startAt,
        endAt: endAt,
        allDay: allDay,
        colorKey: colorKey,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> updateEvent(CalendarEventModel event) => _repository.save(event);

  Future<void> deleteEvent(String id) => _repository.delete(id);

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
