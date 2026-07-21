import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/text_styles.dart';
import '../../providers/note_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/confirm_delete_dialog.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/inline_confirm_card.dart';
import '../../widgets/note_preview_sheet.dart';
import '../../widgets/note_tile.dart';
import '../../widgets/tag_chip.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  String _selectedTag = 'All';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NoteProvider>();
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final pinned = provider.pinnedNote;
    final grid = provider.filteredGridNotes(_selectedTag);
    final archiveBg = swipeBackground(
      alignment: Alignment.centerLeft,
      color: AppColors.softFill(AppColors.accent2, theme.brightness),
      icon: LucideIcons.archive,
      iconColor: AppColors.softInk(AppColors.accent2, theme.brightness),
    );
    final trashBg = swipeBackground(
      alignment: Alignment.centerRight,
      color: theme.colorScheme.error.withValues(alpha: 0.15),
      icon: LucideIcons.trash2,
      iconColor: theme.colorScheme.error,
    );

    return AppScaffold(
      title: 'Notes',
      drawerRoute: AppRoutes.notes,
      titleStyle: TextStyles.h2(color: onSurface),
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.archive),
          tooltip: 'Archived notes',
          onPressed: () =>
              Navigator.of(context).pushNamed(AppRoutes.notesArchive),
        ),
        const SizedBox(width: 20),
        IconButton(
          icon: const Icon(LucideIcons.trash2),
          tooltip: 'Deleted notes',
          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.notesTrash),
        ),
        const SizedBox(width: 8),
      ],
      floatingActionButton: AppFab(
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.addNote),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.search,
                  size: 15,
                  color: onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 10),
                Text(
                  'Search notes, tags…',
                  style: TextStyle(
                    fontSize: 13,
                    color: onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 30,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: provider.availableTags.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final tag = provider.availableTags[i];
                return TagChip(
                  tag,
                  variant: tag == _selectedTag
                      ? TagVariant.accent
                      : TagVariant.neutral,
                  onTap: () => setState(() => _selectedTag = tag),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'tap to preview · long-press to edit · swipe to archive/trash',
            style: TextStyle(fontSize: 11, color: onSurface.withValues(alpha: 0.45)),
          ),
          const SizedBox(height: 12),
          if (pinned != null &&
              (_selectedTag == 'All' || _selectedTag == pinned.tag))
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _NoteRow(
                noteId: pinned.id,
                noteTitle: pinned.title,
                provider: provider,
                archiveBg: archiveBg,
                trashBg: trashBg,
                child: PinnedNoteCard(
                  note: pinned,
                  onToggleItem: (itemId) =>
                      provider.toggleChecklistItem(pinned.id, itemId),
                  onTap: () => showNotePreview(
                    context,
                    pinned,
                    onEdit: () => Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.editNote, arguments: pinned.id),
                    onTogglePin: () => provider.togglePinned(pinned.id),
                    onDelete: () => confirmDeleteTask(
                      context,
                      title: pinned.title,
                      onConfirm: () => provider.trashNote(pinned.id),
                    ),
                  ),
                  onLongPress: () => Navigator.of(
                    context,
                  ).pushNamed(AppRoutes.editNote, arguments: pinned.id),
                ),
              ),
            ),
          if (grid.isEmpty && pinned == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Text(
                'No notes yet — tap + to write one',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: grid.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.78,
            ),
            itemBuilder: (context, i) => _NoteRow(
              noteId: grid[i].id,
              noteTitle: grid[i].title,
              provider: provider,
              archiveBg: archiveBg,
              trashBg: trashBg,
              expand: true,
              child: NoteTile(
                note: grid[i],
                onTap: () => showNotePreview(
                  context,
                  grid[i],
                  onEdit: () => Navigator.of(
                    context,
                  ).pushNamed(AppRoutes.editNote, arguments: grid[i].id),
                  onTogglePin: () => provider.togglePinned(grid[i].id),
                  onDelete: () => confirmDeleteTask(
                    context,
                    title: grid[i].title,
                    onConfirm: () => provider.trashNote(grid[i].id),
                  ),
                ),
                onLongPress: () => Navigator.of(
                  context,
                ).pushNamed(AppRoutes.editNote, arguments: grid[i].id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _NotePendingAction { archive, trash }

/// Wraps a note card (pinned or grid) with swipe-to-archive/trash — instead
/// of firing immediately, the swipe arms a pending action and the card
/// flips into an [InlineConfirmCard], same as Tasks/Home/Trash. [expand]
/// forces the row to fill its grid cell regardless of content (needed for
/// the grid tile so cards stay equal-sized; must stay off for the singular
/// pinned card, which isn't in a bounded grid cell).
class _NoteRow extends StatefulWidget {
  const _NoteRow({
    required this.noteId,
    required this.noteTitle,
    required this.provider,
    required this.archiveBg,
    required this.trashBg,
    required this.child,
    this.expand = false,
  });

  final String noteId;
  final String noteTitle;
  final NoteProvider provider;
  final Widget archiveBg;
  final Widget trashBg;
  final Widget child;
  final bool expand;

  @override
  State<_NoteRow> createState() => _NoteRowState();
}

class _NoteRowState extends State<_NoteRow> {
  _NotePendingAction? _pending;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Widget content;
    if (_pending != null) {
      content = InlineConfirmCard(
        actionIcon: _pending == _NotePendingAction.archive
            ? LucideIcons.archive
            : LucideIcons.trash2,
        actionColor: _pending == _NotePendingAction.archive
            ? AppColors.accent2
            : theme.colorScheme.error,
        actionLabel: _pending == _NotePendingAction.archive
            ? 'Archive "${widget.noteTitle}"'
            : 'Move "${widget.noteTitle}" to trash',
        height: widget.expand ? null : 100,
        onConfirm: () {
          if (_pending == _NotePendingAction.archive) {
            widget.provider.archiveNote(widget.noteId);
          } else {
            widget.provider.trashNote(widget.noteId);
          }
          setState(() => _pending = null);
        },
        onCancel: () => setState(() => _pending = null),
      );
    } else {
      content = Dismissible(
        key: ValueKey(widget.noteId),
        background: widget.archiveBg,
        secondaryBackground: widget.trashBg,
        confirmDismiss: (direction) async {
          setState(() {
            _pending = direction == DismissDirection.startToEnd
                ? _NotePendingAction.archive
                : _NotePendingAction.trash;
          });
          return false;
        },
        // Dismissible wraps its child in a Stack (to layer the swipe
        // background behind it) with the default loose fit, which lets the
        // card hug its own content width instead of filling the row. Force
        // it back to full width here, at the exact point Dismissible would
        // otherwise loosen it.
        child: SizedBox(width: double.infinity, child: widget.child),
      );
    }
    return widget.expand ? SizedBox.expand(child: content) : content;
  }
}
