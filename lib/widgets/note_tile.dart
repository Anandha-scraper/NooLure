import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/constants/app_colors.dart';
import '../core/theme/text_styles.dart';
import '../models/note_model.dart';
import 'card_container.dart';
import 'tag_chip.dart';

/// Regular note card shown in the 2-column grid.
class NoteTile extends StatelessWidget {
  const NoteTile({super.key, required this.note, this.onTap, this.onLongPress});

  final NoteModel note;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: CardContainer(
        elevation: CardElevation.sm,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            TagChip(note.tag),
            if (note.isImage) ...[
              const SizedBox(height: 8),
              Container(
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.softFill(
                        theme.colorScheme.primary,
                        theme.brightness,
                      ),
                      AppColors.softFill(AppColors.accent2, theme.brightness),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                note.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyles.cardTitle(context),
              ),
            ),
            if (note.body.isNotEmpty) ...[
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  note.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyles.cardBody(context),
                ),
              ),
            ],
            const SizedBox(height: 8),
            CardMeta('Edited ${note.editedLabel}'),
          ],
        ),
      ),
    );
  }
}

/// The pinned "sticky note" highlight card with a mini checklist preview.
///
/// This one deliberately keeps its fixed yellow/ink pair in both themes — it's
/// a sticky note, and a sticky note is yellow.
class PinnedNoteCard extends StatelessWidget {
  const PinnedNoteCard({
    super.key,
    required this.note,
    required this.onToggleItem,
    this.onTap,
    this.onLongPress,
  });

  final NoteModel note;
  final ValueChanged<String> onToggleItem;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: CardContainer(
        color: AppColors.highlight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.highlightText.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    note.tag,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.highlightText,
                    ),
                  ),
                ),
                const Icon(
                  LucideIcons.pin,
                  size: 14,
                  color: AppColors.highlightText,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              note.title,
              // Caprasimo, matching NoteTile's title — these two cards sit
              // side by side and used to render the same element in different
              // typefaces.
              style: TextStyles.heading(
                size: 17,
                color: AppColors.highlightText,
              ),
            ),
            const SizedBox(height: 6),
            for (final item in note.checklist)
              GestureDetector(
                onTap: () => onToggleItem(item.id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      if (item.done)
                        const Icon(
                          LucideIcons.check,
                          size: 13,
                          color: AppColors.highlightText,
                        )
                      else
                        Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: AppColors.highlightText,
                              width: 1.5,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.highlightText,
                            decoration: item.done
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
