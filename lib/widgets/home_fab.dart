import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/constants/app_colors.dart';
import 'custom_button.dart';

/// Home's "+" button — tap expands it into 3 labeled mini-FABs (Task /
/// Note / Birthday) instead of jumping straight to one screen, since Home
/// is the one place that creates all three record types.
class HomeFab extends StatefulWidget {
  const HomeFab({
    super.key,
    required this.onTask,
    required this.onNote,
    required this.onBirthday,
  });

  final VoidCallback onTask;
  final VoidCallback onNote;
  final VoidCallback onBirthday;

  @override
  State<HomeFab> createState() => _HomeFabState();
}

class _HomeFabState extends State<HomeFab> {
  bool _open = false;

  void _toggle() => setState(() => _open = !_open);

  void _select(VoidCallback action) {
    setState(() => _open = false);
    action();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: Alignment.bottomCenter,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: _open ? 1 : 0,
            child: !_open
                ? const SizedBox(width: 58)
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _MiniFabAction(
                        icon: LucideIcons.cake,
                        label: 'Birthday',
                        onPressed: () => _select(widget.onBirthday),
                      ),
                      const SizedBox(height: 12),
                      _MiniFabAction(
                        icon: LucideIcons.stickyNote,
                        label: 'Note',
                        onPressed: () => _select(widget.onNote),
                      ),
                      const SizedBox(height: 12),
                      _MiniFabAction(
                        icon: LucideIcons.listTodo,
                        label: 'Task',
                        onPressed: () => _select(widget.onTask),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
          ),
        ),
        AnimatedRotation(
          turns: _open ? 0.125 : 0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: AppFab(onPressed: _toggle, icon: _open ? Icons.close : Icons.add),
        ),
      ],
    );
  }
}

class _MiniFabAction extends StatelessWidget {
  const _MiniFabAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(999),
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              boxShadow: AppColors.shadowSm(theme.brightness),
            ),
            child: Text(
              label,
              style: TextStyle(fontSize: 12.5, color: onSurface),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 44,
          height: 44,
          child: FloatingActionButton(
            heroTag: null,
            mini: false,
            onPressed: onPressed,
            shape: const CircleBorder(),
            child: Icon(icon, size: 20),
          ),
        ),
      ],
    );
  }
}
