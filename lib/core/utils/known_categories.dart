import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/note_provider.dart';
import '../../providers/task_provider.dart';

/// The union of every category a task has used and every tag a note has
/// used, so typing a new one in either feature makes it suggestible in both.
List<String> knownCategories(BuildContext context) {
  final taskCategories = context.read<TaskProvider>().tasks.map(
    (t) => t.category,
  );
  final noteTags = context.read<NoteProvider>().notes.map((n) => n.tag);
  final all = {...taskCategories, ...noteTags}
    ..removeWhere((s) => s.trim().isEmpty);
  return all.toList()..sort();
}
