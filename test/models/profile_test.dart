import 'dart:convert';

import 'package:mockito/mockito.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/util/supabase.dart';

import '../util/factories/model_factory.dart';
import '../util/factories/profile_factory.dart';
import '../util/factories/profile_feature_factory.dart';
import '../util/factories/report_factory.dart';
import '../util/factories/review_factory.dart';
import '../util/mock_server.dart';
import '../util/mock_server.mocks.dart';

// Die Klasse UrlProcessor muss zu Beginn jeder Testdatei implementiert werden und die Methode processUrl überschrieben werden
// Wird die Methode ProcessUrl aufgrufen, wird für den dort definierten Fall (in dem Beispiel client.from('drives').select('driver_id,seats')) die Antwort definiert
// Die Datenbankabfrage an den Client wird so abgefangen und das gewünschte Ergebnis zurückgegeben.
// Um herauszufinden welche URL durch die jeweilige Datenbankabfrage generiert wird, einfach den auskommentierten Print-Aufruf in der mockServer.Dart Datei aktivieren

void main() {
  MockUrlProcessor profileProcessor = MockUrlProcessor();

  //setup muss in jeder Testklasse einmal aufgerufen werden
  setUp(() async {
    await MockServer.initialize();
    MockServer.handleRequests(profileProcessor);
  });

  group('fullname', () {
    test('returns empty if neither name nor surname are set', () async {
      Profile profile = ProfileFactory().generateFake(
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
      SupabaseManager.setCurrentProfile(currentProfile);
      expect(profile.isCurrentUser, true);
    });

    test('returns false if id is not equal to current profile id', () async {
      final profile = ProfileFactory().generateFake();
      final currentProfile = ProfileFactory().generateFake(id: profile.id! + 1);
      SupabaseManager.setCurrentProfile(currentProfile);
      expect(profile.isCurrentUser, false);
    });
  });

  group('Profile.fromJson', () {
    test('parses a profile from json', () async {
      Map<String, dynamic> json = {
        "id": 1,
        "created_at": "2021-01-01T00:00:00.000Z",
        "username": "username",
        "email": "email",
        "description": "description",
        "birth_date": "2021-01-01T00:00:00.000Z",
        "surname": "surname",
        "name": "name",
        "gender": 0,
        "avatar_url": "avatar_url",
      };
      Profile profile = Profile.fromJson(json);
      expect(profile.id, json["id"]);
      expect(profile.createdAt, DateTime.parse(json["created_at"]));
      expect(profile.username, json["username"]);
      expect(profile.email, json["email"]);
      expect(profile.description, json["description"]);
      expect(profile.birthDate, DateTime.parse(json["birth_date"]));
      expect(profile.surname, json["surname"]);
      expect(profile.name, json["name"]);
      expect(profile.gender, Gender.male);
      expect(profile.avatarUrl, json["avatar_url"]);
    });

    test('can handle associated models', () async {
      Map<String, dynamic> json = {
        "id": 1,
        "created_at": "2021-01-01T00:00:00.000Z",
        "username": "username",
        "email": "email",
        "reviews_received": ReviewFactory().generateFakeJsonList(length: 3),
        "profile_features": ProfileFeatureFactory().generateFakeJsonList(length: 3),
        "reports_received": ReportFactory().generateFakeJsonList(length: 3),
      };
      Profile profile = Profile.fromJson(json);
      expect(profile.reviewsReceived!.length, 3);
      expect(profile.profileFeatures!.length, 3);
      expect(profile.reportsReceived!.length, 3);
    });
  });

  group('Profile.fromJsonList', () {
    test('parses a list of profiles from json', () async {
      Map<String, dynamic> json = {
        "id": 1,
        "created_at": "2021-01-01T00:00:00.000Z",
        "username": "username",
        "email": "email",
      };

      List<Map<String, dynamic>> jsonList = [json, json, json];
      List<Profile> profiles = Profile.fromJsonList(jsonList);
      expect(profiles.first.id, json["id"]);
      expect(profiles[1].createdAt, DateTime.parse(json["created_at"]));
      expect(profiles.last.username, json["username"]);
    });
  });

  group('toJson', () {
    test('returns a json representation of the profile', () async {
      Profile profile = ProfileFactory().generateFake();
      Map<String, dynamic> json = profile.toJson();
      expect(json["username"], profile.username);
      expect(json["email"], profile.email);
      expect(json["description"], profile.description);
      expect(json["birth_date"], profile.birthDate!.toString());
      expect(json["surname"], profile.surname);
      expect(json["name"], profile.name);
      expect(json["gender"], profile.gender?.index);
      expect(json["avatar_url"], profile.avatarUrl);
    });
  });

  group('toString', () {
    test('returns a string representation of the profile', () async {
      Profile profile = ProfileFactory().generateFake(
        id: 1,
        username: "username",
        email: "email",
        createdAt: DateTime.parse("2021-01-01T00:00:00.000Z"),
      );
      expect(
        profile.toString(),
        "Profile{id: 1, username: username, email: email, createdAt: 2021-01-01 00:00:00.000Z}",
      );
    });
  });

  group('getProfileFromAuthId', () {
    test('returns null if no profile exists with that auth id', () async {
      when(profileProcessor.processUrl(any)).thenReturn("");
      Profile? result = await Profile.getProfileFromAuthId("1");
      expect(result, null);
    });

    test('returns the profile if it exists', () async {
      final profile = ProfileFactory().generateFake();
      when(profileProcessor.processUrl(any)).thenReturn(jsonEncode(profile.toJsonForApi()));
      Profile result = await Profile.getProfileFromAuthId("auth-id") as Profile;
      expect(result.id, profile.id);
    });
  });
}
