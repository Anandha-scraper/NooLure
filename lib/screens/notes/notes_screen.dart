import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/text_styles.dart';
import '../../providers/note_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/custom_button.dart';
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
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final pinned = provider.pinnedNote;
    final grid = provider.filteredGridNotes(_selectedTag);

    return AppScaffold(
      title: 'Notes',
      drawerRoute: AppRoutes.notes,
      titleStyle: TextStyles.h2(color: onSurface),
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
          const SizedBox(height: 16),
          if (pinned != null &&
              (_selectedTag == 'All' || _selectedTag == pinned.tag))
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: PinnedNoteCard(
                note: pinned,
                onToggleItem: (itemId) =>
                    provider.toggleChecklistItem(pinned.id, itemId),
                onTap: () => Navigator.of(
                  context,
                ).pushNamed(AppRoutes.editNote, arguments: pinned.id),
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
            itemBuilder: (context, i) => NoteTile(
              note: grid[i],
              onDelete: () => provider.deleteNote(grid[i].id),
              onTogglePin: () => provider.togglePinned(grid[i].id),
              onTap: () => Navigator.of(
                context,
              ).pushNamed(AppRoutes.editNote, arguments: grid[i].id),
            ),
          ),
        ],
      ),
    );
  }
}
