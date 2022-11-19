import 'model.dart';

class Profile extends Model {
  final String username;
  final String email;

  Profile({
    required super.id,
    required this.username,
    required this.email,
    super.createdAt,
  });

  @override
  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      createdAt: json['created_at'],
    );
  }

  static List<Profile> fromJsonList(List<Map<String, dynamic>> jsonList) {
    return jsonList.map((json) => Profile.fromJson(json)).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'created_at': createdAt,
    };
  }

  List<Map<String, dynamic>> toJsonList(List<Profile> profiles) {
    return profiles.map((profile) => profile.toJson()).toList();
  }

  @override
  String toString() {
    return 'Profile{id: $id, username: $username, email: $email, createdAt: $createdAt}';
  }
}
