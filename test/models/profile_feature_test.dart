import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/account/models/profile_feature.dart';

import '../util/factories/profile_factory.dart';
import '../util/factories/profile_feature_factory.dart';

void main() {
  group('ProfileFeature.fromJson', (() {
    test('parses ProfileFeature from json', (() {
      final Map<String, dynamic> json = {
        'id': 1,
        'created_at': '2021-01-01T00:00:00.000Z',
        'profile_id': 1,
        'feature': Feature.noSmoking.index,
        'rank': 1,
      };
      final ProfileFeature profileFeature = ProfileFeature.fromJson(json);
      expect(profileFeature.id, 1);
      expect(profileFeature.createdAt, DateTime.parse('2021-01-01T00:00:00.000Z'));
      expect(profileFeature.profileId, 1);
      expect(profileFeature.feature, Feature.noSmoking);
    }));

    test('can handle Profile', (() {
      final Profile profile = ProfileFactory().generateFake();
      final Map<String, dynamic> json = {
        'id': 1,
        'created_at': '2021-01-01T00:00:00.000Z',
        'profile_id': profile.id,
        'feature': Feature.accessible.index,
        'rank': 1,
        'profile': profile.toJsonForApi(),
      };
      final ProfileFeature profileFeature = ProfileFeature.fromJson(json);
      expect(profileFeature.profile.toString(), profile.toString());
    }));

    test('throws error when feature is not in enum', (() {
      final Map<String, dynamic> json1 = {
        'id': 1,
        'created_at': '2021-01-01T00:00:00.000Z',
        'profile_id': 1,
        'feature': 20,
        'rank': 1,
      };
      final Map<String, dynamic> json2 = {
        'id': 1,
        'created_at': '2021-01-01T00:00:00.000Z',
        'profile_id': 1,
        'feature': -1,
        'rank': 1,
      };
      expect(() => ProfileFeature.fromJson(json1), throwsA(isA<RangeError>()));
      expect(() => ProfileFeature.fromJson(json2), throwsA(isA<RangeError>()));
    }));
  }));

  group('ProfileFeature.fromJsonList', () {
    test('parses a list of ProfileFeatures from json', () {
      final Map<String, dynamic> json = {
        'id': 1,
        'created_at': '2021-01-01T00:00:00.000Z',
        'profile_id': 1,
        'feature': Feature.noSmoking.index,
        'rank': 1,
      };
      final List<Map<String, dynamic>> jsonList = [json, json, json];
      final List<ProfileFeature> profileFeatures = ProfileFeature.fromJsonList(jsonList);
      expect(profileFeatures.first.id, json['id']);
      expect(profileFeatures[1].createdAt, DateTime.parse(json['created_at']));
      expect(profileFeatures.last.profileId, json['profile_id']);
      expect(profileFeatures.first.feature, Feature.noSmoking);
    });

    test('can handle an empty list', () {
      final List<ProfileFeature> profileFeatures = ProfileFeature.fromJsonList([]);
      expect(profileFeatures, []);
    });
  });

  group('ProfileFeature.toJson', () {
    test('returns a json representation of the ProfileFeature', () async {
      final ProfileFeature profileFeature = ProfileFeatureFactory().generateFake();
      final Map<String, dynamic> json = profileFeature.toJson();
      expect(json['profile_id'], profileFeature.profileId);
      expect(json['feature'], profileFeature.feature.index);
      expect(json['rank'], profileFeature.rank);
      expect(json.keys.length, 3);
    });
  });

  group('Feature.isMutuallyExclusive', () {
    test('returns true if the features are mutually exclusive', () {
      final bool isMutuallyExclusive = Feature.noSmoking.isMutuallyExclusive(Feature.smoking);
      expect(isMutuallyExclusive, true);
      expect(Feature.smoking.isMutuallyExclusive(Feature.noSmoking), true);
      expect(Feature.noVaping.isMutuallyExclusive(Feature.vaping), true);
      expect(Feature.vaping.isMutuallyExclusive(Feature.noVaping), true);
      expect(Feature.noPetsAllowed.isMutuallyExclusive(Feature.petsAllowed), true);
      expect(Feature.petsAllowed.isMutuallyExclusive(Feature.noPetsAllowed), true);
      expect(Feature.noChildrenAllowed.isMutuallyExclusive(Feature.childrenAllowed), true);
      expect(Feature.childrenAllowed.isMutuallyExclusive(Feature.noChildrenAllowed), true);
      expect(Feature.relaxedDrivingStyle.isMutuallyExclusive(Feature.speedyDrivingStyle), true);
      expect(Feature.speedyDrivingStyle.isMutuallyExclusive(Feature.relaxedDrivingStyle), true);
    });

    test('returns false if the features are not mutually exclusive', () {
      expect(Feature.noSmoking.isMutuallyExclusive(Feature.noVaping), false);
      expect(Feature.noSmoking.isMutuallyExclusive(Feature.noPetsAllowed), false);
      expect(Feature.noVaping.isMutuallyExclusive(Feature.noPetsAllowed), false);
      expect(Feature.noSmoking.isMutuallyExclusive(Feature.noChildrenAllowed), false);
    });

    test('always false for features that have no mutual exclusions', () {
      for (final Feature feature in Feature.values) {
        expect(Feature.accessible.isMutuallyExclusive(feature), false);
        expect(Feature.requires3G.isMutuallyExclusive(feature), false);
        expect(Feature.music.isMutuallyExclusive(feature), false);
        expect(Feature.quiet.isMutuallyExclusive(feature), false);
      }
    });
  });
}
