import 'package:flutter/material.dart';

Future<void> confirmDeleteTask(
  BuildContext context, {
  required String title,
  required VoidCallback onConfirm,
  bool permanent = false,
}) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
        permanent
            ? 'Permanently delete "$title"?'
            : 'Move "$title" to trash?',
      ),
      content: permanent ? const Text('This cannot be undone.') : null,
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
          child: Text(permanent ? 'Delete forever' : 'Move to trash'),
        ),
      ],
    ),
  );
}
