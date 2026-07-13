import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/text_styles.dart';
import '../../core/utils/known_categories.dart';
import '../../providers/note_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/tag_input_field.dart';

/// Add/edit note screen — a `noteId` puts it in edit mode, pre-filling and
/// saving over the existing note (including a pinned one, whose sticky-note
/// preview never shows the body — this screen is where the full body is
/// visible and editable).
class AddNoteScreen extends StatefulWidget {
  const AddNoteScreen({super.key, this.noteId});

  final String? noteId;

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  late final TextEditingController _tagController;

  @override
  void initState() {
    super.initState();
    final existing = widget.noteId == null
        ? null
        : context.read<NoteProvider>().byId(widget.noteId!);
    _titleController = TextEditingController(text: existing?.title ?? '');
    _bodyController = TextEditingController(text: existing?.body ?? '');
    _tagController = TextEditingController(text: existing?.tag ?? 'Ideas');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.noteId != null;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return AppScaffold(
      title: _isEditing ? 'Edit note' : 'New note',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text('Title', style: TextStyles.sectionLabel(color: onSurface)),
          const SizedBox(height: 8),
          CustomTextField(controller: _titleController, hintText: 'Note title'),
          const SizedBox(height: 18),
          Text('Tag', style: TextStyles.sectionLabel(color: onSurface)),
          const SizedBox(height: 8),
          TagInputField(
            controller: _tagController,
            suggestions: knownCategories(context),
            hintText: 'Tag',
          ),
          const SizedBox(height: 18),
          Text('Body', style: TextStyles.sectionLabel(color: onSurface)),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _bodyController,
            hintText: 'Write something…',
            maxLines: 8,
            borderRadius: BorderRadius.circular(22),
          ),
          const SizedBox(height: 30),
          ListenableBuilder(
            listenable: _titleController,
            builder: (context, _) => PrimaryButton(
              label: _isEditing ? 'Save changes' : 'Add note',
              onPressed: _titleController.text.trim().isEmpty ? null : _submit,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final navigator = Navigator.of(context);
    final provider = context.read<NoteProvider>();
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    final tag = _tagController.text.trim().isEmpty
        ? 'Ideas'
        : _tagController.text.trim();

    if (_isEditing) {
      final existing = provider.byId(widget.noteId!);
      if (existing != null) {
        await provider.updateNote(
          existing.copyWith(title: title, body: body, tag: tag),
        );
      }
    } else {
      await provider.addNote(title: title, body: body, tag: tag);
    }
    navigator.pop();
  }
}
