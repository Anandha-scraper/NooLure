import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/constants/app_colors.dart';

/// Swipe-reveal background — a colored, rounded strip with a single icon,
/// aligned to whichever edge the swipe is coming from. Shared by every
/// `Dismissible` in the app so they all look the same mid-swipe (before the
/// threshold arms a pending action and swaps in [InlineConfirmCard]).
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

/// Replaces a swiped card once an action is armed: the card itself splits
/// left/right instead of popping a dialog or showing a button row. Left half
/// always cancels (X), right half is the specific action alone — icon-only,
/// so there's nothing that can overflow regardless of how narrow the card is
/// (unlike the old Cancel/Confirm button row, which broke in the notes grid).
class InlineConfirmCard extends StatelessWidget {
  const InlineConfirmCard({
    super.key,
    required this.actionIcon,
    required this.actionColor,
    required this.actionLabel,
    required this.onConfirm,
    required this.onCancel,
    this.height,
  });

  /// Icon for the right half, e.g. LucideIcons.check / .trash2 / .archive /
  /// .archiveRestore.
  final IconData actionIcon;

  /// Base semantic color the right half's fill/ink are derived from via
  /// [AppColors.softFill]/[AppColors.softInk] — [AppColors.accent2] for
  /// positive actions (done/archive/restore), the theme's error color for
  /// destructive ones.
  final Color actionColor;

  /// Screen-reader-only description of the right-half action (e.g. 'Archive
  /// "Grocery list"'). Not rendered as visible text — icon-only by design.
  final String actionLabel;

  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  /// Bounds the card's height when the parent doesn't already provide a tight
  /// constraint. Leave null only when the parent already constrains height
  /// tightly (e.g. a grid cell wrapped in SizedBox.expand) — the Row of two
  /// Expanded halves needs a bounded height from somewhere.
  final double? height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    final cancelFill = theme.cardTheme.color ?? theme.colorScheme.surface;
    final cancelInk = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    final actionFill = AppColors.softFill(actionColor, brightness);
    final actionInk = AppColors.softInk(actionColor, brightness);
    final divider = theme.dividerColor.withValues(alpha: 0.4);

    final split = ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Row(
        children: [
          Expanded(
            child: _ConfirmHalf(
              icon: LucideIcons.x,
              background: cancelFill,
              iconColor: cancelInk,
              semanticLabel: 'Cancel',
              onTap: onCancel,
            ),
          ),
          Container(width: 1, color: divider),
          Expanded(
            child: _ConfirmHalf(
              icon: actionIcon,
              background: actionFill,
              iconColor: actionInk,
              semanticLabel: actionLabel,
              onTap: onConfirm,
            ),
          ),
        ],
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: AppColors.shadowSm(brightness),
      ),
      child: height == null ? split : SizedBox(height: height, child: split),
    );
  }
}

class _ConfirmHalf extends StatelessWidget {
  const _ConfirmHalf({
    required this.icon,
    required this.background,
    required this.iconColor,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final Color background;
  final Color iconColor;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: background,
        child: InkWell(
          onTap: onTap,
          child: Center(child: Icon(icon, color: iconColor, size: 22)),
        ),
      ),
    );
  }
}
