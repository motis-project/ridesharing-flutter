import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/util/supabase_manager.dart';

import '../util/factories/model_factory.dart';
import '../util/factories/profile_factory.dart';
import '../util/factories/profile_feature_factory.dart';
import '../util/factories/report_factory.dart';
import '../util/factories/review_factory.dart';

void main() {
  group('fullname', () {
    test('returns empty if neither name nor surname are set', () async {
      final Profile profile = ProfileFactory().generateFake(
        name: NullableParameter(null),
        surname: NullableParameter(null),
      );
      expect(profile.fullName, '');
    });

    test('returns surname if name is not set', () async {
      final profile = ProfileFactory().generateFake(
        name: NullableParameter(null),
      );
      expect(profile.fullName, profile.surname);
    });

    test('returns name if surname is not set', () async {
      final profile = ProfileFactory().generateFake(
        surname: NullableParameter(null),
      );
      expect(profile.fullName, profile.name);
    });

    test('returns name and surname if both are set', () async {
      final profile = ProfileFactory().generateFake(
        name: NullableParameter('name'),
        surname: NullableParameter('surname'),
      );
      expect(profile.fullName, 'surname name');
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
        surname: NullableParameter(null),
        name: NullableParameter(null),
        gender: NullableParameter(null),
        avatarUrl: NullableParameter(null),
      );
      expect(profile.hasNoPersonalInformation, true);
    });

    test('returns false if one piece of personal information is not null', () async {
      final profile = ProfileFactory().generateFake(
        description: NullableParameter(null),
        birthDate: NullableParameter(null),
        surname: NullableParameter(null),
        name: NullableParameter(null),
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
        'created_at': '2021-01-01T00:00:00.000Z',
        'username': 'username',
        'email': 'email',
        'description': 'description',
        'birth_date': '2021-01-01T00:00:00.000Z',
        'surname': 'surname',
        'name': 'name',
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
      expect(profile.surname, json['surname']);
      expect(profile.name, json['name']);
      expect(profile.gender, Gender.male);
      expect(profile.avatarUrl, json['avatar_url']);
    });

    test('can handle associated models', () async {
      final Map<String, dynamic> json = {
        'id': 1,
        'created_at': '2021-01-01T00:00:00.000Z',
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
        'created_at': '2021-01-01T00:00:00.000Z',
        'username': 'username',
        'email': 'email',
        'description': 'description',
        'birth_date': '2021-01-01T00:00:00.000Z',
        'surname': 'surname',
        'name': 'name',
        'gender': -1,
        'avatar_url': 'avatar_url',
      };
      final Map<String, dynamic> json2 = {
        'id': 1,
        'created_at': '2021-01-01T00:00:00.000Z',
        'username': 'username',
        'email': 'email',
        'description': 'description',
        'birth_date': '2021-01-01T00:00:00.000Z',
        'surname': 'surname',
        'name': 'name',
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
        'created_at': '2021-01-01T00:00:00.000Z',
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
      expect(json['birth_date'], profile.birthDate!.toString());
      expect(json['surname'], profile.surname);
      expect(json['name'], profile.name);
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
        createdAt: DateTime.parse('2021-01-01T00:00:00.000Z'),
      );
      expect(
        profile.toString(),
        'Profile{id: 1, username: username, email: email, createdAt: 2021-01-01 00:00:00.000Z}',
      );
    });
  });
}
