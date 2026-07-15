class TripItem {
  const TripItem({required this.id, required this.title, this.done = false});

  final String id;
  final String title;
  final bool done;

  TripItem copyWith({String? id, String? title, bool? done}) => TripItem(
    id: id ?? this.id,
    title: title ?? this.title,
    done: done ?? this.done,
  );
}

class TripModel {
  const TripModel({
    required this.id,
    required this.name,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.inviteCode,
    required this.createdBy,
    this.members = const [],
    this.items = const [],
  });

  final String id;
  final String name;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final String inviteCode;
  final String createdBy;
  final List<String> members;
  final List<TripItem> items;

  TripModel copyWith({
    String? id,
    String? name,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    String? inviteCode,
    String? createdBy,
    List<String>? members,
    List<TripItem>? items,
  }) => TripModel(
    id: id ?? this.id,
    name: name ?? this.name,
    destination: destination ?? this.destination,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    inviteCode: inviteCode ?? this.inviteCode,
    createdBy: createdBy ?? this.createdBy,
    members: members ?? this.members,
    items: items ?? this.items,
  );

  String get dateRange {
    final s = '${startDate.day}/${startDate.month}/${startDate.year}';
    final e = '${endDate.day}/${endDate.month}/${endDate.year}';
    return '$s – $e';
  }

  int get daysLeft {
    final now = DateTime.now();
    return startDate.difference(DateTime(now.year, now.month, now.day)).inDays;
  }
}
