import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/text_styles.dart';
import '../../core/utils/known_categories.dart';
import '../../models/note_model.dart';
import '../../providers/note_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/tag_input_field.dart';

typedef _NoteSnapshot = ({String title, String body, String tag});

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

  // Session-only undo/redo — never persisted, discarded the moment this
  // screen is popped (the stacks are just fields on this State, which dies
  // with it). See _captureHistoryOnChange for the coalescing strategy.
  final List<_NoteSnapshot> _undoStack = [];
  final List<_NoteSnapshot> _redoStack = [];
  late _NoteSnapshot _baseline;
  bool _burstActive = false;
  bool _isApplyingHistory = false;
  Timer? _burstTimer;
  static const _historyCoalesceWindow = Duration(milliseconds: 800);

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
    _baseline = _currentSnapshot();
    _titleController.addListener(_captureHistoryOnChange);
    _bodyController.addListener(_captureHistoryOnChange);
    _tagController.addListener(_captureHistoryOnChange);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _burstTimer?.cancel();
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

  _NoteSnapshot _currentSnapshot() => (
    title: _titleController.text,
    body: _bodyController.text,
    tag: _tagController.text,
  );

  /// Coalesces a burst of typing into one undo entry, rather than one per
  /// keystroke: the pre-burst state is pushed the moment a burst starts, and
  /// the burst "closes" (settling a new baseline) after a pause with no
  /// further edits — same cadence as autosave, on its own independent timer.
  void _captureHistoryOnChange() {
    if (_isApplyingHistory) return;
    final current = _currentSnapshot();
    // A selection/cursor move alone still notifies listeners; only a real
    // content change should count as the start of a burst.
    if (current == _baseline) return;
    if (!_burstActive) {
      _undoStack.add(_baseline);
      _redoStack.clear();
      _burstActive = true;
      setState(() {});
    }
    _burstTimer?.cancel();
    _burstTimer = Timer(_historyCoalesceWindow, _closeBurst);
  }

  void _closeBurst() {
    _burstActive = false;
    _baseline = _currentSnapshot();
  }

  void _applySnapshot(_NoteSnapshot snap) {
    _isApplyingHistory = true;
    _titleController.value = TextEditingValue(
      text: snap.title,
      selection: TextSelection.collapsed(offset: snap.title.length),
    );
    _bodyController.value = TextEditingValue(
      text: snap.body,
      selection: TextSelection.collapsed(offset: snap.body.length),
    );
    _tagController.value = TextEditingValue(
      text: snap.tag,
      selection: TextSelection.collapsed(offset: snap.tag.length),
    );
    _isApplyingHistory = false;
    _baseline = snap;
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    _burstTimer?.cancel();
    _burstActive = false;
    final current = _currentSnapshot();
    final previous = _undoStack.removeLast();
    _redoStack.add(current);
    _applySnapshot(previous);
    setState(() {});
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    final current = _currentSnapshot();
    final next = _redoStack.removeLast();
    _undoStack.add(current);
    _applySnapshot(next);
    setState(() {});
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
      bottomBar: _UndoRedoBar(
        canUndo: _undoStack.isNotEmpty,
        canRedo: _redoStack.isNotEmpty,
        onUndo: _undo,
        onRedo: _redo,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              style: TextStyles.heading(size: 20, color: onSurface),
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration.collapsed(hintText: 'Title').copyWith(
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
              ),
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
              decoration: InputDecoration.collapsed(
                hintText: 'Write something…',
              ).copyWith(
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UndoRedoBar extends StatelessWidget {
  const _UndoRedoBar({
    required this.canUndo,
    required this.canRedo,
    required this.onUndo,
    required this.onRedo,
  });

  final bool canUndo;
  final bool canRedo;
  final VoidCallback onUndo;
  final VoidCallback onRedo;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(LucideIcons.undo2),
              tooltip: 'Undo',
              onPressed: canUndo ? onUndo : null,
            ),
            IconButton(
              icon: const Icon(LucideIcons.redo2),
              tooltip: 'Redo',
              onPressed: canRedo ? onRedo : null,
            ),
          ],
        ),
      ),
    );
  }
}
