class TripMember {
  const TripMember({required this.uid, required this.name, required this.joinedAt});

  final String uid;

  /// Display-name snapshot at join time.
  final String name;
  final DateTime joinedAt;

  Map<String, dynamic> toJson() => {
    'name': name,
    'joinedAt': joinedAt.toIso8601String(),
  };

  factory TripMember.fromJson(String uid, Map<String, dynamic> json) => TripMember(
    uid: uid,
    name: (json['name'] as String?) ?? '',
    joinedAt: _parseDate(json['joinedAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
  );
}

class TripItem {
  const TripItem({
    required this.id,
    required this.title,
    this.responses = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;

  /// uid -> when that member responded (checked themselves off this item).
  final Map<String, DateTime> responses;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get responseCount => responses.length;

  bool respondedBy(String uid) => responses.containsKey(uid);

  bool isComplete(int memberCount) =>
      memberCount > 0 && responses.length >= memberCount;

  TripItem copyWith({
    String? title,
    Map<String, DateTime>? responses,
    DateTime? updatedAt,
  }) => TripItem(
    id: id,
    title: title ?? this.title,
    responses: responses ?? this.responses,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'responses': {
      for (final e in responses.entries) e.key: e.value.toIso8601String(),
    },
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory TripItem.fromJson(String id, Map<String, dynamic> json) {
    final responsesRaw = json['responses'] as Map? ?? {};
    return TripItem(
      id: id,
      title: (json['title'] as String?) ?? '',
      responses: {
        for (final e in responsesRaw.entries)
          e.key.toString(): _parseDate(e.value) ?? DateTime.fromMillisecondsSinceEpoch(0),
      },
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']) ?? DateTime.now(),
    );
  }
}

class TripModel {
  const TripModel({
    required this.id,
    required this.name,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.inviteCode,
    required this.createdByUid,
    required this.createdByName,
    this.members = const {},
    this.items = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final String inviteCode;

  /// The single admin for this trip, identified by Firebase Auth uid.
  final String createdByUid;
  final String createdByName;
  final Map<String, TripMember> members;
  final Map<String, TripItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool isAdmin(String? uid) => uid != null && uid == createdByUid;

  List<TripMember> get memberList =>
      members.values.toList()..sort((a, b) => a.joinedAt.compareTo(b.joinedAt));

  List<TripItem> get itemList =>
      items.values.toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  String get dateRange {
    final s = '${startDate.day}/${startDate.month}/${startDate.year}';
    final e = '${endDate.day}/${endDate.month}/${endDate.year}';
    return '$s – $e';
  }

  int get daysLeft {
    final now = DateTime.now();
    return startDate.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  TripModel copyWith({
    String? name,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    String? inviteCode,
    String? createdByUid,
    String? createdByName,
    Map<String, TripMember>? members,
    Map<String, TripItem>? items,
    DateTime? updatedAt,
  }) => TripModel(
    id: id,
    name: name ?? this.name,
    destination: destination ?? this.destination,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    inviteCode: inviteCode ?? this.inviteCode,
    createdByUid: createdByUid ?? this.createdByUid,
    createdByName: createdByName ?? this.createdByName,
    members: members ?? this.members,
    items: items ?? this.items,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'destination': destination,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'inviteCode': inviteCode,
    'createdByUid': createdByUid,
    'createdByName': createdByName,
    'members': {for (final e in members.entries) e.key: e.value.toJson()},
    'items': {for (final e in items.entries) e.key: e.value.toJson()},
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  /// [id] is threaded in from the RTDB snapshot key rather than duplicated
  /// inside the JSON blob — trips are addressed structurally by path, not by
  /// a redundant id field the way tasks/notes/birthdays store theirs.
  factory TripModel.fromJson(String id, Map<String, dynamic> json) {
    final membersRaw = json['members'] as Map? ?? {};
    final itemsRaw = json['items'] as Map? ?? {};
    return TripModel(
      id: id,
      name: (json['name'] as String?) ?? '',
      destination: (json['destination'] as String?) ?? '',
      startDate: _parseDate(json['startDate']) ?? DateTime.now(),
      endDate: _parseDate(json['endDate']) ?? DateTime.now(),
      inviteCode: (json['inviteCode'] as String?) ?? '',
      createdByUid: (json['createdByUid'] as String?) ?? '',
      createdByName: (json['createdByName'] as String?) ?? '',
      members: {
        for (final e in membersRaw.entries)
          e.key.toString(): TripMember.fromJson(
            e.key.toString(),
            Map<String, dynamic>.from(e.value as Map),
          ),
      },
      items: {
        for (final e in itemsRaw.entries)
          e.key.toString(): TripItem.fromJson(
            e.key.toString(),
            Map<String, dynamic>.from(e.value as Map),
          ),
      },
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']) ?? DateTime.now(),
    );
  }
}

DateTime? _parseDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
