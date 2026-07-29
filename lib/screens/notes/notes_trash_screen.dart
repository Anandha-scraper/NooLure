import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/date_labels.dart';
import '../../models/note_model.dart';
import '../../providers/note_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/inline_confirm_card.dart';
import '../../widgets/tag_chip.dart';

class NotesTrashScreen extends StatelessWidget {
  const NotesTrashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NoteProvider>();
    final trashed = provider.trashedNotes;
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return AppScaffold(
      title: 'Deleted Notes',
      actions: trashed.isNotEmpty
          ? [
              IconButton(
                icon: const Icon(LucideIcons.trash2),
                tooltip: 'Empty trash',
                onPressed: () => _confirmEmptyTrash(context, provider, trashed.length),
              ),
              const SizedBox(width: 8),
            ]
          : null,
      body: trashed.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.trash2,
                    size: 40,
                    color: onSurface.withValues(alpha: 0.25),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Trash is empty',
                    style: TextStyle(
                      fontSize: 14,
                      color: onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              itemCount: trashed.length,
              itemBuilder: (context, i) => _NotesTrashRow(
                note: trashed[i],
                provider: provider,
              ),
            ),
    );
  }

  Future<void> _confirmEmptyTrash(
    BuildContext context,
    NoteProvider provider,
    int count,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Permanently delete $count ${count == 1 ? 'note' : 'notes'}?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.emptyTrash();
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Delete all'),
          ),
        ],
      ),
    );
  }
}

enum _PendingAction { restore, delete }

class _NotesTrashRow extends StatefulWidget {
  const _NotesTrashRow({required this.note, required this.provider});

  final NoteModel note;
  final NoteProvider provider;

  @override
  State<_NotesTrashRow> createState() => _NotesTrashRowState();
}

class _NotesTrashRowState extends State<_NotesTrashRow> {
  _PendingAction? _pending;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final note = widget.note;
    final provider = widget.provider;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _pending != null
          ? InlineConfirmCard(
              actionIcon: _pending == _PendingAction.restore
                  ? LucideIcons.archiveRestore
                  : LucideIcons.trash2,
              actionColor: _pending == _PendingAction.restore
                  ? AppColors.accent2
                  : theme.colorScheme.error,
              actionLabel: _pending == _PendingAction.restore
                  ? 'Restore "${note.title}"'
                  : 'Permanently delete "${note.title}"',
              height: 78,
              onConfirm: () {
                if (_pending == _PendingAction.restore) {
                  _restore(context, provider, note);
                } else {
                  provider.permanentlyDeleteNote(note.id);
                }
                setState(() => _pending = null);
              },
              onCancel: () => setState(() => _pending = null),
            )
          : Dismissible(
        key: ValueKey(note.id),
        background: swipeBackground(
          alignment: Alignment.centerLeft,
          color: AppColors.softFill(AppColors.accent2, theme.brightness),
          icon: LucideIcons.archiveRestore,
          iconColor: AppColors.softInk(AppColors.accent2, theme.brightness),
        ),
        secondaryBackground: swipeBackground(
          alignment: Alignment.centerRight,
          color: theme.colorScheme.error.withValues(alpha: 0.15),
          icon: LucideIcons.trash2,
          iconColor: theme.colorScheme.error,
        ),
        confirmDismiss: (direction) async {
          setState(() {
            _pending = direction == DismissDirection.startToEnd
                ? _PendingAction.restore
                : _PendingAction.delete;
          });
          return false;
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: AppColors.shadowSm(theme.brightness),
          ),
          child: Material(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(32),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          note.title,
                          style: TextStyle(fontSize: 14.5, color: onSurface),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Deleted ${DateLabels.relativeLabel(note.deletedAt!)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: onSurface.withValues(alpha: 0.55),
                              ),
                            ),
                            TagChip(note.tag),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      LucideIcons.archiveRestore,
                      size: 18,
                      color: AppColors.accentInk(
                        theme.colorScheme.primary,
                        theme.brightness,
                      ),
                    ),
                    tooltip: 'Restore',
                    onPressed: () => _restore(context, provider, note),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}

void _restore(BuildContext context, NoteProvider provider, NoteModel note) {
  provider.restoreNote(note.id);
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('Note restored')));
}
