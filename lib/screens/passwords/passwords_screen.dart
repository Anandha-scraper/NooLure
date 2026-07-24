import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/text_styles.dart';
import '../../models/password_model.dart';
import '../../providers/password_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/card_container.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/inline_confirm_card.dart';
import '../../widgets/password_preview_sheet.dart';
import '../../widgets/password_tile.dart';
import '../../widgets/pin_keypad.dart';

class PasswordsScreen extends StatefulWidget {
  const PasswordsScreen({super.key});

  @override
  State<PasswordsScreen> createState() => _PasswordsScreenState();
}

class _PasswordsScreenState extends State<PasswordsScreen> {
  String _selectedTag = 'All';
  String? _pinError;
  bool _confirmingSetup = false;
  String _firstPin = '';
  int _errorTick = 0;


  @override
  void dispose() {
    // Leaving the section — always re-lock, whether via back or the drawer.
    context.read<PasswordProvider>().lock();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PasswordProvider>();

    return AppScaffold(
      title: 'Passwords',
      drawerRoute: AppRoutes.passwords,
      body: !provider.hasVault
          ? _buildSetup(context)
          : provider.isLocked
          ? _buildUnlock(context, provider)
          : _buildList(context, provider),
      floatingActionButton: provider.hasVault && !provider.isLocked
          ? AppFab(
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.addPassword),
            )
          : null,
    );
  }

  Widget _buildSetup(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.keyRound,
              size: 40,
              color: AppColors.accentInk(
                Theme.of(context).colorScheme.primary,
                Theme.of(context).brightness,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _confirmingSetup ? 'Confirm your PIN' : 'Create a 4-digit PIN',
              style: TextStyles.h4(color: onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _confirmingSetup
                  ? 'Enter it once more to confirm'
                  : 'This protects your saved passwords',
              style: TextStyle(
                fontSize: 13,
                color: onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            if (!_confirmingSetup) ...[
              const SizedBox(height: 20),
              const _SecurityExplainer(),
            ],
            const SizedBox(height: 28),
            PinKeypad(errorTick: _errorTick, onComplete: _handleSetupDigits),
            if (_pinError != null) ...[
              const SizedBox(height: 16),
              Text(
                _pinError!,
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleSetupDigits(String digits) {
    if (!_confirmingSetup) {
      setState(() {
        _firstPin = digits;
        _confirmingSetup = true;
        _pinError = null;
        _errorTick++;
      });
      return;
    }
    if (digits != _firstPin) {
      setState(() {
        _confirmingSetup = false;
        _firstPin = '';
        _pinError = "PINs didn't match — start over";
        _errorTick++;
      });
      return;
    }
    context.read<PasswordProvider>().setupPin(digits);
  }

  Widget _buildUnlock(BuildContext context, PasswordProvider provider) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.lock,
              size: 40,
              color: AppColors.accentInk(
                Theme.of(context).colorScheme.primary,
                Theme.of(context).brightness,
              ),
            ),
            const SizedBox(height: 16),
            Text('Enter your PIN', style: TextStyles.h4(color: onSurface)),
            const SizedBox(height: 28),
            PinKeypad(errorTick: _errorTick, onComplete: (digits) => _handleUnlock(digits, provider)),
            if (_pinError != null) ...[
              const SizedBox(height: 16),
              Text(
                _pinError!,
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => _confirmReset(context, provider),
              child: const Text('Forgot PIN?'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleUnlock(String digits, PasswordProvider provider) async {
    final ok = await provider.unlock(digits);
    if (!mounted) return;
    setState(() {
      _pinError = ok ? null : 'Wrong PIN — try again';
      _errorTick++;
    });
  }

  Future<void> _confirmReset(
    BuildContext context,
    PasswordProvider provider,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Forgot your PIN?'),
        content: const Text(
          'Resetting erases every saved password'
          "can't be undone, since only the PIN can unlock them.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.resetVault();
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Erase and reset'),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, PasswordProvider provider) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final theme = Theme.of(context);
    final entries = provider.entries;
    final tags = {'All', ...entries.map((e) => e.meta.tag)}.toList();
    final filtered = _selectedTag == 'All'
        ? entries
        : entries.where((e) => e.meta.tag == _selectedTag).toList();

    final trashBg = swipeBackground(
      alignment: Alignment.centerRight,
      color: theme.colorScheme.error.withValues(alpha: 0.15),
      icon: LucideIcons.trash2,
      iconColor: theme.colorScheme.error,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        SizedBox(
          height: 30,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: tags.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final tag = tags[i];
              return _TagChipButton(
                label: tag,
                selected: tag == _selectedTag,
                onTap: () => setState(() => _selectedTag = tag),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        if (filtered.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'tap to view · long-press to edit · swipe left to delete',
              style: TextStyle(
                fontSize: 11,
                color: onSurface.withValues(alpha: 0.45),
              ),
            ),
          ),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Text(
              'No saved passwords yet — tap + to add one',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: onSurface.withValues(alpha: 0.5),
              ),
            ),
          )
        else
          for (final entry in filtered)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PasswordRow(
                meta: entry.meta,
                data: entry.data,
                trashBg: trashBg,
                provider: provider,
              ),
            ),
      ],
    );
  }
}

/// Short, non-technical explanation of how entries are protected — shown
/// once on the Create-PIN screen, before the user has saved anything, to
/// build trust without naming algorithms.
class _SecurityExplainer extends StatelessWidget {
  const _SecurityExplainer();

  static const _steps = [
    (LucideIcons.keyRound, 'You choose a 4-digit PIN'),
    (LucideIcons.shieldCheck, "That key locks every password before it's ever saved."),
    (
      LucideIcons.cloudOff,
      'Only the locked version is ever backed up , never the real password.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final ink = AppColors.accentInk(theme.colorScheme.primary, theme.brightness);

    return CardContainer(
      elevation: CardElevation.sm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (icon, text) in _steps)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 16, color: ink),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 12,
                        color: onSurface.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TagChipButton extends StatelessWidget {
  const _TagChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.softFill(primary, theme.brightness)
              : theme.cardTheme.color,
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            color: selected
                ? AppColors.softInk(primary, theme.brightness)
                : theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

enum _PendingAction { delete }

class _PasswordRow extends StatefulWidget {
  const _PasswordRow({
    required this.meta,
    required this.data,
    required this.trashBg,
    required this.provider,
  });

  final PasswordModel meta;
  final PasswordEntryData data;
  final Widget trashBg;
  final PasswordProvider provider;

  @override
  State<_PasswordRow> createState() => _PasswordRowState();
}

class _PasswordRowState extends State<_PasswordRow> {
  _PendingAction? _pending;

  void _openPreview() => showPasswordPreview(
    context,
    meta: widget.meta,
    data: widget.data,
    onEdit: _openEdit,
    onDelete: () => widget.provider.deleteEntry(widget.meta.id),
  );

  void _openEdit() => Navigator.of(context).pushNamed(
    AppRoutes.editPassword,
    arguments: (id: widget.meta.id, data: widget.data, tag: widget.meta.tag),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_pending != null) {
      return InlineConfirmCard(
        actionIcon: LucideIcons.trash2,
        actionColor: theme.colorScheme.error,
        actionLabel: 'Delete "${widget.meta.tag}"',
        height: 100,
        onConfirm: () {
          widget.provider.deleteEntry(widget.meta.id);
          setState(() => _pending = null);
        },
        onCancel: () => setState(() => _pending = null),
      );
    }

    return Dismissible(
      key: ValueKey(widget.meta.id),
      direction: DismissDirection.endToStart,
      background: widget.trashBg,
      confirmDismiss: (direction) async {
        setState(() => _pending = _PendingAction.delete);
        return false;
      },
      // Dismissible wraps its child in a Stack (to layer the swipe
      // background behind it) with the default loose fit, which lets the
      // card hug its own content width instead of filling the row. Force
      // it back to full width here, at the exact point Dismissible would
      // otherwise loosen it.
      child: SizedBox(
        width: double.infinity,
        child: PasswordTile(
          meta: widget.meta,
          data: widget.data,
          onTap: _openPreview,
          onLongPress: _openEdit,
        ),
      ),
    );
  }
}
