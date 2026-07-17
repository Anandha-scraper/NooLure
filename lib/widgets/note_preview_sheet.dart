import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme/text_styles.dart';
import '../core/utils/linkify_text.dart';
import '../models/note_model.dart';
import 'tag_chip.dart';

/// Read-only glance at a note — shown on tap. Carries the actions that used
/// to live in a long-press menu (Pin/Unpin, Delete) plus Edit, since
/// long-press now jumps straight to the edit screen.
Future<void> showNotePreview(
  BuildContext context,
  NoteModel note, {
  required VoidCallback onEdit,
  required VoidCallback onTogglePin,
  required VoidCallback onDelete,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => _NotePreviewSheet(
      note: note,
      onEdit: () {
        Navigator.of(sheetContext).pop();
        onEdit();
      },
      onTogglePin: () {
        Navigator.of(sheetContext).pop();
        onTogglePin();
      },
      onDelete: () {
        Navigator.of(sheetContext).pop();
        onDelete();
      },
    ),
  );
}

class _NotePreviewSheet extends StatelessWidget {
  const _NotePreviewSheet({
    required this.note,
    required this.onEdit,
    required this.onTogglePin,
    required this.onDelete,
  });

  final NoteModel note;
  final VoidCallback onEdit;
  final VoidCallback onTogglePin;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TagChip(note.tag),
              const SizedBox(height: 10),
              Text(note.title, style: TextStyles.h4(color: onSurface)),
              const SizedBox(height: 4),
              Text(
                'Edited ${note.editedLabel}',
                style: TextStyle(
                  fontSize: 11.5,
                  color: onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (note.body.isNotEmpty)
                        SelectableText.rich(
                          TextSpan(
                            children: linkify(
                              note.body,
                              baseStyle: TextStyle(
                                fontSize: 13.5,
                                color: onSurface.withValues(alpha: 0.8),
                              ),
                              linkStyle: TextStyle(
                                fontSize: 13.5,
                                color: theme.colorScheme.primary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      if (note.checklist.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        for (final item in note.checklist)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                Icon(
                                  item.done
                                      ? LucideIcons.checkSquare
                                      : LucideIcons.square,
                                  size: 15,
                                  color: onSurface.withValues(alpha: 0.6),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: onSurface.withValues(
                                        alpha: item.done ? 0.5 : 0.85,
                                      ),
                                      decoration: item.done
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onTogglePin,
                    icon: Icon(
                      LucideIcons.pin,
                      size: 16,
                      color: note.isPinned ? theme.colorScheme.primary : null,
                    ),
                    label: Text(note.isPinned ? 'Unpin' : 'Pin'),
                  ),
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(LucideIcons.trash2, size: 16),
                    label: const Text('Delete'),
                  ),
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(LucideIcons.pencil, size: 16),
                    label: const Text('Edit'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
