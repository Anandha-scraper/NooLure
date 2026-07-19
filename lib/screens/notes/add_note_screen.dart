import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/text_styles.dart';
import '../../core/utils/known_categories.dart';
import '../../models/note_model.dart';
import '../../providers/note_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/tag_input_field.dart';

/// Add/edit note screen — a `noteId` puts it in edit mode, pre-filling and
/// saving over the existing note (including a pinned one, whose sticky-note
/// preview never shows the body — this screen is where the full body is
/// visible and editable).
///
/// Autosaves as you type (Google-Keep-style) instead of requiring an
/// explicit Save tap — a stable note id is picked up front (existing id when
/// editing, a fresh one when creating) so the same debounced save path
/// upserts either way; nothing is written until there's actual content, so
/// opening and immediately backing out never creates a junk empty note.
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
  late final String _noteId;
  late final DateTime _createdAt;
  NoteModel? _existing;

  Timer? _debounce;
  bool _dirty = false;
  bool _saving = false;
  bool _hasSavedOnce = false;

  @override
  void initState() {
    super.initState();
    _existing = widget.noteId == null
        ? null
        : context.read<NoteProvider>().byId(widget.noteId!);
    _noteId = widget.noteId ?? const Uuid().v4();
    _createdAt = _existing?.createdAt ?? DateTime.now();
    _titleController = TextEditingController(text: _existing?.title ?? '');
    _bodyController = TextEditingController(text: _existing?.body ?? '');
    _tagController = TextEditingController(text: _existing?.tag ?? 'Ideas');
    _titleController.addListener(_scheduleAutosave);
    _bodyController.addListener(_scheduleAutosave);
    _tagController.addListener(_scheduleAutosave);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    // Flush anything typed in the last debounce window so nothing's lost —
    // no setState here, the widget is already on its way out.
    if (_dirty) {
      final note = _buildNote();
      if (note != null) context.read<NoteProvider>().updateNote(note);
    }
    _titleController.dispose();
    _bodyController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.noteId != null;

  void _scheduleAutosave() {
    _dirty = true;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), _save);
  }

  /// Builds the note to persist, or `null` while there's nothing worth
  /// saving yet (both title and body still empty).
  NoteModel? _buildNote() {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty && body.isEmpty) return null;
    final tag = _tagController.text.trim().isEmpty
        ? 'Ideas'
        : _tagController.text.trim();
    return NoteModel(
      id: _noteId,
      title: title,
      body: body,
      tag: tag,
      isImage: _existing?.isImage ?? false,
      isPinned: _existing?.isPinned ?? false,
      checklist: _existing?.checklist ?? const [],
      createdAt: _createdAt,
      updatedAt: DateTime.now(),
      deletedAt: _existing?.deletedAt,
      archivedAt: _existing?.archivedAt,
    );
  }

  Future<void> _save() async {
    final note = _buildNote();
    if (note == null) return;
    if (mounted) setState(() => _saving = true);
    await context.read<NoteProvider>().updateNote(note);
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
      title: _isEditing ? 'Edit note' : 'New note',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              style: TextStyles.heading(size: 20, color: onSurface),
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration.collapsed(hintText: 'Title'),
            ),
            const SizedBox(height: 10),
            TagInputField(
              controller: _tagController,
              suggestions: knownCategories(context),
              hintText: 'Tag',
              borderless: true,
            ),
            const SizedBox(height: 16),
            Divider(
              height: 1,
              color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bodyController,
              maxLines: null,
              minLines: 6,
              textAlignVertical: TextAlignVertical.top,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: onSurface.withValues(alpha: 0.85),
              ),
              decoration: const InputDecoration.collapsed(
                hintText: 'Write something…',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
