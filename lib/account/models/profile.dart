import 'package:flutter_app/util/supabase.dart';

import '../../util/model.dart';

class Profile extends Model {
  final String username;
  final String email;

  final String? description;
  final DateTime? birthDate;
  final String? surname;
  final String? name;
  final Gender? gender;

  Profile({
    super.id,
    super.createdAt,
    required this.username,
    required this.email,
    this.description,
    this.birthDate,
    this.surname,
    this.name,
    this.gender,
  });

  @override
  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      username: json['username'],
      email: json['email'],
      description: json['description'],
      birthDate: json['birth_date'] != null ? DateTime.parse(json['birth_date']) : null,
      surname: json['surname'],
      name: json['name'],
      gender: json['gender'] != null ? Gender.values[json['gender']] : null,
    );
  }

  static List<Profile> fromJsonList(List<Map<String, dynamic>> jsonList) {
    return jsonList.map((json) => Profile.fromJson(json)).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'description': description,
      'birth_date': birthDate?.toString(),
      'surname': surname,
      'name': name,
      'gender': gender?.index,
    };
  }

  List<Map<String, dynamic>> toJsonList(List<Profile> profiles) {
    return profiles.map((profile) => profile.toJson()).toList();
  }

  @override
  String toString() {
    return 'Profile{id: $id, username: $username, email: $email, createdAt: $createdAt}';
  }

  static Future<Profile?> getProfileFromAuthId(String authId) async {
    Map<String, dynamic>? query = await supabaseClient.from('profiles').select().eq('auth_id', authId).maybeSingle();
    if (query == null) {
      return null;
    }

    return Profile.fromJson(query);
  }
}

enum Gender {
  male,
  female,
  diverse,
}
