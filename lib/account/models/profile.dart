import 'package:flutter/material.dart';
import 'package:motis_mitfahr_app/account/models/report.dart';
import 'package:motis_mitfahr_app/account/models/review.dart';
import 'package:motis_mitfahr_app/account/models/profile_feature.dart';
import 'package:motis_mitfahr_app/util/supabase.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../util/model.dart';

class Profile extends Model {
  final String username;
  final String email;

  final String? description;
  final DateTime? birthDate;
  final String? surname;
  final String? name;
  final Gender? gender;

  final String? avatarUrl;

  List<Review>? reviewsReceived;
  List<ProfileFeature>? profileFeatures;
  List<Report>? reportsReceived;

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
    this.avatarUrl,
    this.reviewsReceived,
    this.profileFeatures,
    this.reportsReceived,
  });

  get fullName {
    if (name != null && surname != null) return '$surname $name';
    if (name != null) return name!;
    if (surname != null) return surname!;
    return '';
  }

  get isCurrentUser => id == SupabaseManager.getCurrentProfile()?.id;

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
      avatarUrl: json['avatar_url'],
      reviewsReceived: json.containsKey('reviews_received')
          ? Review.fromJsonList(json['reviews_received'].cast<Map<String, dynamic>>())
          : null,
      profileFeatures: json.containsKey('profile_features')
          ? ProfileFeature.fromJsonList(json['profile_features'].cast<Map<String, dynamic>>())
          : null,
      reportsReceived: json.containsKey('reports_received')
          ? Report.fromJsonList(json['reports_received'].cast<Map<String, dynamic>>())
          : null,
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
      'avatar_url': avatarUrl,
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

  AggregateReview getAggregateReview() {
    List<Review> reviews = reviewsReceived ?? [];
    return AggregateReview.fromReviews(reviews);
  }
}

enum Gender {
  male,
  female,
  diverse,
}

extension GenderName on Gender {
  String getName(BuildContext context) {
    switch (this) {
      case Gender.male:
        return S.of(context).modelProfileGenderMale;
      case Gender.female:
        return S.of(context).modelProfileGenderFemale;
      case Gender.diverse:
        return S.of(context).modelProfileGenderDiverse;
    }
  }
}
