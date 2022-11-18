import 'model.dart';

class Profile extends Model {
  final String name;

  Profile({
    required super.id,
    required this.name,
    super.createdAt,
  });

  @override
  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      name: json['name'],
      createdAt: json['created_at'],
    );
  }

  static List<Profile> fromJsonList(List<Map<String, dynamic>> jsonList) {
    return jsonList.map((json) => Profile.fromJson(json)).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt,
    };
  }

  List<Map<String, dynamic>> toJsonList(List<Profile> Profiles) {
    return Profiles.map((Profile) => Profile.toJson()).toList();
  }

  @override
  String toString() {
    return 'Profile{id: $id, name: $name, createdAt: $createdAt}';
  }
}
