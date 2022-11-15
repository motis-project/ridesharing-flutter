import 'model.dart';

class User extends Model {
  final String name;

  User({
    required super.id,
    required this.name,
    super.createdAt,
  });

  @override
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      createdAt: json['created_at'],
    );
  }

  static List<User> fromJsonList(List<Map<String, dynamic>> jsonList) {
    return jsonList.map((json) => User.fromJson(json)).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt,
    };
  }
}
