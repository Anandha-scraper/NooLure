import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme/text_styles.dart';
import '../models/password_model.dart';

/// Read-only glance at a decrypted entry — masked password with a reveal
/// toggle, copy (auto-clears the clipboard after 20s), Edit, Delete.
Future<void> showPasswordPreview(
  BuildContext context, {
  required PasswordModel meta,
  required PasswordEntryData data,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => _PasswordPreviewSheet(
      meta: meta,
      data: data,
      onEdit: () {
        Navigator.of(sheetContext).pop();
        onEdit();
      },
      onDelete: () {
        Navigator.of(sheetContext).pop();
        onDelete();
      },
    ),
  );
}

class _PasswordPreviewSheet extends StatefulWidget {
  const _PasswordPreviewSheet({
    required this.meta,
    required this.data,
    required this.onEdit,
    required this.onDelete,
  });

  final PasswordModel meta;
  final PasswordEntryData data;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_PasswordPreviewSheet> createState() => _PasswordPreviewSheetState();
}

class _PasswordPreviewSheetState extends State<_PasswordPreviewSheet> {
  bool _revealed = false;
  Timer? _clipboardClearTimer;

  @override
  void dispose() {
    _clipboardClearTimer?.cancel();
    super.dispose();
  }

  Future<void> _copyPassword() async {
    final password = widget.data.password;
    await Clipboard.setData(ClipboardData(text: password));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password copied — clears in 20s')),
      );
    }
    _clipboardClearTimer?.cancel();
    _clipboardClearTimer = Timer(const Duration(seconds: 20), () async {
      final current = await Clipboard.getData(Clipboard.kTextPlain);
      if (current?.text == password) {
        await Clipboard.setData(const ClipboardData(text: ''));
      }
    });
  }

  Future<void> _copyUsername() async {
    await Clipboard.setData(ClipboardData(text: widget.data.username));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Username copied')));
  }

  Future<void> _copyUrl() async {
    await Clipboard.setData(ClipboardData(text: widget.data.url));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('URL copied')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final data = widget.data;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.meta.tag, style: TextStyles.h4(color: onSurface)),
            const SizedBox(height: 4),
            Text(
              'Edited ${widget.meta.editedLabel}',
              style: TextStyle(
                fontSize: 11.5,
                color: onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 18),
            if (data.username.isNotEmpty) ...[
              _Field(
                label: 'Username',
                value: data.username,
                onSurface: onSurface,
                trailing: IconButton(
                  icon: const Icon(LucideIcons.copy, size: 18),
                  tooltip: 'Copy',
                  onPressed: _copyUsername,
                ),
              ),
              const SizedBox(height: 12),
            ],
            _Field(
              label: 'Password',
              value: _revealed ? data.password : '••••••••',
              onSurface: onSurface,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      _revealed ? LucideIcons.eyeOff : LucideIcons.eye,
                      size: 18,
                    ),
                    tooltip: _revealed ? 'Hide' : 'Reveal',
                    onPressed: () => setState(() => _revealed = !_revealed),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.copy, size: 18),
                    tooltip: 'Copy',
                    onPressed: _copyPassword,
                  ),
                ],
              ),
            ),
            if (data.url.isNotEmpty) ...[
              const SizedBox(height: 12),
              _Field(
                label: 'URL',
                value: data.url,
                onSurface: onSurface,
                trailing: IconButton(
                  icon: const Icon(LucideIcons.copy, size: 18),
                  tooltip: 'Copy',
                  onPressed: _copyUrl,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: widget.onDelete,
                  icon: const Icon(LucideIcons.trash2, size: 16),
                  label: const Text('Delete'),
                ),
                TextButton.icon(
                  onPressed: widget.onEdit,
                  icon: const Icon(LucideIcons.pencil, size: 16),
                  label: const Text('Edit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.value,
    required this.onSurface,
    this.trailing,
  });

  final String label;
  final String value;
  final Color onSurface;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 2),
              SelectableText(
                value,
                style: TextStyle(fontSize: 14, color: onSurface),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}
