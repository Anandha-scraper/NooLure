import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:noolure/core/data/repository.dart';
import 'package:noolure/models/task_model.dart';

/// Exercises the local-first guarantee: with no Firebase configured (the state
/// the app ships in), writes still land on disk, survive a restart, and push
/// through the watch() stream.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('noolure_test');
    Hive.init(tempDir.path);
    await Hive.openBox<String>('tasks');
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Repository<TaskModel> buildRepository() => Repository(
    collection: 'tasks',
    fromJson: TaskModel.fromJson,
    toJson: (t) => t.toJson(),
    idOf: (t) => t.id,
  );

  TaskModel task(String id, {String title = 'Call mom', DateTime? updatedAt}) {
    final now = updatedAt ?? DateTime(2026, 7, 13, 12);
    return TaskModel(
      id: id,
      title: title,
      priority: TaskPriority.medium,
      category: 'Personal',
      dueAt: DateTime(2026, 7, 13, 15),
      createdAt: DateTime(2026, 7, 13, 12),
      updatedAt: now,
    );
  }

  test('saves and reads back a task with no backend configured', () async {
    final repository = buildRepository();
    await repository.save(task('t1'));

    final loaded = repository.byId('t1');
    expect(loaded, isNotNull);
    expect(loaded!.title, 'Call mom');
    expect(loaded.dueAt, DateTime(2026, 7, 13, 15));
    expect(loaded.priority, TaskPriority.medium);
  });

  test('data written offline survives a restart', () async {
    await buildRepository().save(task('t1', title: 'Written on a plane'));

    // Simulate relaunching the app against the same on-disk box.
    await Hive.close();
    Hive.init(tempDir.path);
    await Hive.openBox<String>('tasks');

    expect(buildRepository().byId('t1')?.title, 'Written on a plane');
  });

  test('watch() emits current contents then every change', () async {
    final repository = buildRepository();
    await repository.save(task('t1'));

    final emissions = <List<TaskModel>>[];
    final subscription = repository.watch().listen(emissions.add);
    // watch() yields its seed emission on the microtask after listen, so let
    // that land before mutating — otherwise the first frame already sees t2.
    await Future<void>.delayed(Duration.zero);

    await repository.save(task('t2', title: 'Second'));
    await repository.delete('t1');
    await Future<void>.delayed(Duration.zero);
    await subscription.cancel();

    expect(emissions.first.map((t) => t.id), ['t1']);
    expect(emissions.last.map((t) => t.id), ['t2']);
  });

  test('delete removes the record', () async {
    final repository = buildRepository();
    await repository.save(task('t1'));
    await repository.delete('t1');

    expect(repository.byId('t1'), isNull);
    expect(repository.all(), isEmpty);
  });

  group('mergeRemote (last-write-wins on updatedAt)', () {
    test('accepts a remote copy that is newer than ours', () async {
      final repository = buildRepository();
      await repository.save(task('t1', title: 'Local'));

      await repository.mergeRemote(
        't1',
        task(
          't1',
          title: 'Remote, newer',
          updatedAt: DateTime(2026, 7, 13, 18),
        ).toJson(),
      );

      expect(repository.byId('t1')?.title, 'Remote, newer');
    });

    test('rejects a remote copy that is older than ours', () async {
      final repository = buildRepository();
      await repository.save(
        task('t1', title: 'Local, newer', updatedAt: DateTime(2026, 7, 13, 18)),
      );

      await repository.mergeRemote(
        't1',
        task(
          't1',
          title: 'Remote, stale',
          updatedAt: DateTime(2026, 7, 13, 9),
        ).toJson(),
      );

      expect(repository.byId('t1')?.title, 'Local, newer');
    });
  });

  test('a corrupt record does not take down the whole list', () async {
    final repository = buildRepository();
    await repository.save(task('t1'));
    await Hive.box<String>('tasks').put('bad', '{not valid json');

    expect(repository.all().map((t) => t.id), ['t1']);
  });
}
