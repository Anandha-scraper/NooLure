import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../core/theme/text_styles.dart';
import '../core/utils/boldify_text.dart';
import '../core/utils/note_body_formatting.dart';
import '../models/note_model.dart';
import '../providers/note_provider.dart';
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
    // Re-fetched live so a checklist toggle from within this sheet (either
    // the structured list below or a body-embedded glyph) re-renders
    // immediately instead of showing the stale snapshot it was opened with.
    final liveNote = context.watch<NoteProvider>().byId(note.id) ?? note;

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
              TagChip(liveNote.tag),
              const SizedBox(height: 10),
              Text(liveNote.title, style: TextStyles.h4(color: onSurface)),
              const SizedBox(height: 4),
              Text(
                'Edited ${liveNote.editedLabel}',
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
                      if (liveNote.body.isNotEmpty)
                        SelectableText.rich(
                          TextSpan(
                            children: formatNoteBody(
                              liveNote.body,
                              baseStyle: TextStyle(
                                fontSize: 13.5,
                                color: onSurface.withValues(alpha: 0.8),
                              ),
                              boldStyle: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: onSurface.withValues(alpha: 0.8),
                              ),
                              linkStyle: TextStyle(
                                fontSize: 13.5,
                                color: theme.colorScheme.primary,
                                decoration: TextDecoration.underline,
                              ),
                              onToggleChecklist: (lineStartOffset) {
                                final result = toggleChecklistAtOffset(
                                  liveNote.body,
                                  lineStartOffset,
                                );
                                if (result == null) return;
                                context.read<NoteProvider>().updateNote(
                                  liveNote.copyWith(body: result.body),
                                );
                              },
                            ),
                          ),
                        ),
                      if (liveNote.checklist.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        for (final item in liveNote.checklist)
                          GestureDetector(
                            onTap: () => context
                                .read<NoteProvider>()
                                .toggleChecklistItem(liveNote.id, item.id),
                            child: Padding(
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
                      color: liveNote.isPinned ? theme.colorScheme.primary : null,
                    ),
                    label: Text(liveNote.isPinned ? 'Unpin' : 'Pin'),
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
