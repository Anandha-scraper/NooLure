import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/data/repositories.dart';
import '../core/data/repository.dart';
import '../models/note_model.dart';

class NoteProvider extends ChangeNotifier {
  NoteProvider({Repository<NoteModel>? repository})
    : _repository = repository ?? Repositories.notes {
    _subscription = _repository.watch().listen((notes) {
      _notes = notes..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      notifyListeners();
    });
  }

  final Repository<NoteModel> _repository;
  static const _uuid = Uuid();

  StreamSubscription<List<NoteModel>>? _subscription;
  List<NoteModel> _notes = [];

  List<NoteModel> get notes => List.unmodifiable(_notes);

  NoteModel? get pinnedNote {
    for (final n in _notes) {
      if (n.isPinned) return n;
    }
    return null;
  }

  List<NoteModel> get gridNotes => _notes.where((n) => !n.isPinned).toList();

  List<String> get availableTags {
    final tags = _notes.map((n) => n.tag).toSet().toList()..sort();
    return ['All', ...tags];
  }

  List<NoteModel> filteredGridNotes(String tag) {
    if (tag == 'All') return gridNotes;
    return gridNotes.where((n) => n.tag == tag).toList();
  }

  NoteModel? byId(String id) {
    for (final n in _notes) {
      if (n.id == id) return n;
    }
    return null;
  }

  Future<void> toggleChecklistItem(String noteId, String itemId) async {
    final note = byId(noteId);
    if (note == null) return;
    await _repository.save(
      note.copyWith(
        checklist: [
          for (final c in note.checklist)
            c.id == itemId ? c.copyWith(done: !c.done) : c,
        ],
      ),
    );
  }

  Future<void> togglePinned(String id) async {
    final note = byId(id);
    if (note == null) return;
    await _repository.save(note.copyWith(isPinned: !note.isPinned));
  }

  Future<void> addNote({
    required String title,
    required String body,
    required String tag,
  }) async {
    final now = DateTime.now();
    await _repository.save(
      NoteModel(
        id: _uuid.v4(),
        title: title,
        body: body,
        tag: tag,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> updateNote(NoteModel note) => _repository.save(note);

  Future<void> deleteNote(String id) => _repository.delete(id);

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
