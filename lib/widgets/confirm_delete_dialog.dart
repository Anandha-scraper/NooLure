import 'package:flutter/material.dart';

/// Confirms deleting a task before actually doing it — mirrors
/// [confirmDoneTask]'s pattern so completing and deleting feel consistent.
Future<void> confirmDeleteTask(
  BuildContext context, {
  required String title,
  required VoidCallback onConfirm,
}) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Delete task "$title"?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            onConfirm();
            Navigator.of(dialogContext).pop();
          },
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}
