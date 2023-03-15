import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../util/model.dart';
import '../../util/parse_helper.dart';
import '../../util/supabase_manager.dart';
import 'profile_feature.dart';
import 'report.dart';
import 'review.dart';

class Profile extends Model {
  static const int maxUsernameLength = 15;

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

  /// Returns the full name of the user.
  ///
  /// The full name is composed of the surname and the name, separated by a space.
  /// - If the user has no surname, only the name is returned.
  /// - If the user has no name, only the surname is returned.
  /// - If the user has no name and no surname, an empty string is returned.
  String get fullName {
    if (name != null && surname != null) return '$surname $name';
    if (name != null) return name!;
    if (surname != null) return surname!;
    return '';
  }

  bool get isCurrentUser => id == supabaseManager.currentProfile?.id;

  /// Returns true if the user hasn't filled any personal information.
  ///
  /// If any of the following fields is given, this is false:
  /// - description
  /// - birth date
  /// - surname
  /// - name
  /// - gender
  /// - avatar
  ///
  /// Features are not considered personal information.
  bool get hasNoPersonalInformation =>
      description == null &&
      birthDate == null &&
      surname == null &&
      name == null &&
      gender == null &&
      avatarUrl == null;

  /// The maximum permitted age of a user (120 years)
  static const Duration maxAge = Duration(days: 365 * 120);

  /// The minimum permitted age of a user (12 years)
  static const Duration minAge = Duration(days: 365 * 12);

  /// Returns the corresponding [Feature]s of the [ProfileFeature]s of this [Profile].
  List<Feature>? get features =>
      profileFeatures?.map((ProfileFeature profileFeature) => profileFeature.feature).toList();

  @override
  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      username: json['username'] as String,
      email: json['email'] as String,
      description: json['description'] as String?,
      birthDate: json['birth_date'] != null ? DateTime.parse(json['birth_date'] as String) : null,
      surname: json['surname'] as String?,
      name: json['name'] as String?,
      gender: json['gender'] != null ? Gender.values[json['gender'] as int] : null,
      avatarUrl: json['avatar_url'] as String?,
      reviewsReceived: json.containsKey('reviews_received')
          ? Review.fromJsonList(parseHelper.parseListOfMaps(json['reviews_received']))
          : null,
      profileFeatures: json.containsKey('profile_features')
          ? ProfileFeature.fromJsonList(parseHelper.parseListOfMaps(json['profile_features']))
          : null,
      reportsReceived: json.containsKey('reports_received')
          ? Report.fromJsonList(parseHelper.parseListOfMaps(json['reports_received']))
          : null,
    );
  }

  static List<Profile> fromJsonList(List<Map<String, dynamic>> jsonList) {
    return jsonList.map((Map<String, dynamic> json) => Profile.fromJson(json)).toList();
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
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

  int? get age {
    if (birthDate == null) return null;

    final DateTime today = DateTime.now();

    final int yearsDifference = today.year - birthDate!.year;

    if (today.month > birthDate!.month || (today.month == birthDate!.month && today.day >= birthDate!.day)) {
      return yearsDifference;
    } else {
      return yearsDifference - 1;
    }
  }

  @override
  Map<String, dynamic> toJsonForApi() {
    return super.toJsonForApi()
      ..addAll(<String, dynamic>{
        'reviews_received':
            reviewsReceived?.map((Review review) => review.toJsonForApi()).toList() ?? <Map<String, dynamic>>[],
        'profile_features':
            profileFeatures?.map((ProfileFeature profileFeature) => profileFeature.toJsonForApi()).toList() ??
                <Map<String, dynamic>>[],
        'reports_received':
            reportsReceived?.map((Report report) => report.toJsonForApi()).toList() ?? <Map<String, dynamic>>[],
      });
  }

  @override
  String toString() {
    return 'Profile{id: $id, username: $username, email: $email, createdAt: $createdAt}';
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
