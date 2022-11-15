class AppUser {
  AppUser({
    required this.id,
    //todo: change back to username when users table is updated
    required this.name,
    required this.createdAt,
  });

  /// User ID of the profile
  final int id;

  /// Username of the profile
  final String name;

  /// Date and time when the profile was created
  final DateTime createdAt;

  AppUser.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        name = map['name'],
        createdAt = DateTime.parse(map['created_at']);
}
