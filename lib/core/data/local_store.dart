import 'package:hive_ce_flutter/hive_flutter.dart';

/// On-device storage. This is the app's source of truth: every read and write
/// goes here first, so the app is fully usable with no network and no backend
/// configured. Firebase, when present, is a mirror on top (see [SyncService]).
///
/// Records are stored as JSON strings keyed by id, which keeps the models free
/// of Hive adapters and codegen — they already need `toJson`/`fromJson` for the
/// Firebase leg.
class LocalStore {
  LocalStore._();

  static const String tasks = 'tasks';
  static const String notes = 'notes';
  static const String birthdays = 'birthdays';
  static const String passwords = 'passwords';
  static const String passwordVault = 'passwordVault';

  static const List<String> collections = [
    tasks,
    notes,
    birthdays,
    passwords,
    passwordVault,
  ];

  static Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait(collections.map(Hive.openBox<String>));
  }

  static Box<String> box(String collection) => Hive.box<String>(collection);

  /// Wipes every local collection — used when a user deletes their account.
  static Future<void> clearAll() async {
    for (final collection in collections) {
      await box(collection).clear();
    }
  }
}
