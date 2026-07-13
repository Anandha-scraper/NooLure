import '../core/utils/date_labels.dart';

class NoteChecklistItem {
  const NoteChecklistItem({
    required this.id,
    required this.title,
    this.done = false,
  });

  /// Checklist items used to be identified by their index in the list, which
  /// silently corrupts as soon as two devices reorder or delete concurrently.
  final String id;
  final String title;
  final bool done;

  NoteChecklistItem copyWith({String? title, bool? done}) => NoteChecklistItem(
    id: id,
    title: title ?? this.title,
    done: done ?? this.done,
  );

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'done': done};

  factory NoteChecklistItem.fromJson(Map<String, dynamic> json) =>
      NoteChecklistItem(
        id: json['id'] as String,
        title: (json['title'] as String?) ?? '',
        done: (json['done'] as bool?) ?? false,
      );
}

class NoteModel {
  const NoteModel({
    required this.id,
    required this.title,
    required this.body,
    required this.tag,
    required this.createdAt,
    required this.updatedAt,
    this.isImage = false,
    this.isPinned = false,
    this.checklist = const [],
  });

  final String id;
  final String title;
  final String body;
  final String tag;
  final bool isImage;
  final bool isPinned;
  final List<NoteChecklistItem> checklist;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// 'just now' / '2h ago' / 'Mar 3' — derived, never stored.
  String get editedLabel => DateLabels.relativeLabel(updatedAt);

  NoteModel copyWith({
    String? title,
    String? body,
    String? tag,
    bool? isImage,
    bool? isPinned,
    List<NoteChecklistItem>? checklist,
    DateTime? updatedAt,
  }) => NoteModel(
    id: id,
    title: title ?? this.title,
    body: body ?? this.body,
    tag: tag ?? this.tag,
    isImage: isImage ?? this.isImage,
    isPinned: isPinned ?? this.isPinned,
    checklist: checklist ?? this.checklist,
    createdAt: createdAt,
    updatedAt: updatedAt ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'tag': tag,
    'isImage': isImage,
    'isPinned': isPinned,
    'checklist': checklist.map((c) => c.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    final created = _parseDate(json['createdAt']) ?? DateTime.now();
    return NoteModel(
      id: json['id'] as String,
      title: (json['title'] as String?) ?? '',
      body: (json['body'] as String?) ?? '',
      tag: (json['tag'] as String?) ?? 'Note',
      isImage: (json['isImage'] as bool?) ?? false,
      isPinned: (json['isPinned'] as bool?) ?? false,
      checklist: [
        for (final c in (json['checklist'] as List<dynamic>? ?? []))
          NoteChecklistItem.fromJson(Map<String, dynamic>.from(c as Map)),
      ],
      createdAt: created,
      updatedAt: _parseDate(json['updatedAt']) ?? created,
    );
  }
}

DateTime? _parseDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
