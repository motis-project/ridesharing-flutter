import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/managers/supabase_manager.dart';

import '../../test_util/factories/model_factory.dart';
import '../../test_util/factories/profile_factory.dart';
import '../../test_util/factories/profile_feature_factory.dart';
import '../../test_util/factories/report_factory.dart';
import '../../test_util/factories/review_factory.dart';

void main() {
  group('fullname', () {
    test('returns empty if neither first not last name are set', () async {
      final Profile profile = ProfileFactory().generateFake(
        firstName: NullableParameter(null),
        lastName: NullableParameter(null),
      );
      expect(profile.fullName, '');
    });

    test('returns first name if last name is not set', () async {
      final profile = ProfileFactory().generateFake(
        lastName: NullableParameter(null),
      );
      expect(profile.fullName, profile.firstName);
    });

    test('returns last name if first name is not set', () async {
      final profile = ProfileFactory().generateFake(
        firstName: NullableParameter(null),
      );
      expect(profile.fullName, profile.lastName);
    });

    test('returns first and last name if both are set', () async {
      final profile = ProfileFactory().generateFake(
        firstName: NullableParameter('first_name'),
        lastName: NullableParameter('last_name'),
      );
      expect(profile.fullName, 'first_name last_name');
    });
  });

  group('isCurrentUser', () {
    test('returns true if id is equal to current profile id', () async {
      final profile = ProfileFactory().generateFake();
      final currentProfile = ProfileFactory().generateFake(
        id: profile.id,
      );
      supabaseManager.currentProfile = currentProfile;
      expect(profile.isCurrentUser, true);
    });

    test('returns false if id is not equal to current profile id', () async {
      final profile = ProfileFactory().generateFake();
      final currentProfile = ProfileFactory().generateFake(id: profile.id! + 1);
      supabaseManager.currentProfile = currentProfile;
      expect(profile.isCurrentUser, false);
    });
  });

  group('hasNoPersonalInformation', () {
    test('returns true if user has no personal information', () async {
      final profile = ProfileFactory().generateFake(
        description: NullableParameter(null),
        birthDate: NullableParameter(null),
        firstName: NullableParameter(null),
        lastName: NullableParameter(null),
        gender: NullableParameter(null),
        avatarUrl: NullableParameter(null),
      );
      expect(profile.hasNoPersonalInformation, true);
    });

    test('returns false if one piece of personal information is not null', () async {
      final profile = ProfileFactory().generateFake(
        description: NullableParameter(null),
        birthDate: NullableParameter(null),
        firstName: NullableParameter(null),
        lastName: NullableParameter(null),
        gender: NullableParameter(null),
        avatarUrl: NullableParameter('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
      );
      expect(profile.hasNoPersonalInformation, false);
    });
  });

  group('Profile.fromJson', () {
    test('parses a profile from json', () async {
      final Map<String, dynamic> json = {
        'id': 1,
        'created_at': '2021-01-01T00:00:00.000',
        'username': 'username',
        'email': 'email',
        'description': 'description',
        'birth_date': '2021-01-01T00:00:00.000',
        'first_name': 'first_name',
        'last_name': 'last_name',
        'gender': 0,
        'avatar_url': 'avatar_url',
      };
      final Profile profile = Profile.fromJson(json);
      expect(profile.id, json['id']);
      expect(profile.createdAt, DateTime.parse(json['created_at']));
      expect(profile.username, json['username']);
      expect(profile.email, json['email']);
      expect(profile.description, json['description']);
      expect(profile.birthDate, DateTime.parse(json['birth_date']));
      expect(profile.firstName, json['first_name']);
      expect(profile.lastName, json['last_name']);
      expect(profile.gender, Gender.male);
      expect(profile.avatarUrl, json['avatar_url']);
    });

    test('can handle associated models', () async {
      final Map<String, dynamic> json = {
        'id': 1,
        'created_at': '2021-01-01T00:00:00.000',
        'username': 'username',
        'email': 'email',
        'reviews_received': ReviewFactory().generateFakeJsonList(length: 3),
        'profile_features': ProfileFeatureFactory().generateFakeJsonList(length: 3),
        'reports_received': ReportFactory().generateFakeJsonList(length: 3),
      };
      final Profile profile = Profile.fromJson(json);
      expect(profile.reviewsReceived!.length, 3);
      expect(profile.profileFeatures!.length, 3);
      expect(profile.reportsReceived!.length, 3);
    });

    test('throws error if gender is not in enum', () {
      final Map<String, dynamic> json1 = {
        'id': 1,
        'created_at': '2021-01-01T00:00:00.000',
        'username': 'username',
        'email': 'email',
        'description': 'description',
        'birth_date': '2021-01-01T00:00:00.000',
        'first_name': 'first_name',
        'last_name': 'last_name',
        'gender': -1,
        'avatar_url': 'avatar_url',
      };
      final Map<String, dynamic> json2 = {
        'id': 1,
        'created_at': '2021-01-01T00:00:00.000',
        'username': 'username',
        'email': 'email',
        'description': 'description',
        'birth_date': '2021-01-01T00:00:00.000',
        'first_name': 'first_name',
        'last_name': 'last_name',
        'gender': 5,
        'avatar_url': 'avatar_url',
      };
      expect(() => Profile.fromJson(json1), throwsA(isA<RangeError>()));
      expect(() => Profile.fromJson(json2), throwsA(isA<RangeError>()));
    });
  });

  group('Profile.fromJsonList', () {
    test('parses a list of profiles from json', () {
      final Map<String, dynamic> json = {
        'id': 1,
        'created_at': '2021-01-01T00:00:00.000',
        'username': 'username',
        'email': 'email',
      };

      final List<Map<String, dynamic>> jsonList = [json, json, json];
      final List<Profile> profiles = Profile.fromJsonList(jsonList);
      expect(profiles.first.id, json['id']);
      expect(profiles[1].createdAt, DateTime.parse(json['created_at']));
      expect(profiles.last.username, json['username']);
    });

    test('can handle an empty list', () {
      final List<Profile> profiles = Profile.fromJsonList([]);
      expect(profiles, []);
    });
  });

  group('toJson', () {
    test('returns a json representation of the profile', () async {
      final Profile profile = ProfileFactory().generateFake();
      final Map<String, dynamic> json = profile.toJson();
      expect(json['username'], profile.username);
      expect(json['email'], profile.email);
      expect(json['description'], profile.description);
      expect(json['birth_date'], profile.birthDate!.toUtc().toString());
      expect(json['first_name'], profile.firstName);
      expect(json['last_name'], profile.lastName);
      expect(json['gender'], profile.gender?.index);
      expect(json['avatar_url'], profile.avatarUrl);
      expect(json.keys.length, 8);
    });
  });

  group('toString', () {
    test('returns a string representation of the profile', () async {
      final Profile profile = ProfileFactory().generateFake(
        id: 1,
        username: 'username',
        email: 'email',
        createdAt: DateTime.parse('2021-01-01T00:00:00.000'),
      );
      expect(
        profile.toString(),
        'Profile{id: 1, username: username, email: email, createdAt: 2021-01-01 00:00:00.000}',
      );
    });
  });
}
