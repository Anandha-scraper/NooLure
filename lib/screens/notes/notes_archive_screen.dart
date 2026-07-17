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
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              itemCount: archived.length,
              itemBuilder: (context, i) =>
                  _ArchiveRow(note: archived[i], provider: provider),
            ),
    );
  }
}

class _ArchiveRow extends StatelessWidget {
  const _ArchiveRow({required this.note, required this.provider});

  final NoteModel note;
  final NoteProvider provider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey(note.id),
        direction: DismissDirection.startToEnd,
        background: swipeBackground(
          alignment: Alignment.centerLeft,
          color: AppColors.softFill(AppColors.accent2, theme.brightness),
          icon: LucideIcons.archiveRestore,
          iconColor: AppColors.softInk(AppColors.accent2, theme.brightness),
        ),
        confirmDismiss: (direction) async {
          _unarchive(context);
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
    );
  }

  void _unarchive(BuildContext context) {
    provider.unarchiveNote(note.id);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Note unarchived')));
  }
}
