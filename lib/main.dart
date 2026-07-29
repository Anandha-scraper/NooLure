import 'package:flutter/material.dart';

import 'app.dart';
import 'core/data/local_store.dart';
import 'core/data/repositories.dart';
import 'core/data/sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Local storage is the source of truth and must be ready before any
  // provider reads from it.
  await LocalStore.init();
  Repositories.init();

  // Best-effort Firebase mirror. With no Firebase config in the project this
  // quietly no-ops and the app runs entirely on-device; see SyncService.
  await SyncService.instance.init();

  runApp(const NooLureApp());
}
