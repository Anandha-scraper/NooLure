import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/date_labels.dart';
import '../../models/note_model.dart';
import '../../providers/note_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/confirm_delete_dialog.dart';
import '../../widgets/inline_confirm_card.dart';
import '../../widgets/note_preview_sheet.dart';
import '../../widgets/tag_chip.dart';

class NotesArchiveScreen extends StatelessWidget {
  const NotesArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NoteProvider>();
    final archived = provider.archivedNotes;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return AppScaffold(
      title: 'Archived Notes',
      body: archived.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.archive,
                    size: 40,
                    color: onSurface.withValues(alpha: 0.25),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No archived notes',
                    style: TextStyle(
                      fontSize: 14,
                      color: onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'tap to view · swipe right to unarchive · swipe left to delete',
                      style: TextStyle(
                        fontSize: 11,
                        color: onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: archived.length,
                    itemBuilder: (context, i) =>
                        _ArchiveRow(note: archived[i], provider: provider),
                  ),
                ),
              ],
            ),
    );
  }
}

enum _PendingAction { restore, delete }

class _ArchiveRow extends StatefulWidget {
  const _ArchiveRow({required this.note, required this.provider});

  final NoteModel note;
  final NoteProvider provider;

  @override
  State<_ArchiveRow> createState() => _ArchiveRowState();
}

class _ArchiveRowState extends State<_ArchiveRow> {
  _PendingAction? _pending;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final note = widget.note;

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
                  _unarchive(context);
                } else {
                  _delete(context);
                }
                setState(() => _pending = null);
              },
              onCancel: () => setState(() => _pending = null),
            )
          : Dismissible(
        key: ValueKey(note.id),
        direction: DismissDirection.horizontal,
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
            child: InkWell(
              borderRadius: BorderRadius.circular(32),
              onTap: () => _view(context),
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
                                'Archived ${DateLabels.relativeLabel(note.archivedAt!)}',
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
                      tooltip: 'Unarchive',
                      onPressed: () => _unarchive(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _view(BuildContext context) {
    final note = widget.note;
    showNotePreview(
      context,
      note,
      onEdit: () =>
          Navigator.of(context).pushNamed(AppRoutes.editNote, arguments: note.id),
      onTogglePin: () => widget.provider.togglePinned(note.id),
      onDelete: () => confirmDeleteTask(
        context,
        title: note.title,
        permanent: true,
        onConfirm: () => _delete(context),
      ),
    );
  }

  void _unarchive(BuildContext context) {
    widget.provider.unarchiveNote(widget.note.id);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Note unarchived')));
  }

  void _delete(BuildContext context) {
    widget.provider.permanentlyDeleteNote(widget.note.id);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Note deleted')));
  }
}
