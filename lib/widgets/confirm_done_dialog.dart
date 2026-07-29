import 'package:flutter/material.dart';

/// Confirms marking a task done before actually doing it — shared by Home's
/// and the Tasks page's swipe-to-complete gestures so both ask the same way.
Future<void> confirmDoneTask(
  BuildContext context, {
  required String title,
  required VoidCallback onConfirm,
}) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Done task "$title"?'),
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
          child: const Text('Yes'),
        ),
      ],
    ),
  );
}
