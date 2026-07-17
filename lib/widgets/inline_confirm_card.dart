import 'package:flutter/material.dart';

import 'card_container.dart';

/// A swipe-reveal background — a colored, rounded strip with a single icon,
/// aligned to whichever edge the swipe is coming from. Shared by every
/// `Dismissible` in the app so they all look the same mid-swipe.
Widget swipeBackground({
  required Alignment alignment,
  required Color color,
  required IconData icon,
  required Color iconColor,
}) {
  return Container(
    alignment: alignment,
    padding: const EdgeInsets.symmetric(horizontal: 24),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(32),
    ),
    child: Icon(icon, color: iconColor),
  );
}

/// Replaces a popped-up `AlertDialog` confirmation with one that lives
/// inside the card itself — shown in place of the normal row content once a
/// swipe (or other trigger) has armed a pending action.
class InlineConfirmCard extends StatelessWidget {
  const InlineConfirmCard({
    super.key,
    required this.message,
    required this.confirmLabel,
    required this.onConfirm,
    required this.onCancel,
  });

  final String message;
  final String confirmLabel;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return CardContainer(
      elevation: CardElevation.sm,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 13.5, color: onSurface),
            ),
          ),
          TextButton(onPressed: onCancel, child: const Text('Cancel')),
          FilledButton(onPressed: onConfirm, child: Text(confirmLabel)),
        ],
      ),
    );
  }
}
