import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/routes/route_observer.dart';
import '../../core/utils/date_labels.dart';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/inline_confirm_card.dart';
import '../../widgets/tag_chip.dart';
import '../../widgets/task_preview_sheet.dart';

class TaskArchiveScreen extends StatefulWidget {
  const TaskArchiveScreen({super.key});

  @override
  State<TaskArchiveScreen> createState() => _TaskArchiveScreenState();
}

class _TaskArchiveScreenState extends State<TaskArchiveScreen>
    with RouteAware {
  // Only one row's swipe-confirm can be armed at a time, owned here so
  // arming a new one disarms whichever was armed before, and cleared when
  // this screen becomes visible again after a pushed route is popped.
  String? _armedId;
  _PendingAction? _armedAction;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    appRouteObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() => setState(() {
    _armedId = null;
    _armedAction = null;
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final archived = provider.archivedTasks;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return AppScaffold(
      title: 'Archived Tasks',
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
                    'No archived tasks',
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
                    itemBuilder: (context, i) {
                      final task = archived[i];
                      return _ArchiveRow(
                        task: task,
                        provider: provider,
                        isArmed: _armedId == task.id,
                        armedAction: _armedId == task.id ? _armedAction : null,
                        onArm: (action) => setState(() {
                          _armedId = task.id;
                          _armedAction = action;
                        }),
                        onDisarm: () => setState(() {
                          _armedId = null;
                          _armedAction = null;
                        }),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

enum _PendingAction { restore, delete }

/// The armed state ([isArmed]/[armedAction]/[onArm]/[onDisarm]) is owned by
/// the parent screen so only one row across the page is ever armed at once.
class _ArchiveRow extends StatelessWidget {
  const _ArchiveRow({
    required this.task,
    required this.provider,
    required this.isArmed,
    required this.armedAction,
    required this.onArm,
    required this.onDisarm,
  });

  final TaskModel task;
  final TaskProvider provider;
  final bool isArmed;
  final _PendingAction? armedAction;
  final ValueChanged<_PendingAction> onArm;
  final VoidCallback onDisarm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: isArmed
          ? InlineConfirmCard(
              actionIcon: armedAction == _PendingAction.restore
                  ? LucideIcons.archiveRestore
                  : LucideIcons.trash2,
              actionColor: armedAction == _PendingAction.restore
                  ? AppColors.accent2
                  : theme.colorScheme.error,
              actionLabel: armedAction == _PendingAction.restore
                  ? 'Restore "${task.title}"'
                  : 'Permanently delete "${task.title}"',
              height: 78,
              onConfirm: () {
                if (armedAction == _PendingAction.restore) {
                  _unarchive(context);
                } else {
                  _delete(context);
                }
                onDisarm();
              },
              onCancel: onDisarm,
            )
          : Dismissible(
              key: ValueKey(task.id),
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
                onArm(
                  direction == DismissDirection.startToEnd
                      ? _PendingAction.restore
                      : _PendingAction.delete,
                );
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  task.title,
                                  style: TextStyle(fontSize: 14.5, color: onSurface),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      'Archived ${DateLabels.relativeLabel(task.archivedAt!)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: onSurface.withValues(alpha: 0.55),
                                      ),
                                    ),
                                    TagChip(task.category),
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
    showTaskPreview(context, task, onEdit: null, onToggleDone: null);
  }

  void _unarchive(BuildContext context) {
    provider.unarchiveTask(task.id);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Task unarchived')));
  }

  void _delete(BuildContext context) {
    provider.permanentlyDeleteTask(task.id);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Task deleted')));
  }
}
