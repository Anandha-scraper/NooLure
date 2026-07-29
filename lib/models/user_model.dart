class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.initials,
  });

  final String id;
  final String name;
  final String email;
  final String initials;

  UserModel copyWith({String? name}) => UserModel(
    id: id,
    name: name ?? this.name,
    email: email,
    initials: initials,
  );
}
