import 'package:flutter/material.dart';

import '../core/theme/text_styles.dart';
import '../models/password_model.dart';
import 'card_container.dart';

/// List tile for one decrypted password entry — visual pattern lifted from
/// [NoteTile]. The password itself is always masked here; revealing it is a
/// preview-sheet action, never inline in the list.
///
/// The username line is wrapped in a fixed-height [SizedBox] rather than
/// rendered as a bare [Text], because an empty `Text('')` lays out at zero
/// height in Flutter — it does not reserve one line's worth of space the way
/// non-empty text does. Without the fixed height, a card with no username
/// would render visibly shorter than one with a username, even though both
/// use the same widget.
class PasswordTile extends StatelessWidget {
  const PasswordTile({
    super.key,
    required this.meta,
    required this.data,
    this.onTap,
    this.onLongPress,
  });

  final PasswordModel meta;
  final PasswordEntryData data;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: CardContainer(
        elevation: CardElevation.sm,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              meta.tag.isEmpty ? '(untitled)' : meta.tag,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyles.cardTitle(context),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 18,
              child: Text(
                data.username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyles.cardBody(context),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '••••••••',
              style: TextStyle(
                fontSize: 13,
                letterSpacing: 2,
                color: onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            CardMeta('Edited ${meta.editedLabel}'),
          ],
        ),
      ),
    );
  }
}
