import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/text_styles.dart';
import '../../models/password_model.dart';
import '../../providers/password_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/tag_input_field.dart';

const _tagSuggestions = ['Social', 'Work', 'Email', 'General'];

/// Add/edit a password entry. An `entryId` puts it in edit mode; the caller
/// (the Passwords screen) must already hold the decrypted [PasswordEntryData]
/// for that id, since this screen has no way to decrypt on its own — it only
/// ever sees plaintext handed to it directly.
///
/// Autosaves as you type (same pattern as the note editor,
/// `lib/screens/notes/add_note_screen.dart`) instead of a Save button — a
/// stable entry id is picked up front (existing id when editing, a fresh one
/// when creating) so the same debounced save path upserts either way;
/// nothing is written until Category has actual content, so opening and
/// immediately backing out never creates a junk empty entry.
class AddPasswordScreen extends StatefulWidget {
  const AddPasswordScreen({super.key, this.entryId, this.existing, this.existingTag});

  final String? entryId;
  final PasswordEntryData? existing;
  final String? existingTag;

  @override
  State<AddPasswordScreen> createState() => _AddPasswordScreenState();
}

class _AddPasswordScreenState extends State<AddPasswordScreen> {
  late final String _entryId;
  late final _tagController = TextEditingController(
    text: widget.existingTag ?? '',
  );
  late final _usernameController = TextEditingController(
    text: widget.existing?.username ?? '',
  );
  late final _passwordController = TextEditingController(
    text: widget.existing?.password ?? '',
  );
  late final _urlController = TextEditingController(
    text: widget.existing?.url ?? '',
  );

  Timer? _debounce;
  bool _dirty = false;
  bool _saving = false;
  bool _hasSavedOnce = false;
  bool _obscure = true;

  bool get _isEditing => widget.entryId != null;

  @override
  void initState() {
    super.initState();
    _entryId = widget.entryId ?? const Uuid().v4();
    _tagController.addListener(_scheduleAutosave);
    _usernameController.addListener(_scheduleAutosave);
    _passwordController.addListener(_scheduleAutosave);
    _urlController.addListener(_scheduleAutosave);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    // Flush anything typed in the last debounce window so nothing's lost —
    // no setState here, the widget is already on its way out.
    if (_dirty) {
      final data = _buildData();
      if (data != null) {
        context.read<PasswordProvider>().updateEntry(
          _entryId,
          data,
          tag: _tagController.text.trim(),
        );
      }
    }
    _tagController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _scheduleAutosave() {
    _dirty = true;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), _save);
  }

  /// Builds the entry to persist, or `null` while there's nothing worth
  /// saving yet — Category is required, matching the field that used to gate
  /// the (now-removed) Save button.
  PasswordEntryData? _buildData() {
    if (_tagController.text.trim().isEmpty) return null;
    return PasswordEntryData(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      url: _urlController.text.trim(),
    );
  }

  Future<void> _save() async {
    final data = _buildData();
    if (data == null) return;
    if (mounted) setState(() => _saving = true);
    await context.read<PasswordProvider>().updateEntry(
      _entryId,
      data,
      tag: _tagController.text.trim(),
    );
    _dirty = false;
    if (!mounted) return;
    setState(() {
      _saving = false;
      _hasSavedOnce = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return AppScaffold(
      title: _isEditing ? 'Edit password' : 'New password',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: Text(
              _saving
                  ? 'Saving…'
                  : _hasSavedOnce
                  ? 'Saved'
                  : '',
              style: TextStyle(
                fontSize: 12,
                color: onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text('Category', style: TextStyles.sectionLabel(color: onSurface)),
          const SizedBox(height: 8),
          TagInputField(
            controller: _tagController,
            suggestions: _tagSuggestions,
            hintText: 'e.g. Netflix',
          ),
          const SizedBox(height: 18),
          Text('Username', style: TextStyles.sectionLabel(color: onSurface)),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _usernameController,
            hintText: 'e.g. you@example.com',
          ),
          const SizedBox(height: 18),
          Text('Password', style: TextStyles.sectionLabel(color: onSurface)),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _passwordController,
            hintText: 'Password',
            obscureText: _obscure,
            suffixIcon: IconButton(
              icon: Icon(
                _obscure ? LucideIcons.eye : LucideIcons.eyeOff,
                size: 18,
              ),
              tooltip: _obscure ? 'Show' : 'Hide',
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          const SizedBox(height: 18),
          Text('URL', style: TextStyles.sectionLabel(color: onSurface)),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _urlController,
            hintText: 'https:// (optional)',
          ),
        ],
      ),
    );
  }
}
