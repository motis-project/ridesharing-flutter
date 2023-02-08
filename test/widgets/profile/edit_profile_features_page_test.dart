import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/account/models/profile_feature.dart';
import 'package:motis_mitfahr_app/account/pages/edit_account/edit_profile_features_page.dart';
import 'package:motis_mitfahr_app/account/pages/profile_page.dart';
import 'package:motis_mitfahr_app/util/snackbar.dart';
import 'package:motis_mitfahr_app/util/supabase_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../util/factories/profile_factory.dart';
import '../../util/factories/profile_feature_factory.dart';
import '../../util/mocks/mock_server.dart';
import '../../util/mocks/request_processor.dart';
import '../../util/mocks/request_processor.mocks.dart';
import '../../util/pump_material.dart';

void main() {
  late Profile profile;
  final MockRequestProcessor processor = MockRequestProcessor();
  const String email = 'motismitfahrapp@gmail.com';
  const String authId = '123';

  setUpAll(() async {
    MockServer.setProcessor(processor);
  });

  setUp(() async {
    profile = ProfileFactory().generateFake(
      id: 1,
      profileFeatures: [
        ProfileFeatureFactory().generateFake(rank: 0, feature: Feature.accessible),
        ProfileFeatureFactory().generateFake(rank: 1, feature: Feature.requires3G),
        ProfileFeatureFactory().generateFake(rank: 2, feature: Feature.music),
      ],
    );
    supabaseManager.currentProfile = profile;

    whenRequest(
      processor,
      urlMatcher: startsWith('/auth/v1/token'),
      bodyMatcher: containsPair('email', 'motismitfahrapp@gmail.com'),
      methodMatcher: equals('POST'),
    ).thenReturnJson({
      'access_token': authId,
      'token_type': 'bearer',
      'user': User(
          id: authId,
          appMetadata: {},
          userMetadata: {},
          aud: 'public',
          createdAt: DateTime.now().toIso8601String(),
          email: email),
      'email': email,
    });

    await supabaseManager.supabaseClient.auth.signInWithPassword(
      email: email,
      password: authId,
    );

    whenRequest(processor, urlMatcher: contains('/rest/v1/profile')).thenReturnJson(profile.toJsonForApi());
  });
  group('edit_profile_features_page', () {
    testWidgets('show added features', (WidgetTester tester) async {
      await pumpMaterial(tester, EditProfileFeaturesPage(profile));
      for (int i = 0; i < profile.features!.length; i++) {
        final featureFinder = find.byKey(Key('${profile.features![i]} Tile'));
        expect(featureFinder, findsOneWidget);
      }
    });

    testWidgets('show not added features', (WidgetTester tester) async {
      await pumpMaterial(tester, EditProfileFeaturesPage(profile));

      final List<Feature> notAddedFeatures =
          Feature.values.where((Feature e) => !profile.features!.contains(e)).toList();

      expect(notAddedFeatures.length + profile.features!.length, Feature.values.length);

      for (int i = 0; i < notAddedFeatures.length; i++) {
        final featureFinder = find.byKey(Key('${notAddedFeatures[i]} Tile'));
        await tester.scrollUntilVisible(featureFinder, 100, scrollable: find.byType(Scrollable));
        expect(featureFinder, findsOneWidget);
      }
    });

    testWidgets('add features', (WidgetTester tester) async {
      await pumpMaterial(tester, EditProfileFeaturesPage(profile));

      final List<Feature> notAddedFeatures =
          Feature.values.where((Feature e) => !profile.features!.contains(e)).toList();

      Feature feature = notAddedFeatures.first;
      late Finder addFinder;

      //try adding features until found one that is not mutually exclusive
      for (final Feature notAddedFeature in notAddedFeatures) {
        addFinder = find.descendant(
            of: find.ancestor(of: find.byKey(Key('$notAddedFeature Tile')), matching: find.byType(ListTile)),
            matching: find.byKey(const Key('addButton')));
        expect(addFinder, findsOneWidget);

        await tester.tap(addFinder);
        await tester.pumpAndSettle();

        try {
          //check if snackbar is shown => feature is mutually exclusive
          expect(find.byType(SnackBar), findsNothing);
          feature = notAddedFeature;
          break;
        } catch (e) {
          //wait until snackbar is gone
          await tester.pump(SnackBarDurationType.medium.duration);
        }
      }

      expect(addFinder, findsNothing);

      final Finder addedFeatureFinder = find.descendant(
          of: find.ancestor(of: find.byKey(Key('$feature Tile')), matching: find.byType(ListTile)),
          matching: find.byKey(const Key('removeButton')));
      expect(addedFeatureFinder, findsOneWidget);
    });

    testWidgets('snackbar changes on different mutually exclusive', (WidgetTester tester) async {
      profile = ProfileFactory().generateFake(
        id: 1,
        profileFeatures: [
          ProfileFeatureFactory().generateFake(profileId: 1, feature: Feature.smoking, rank: 0),
          ProfileFeatureFactory().generateFake(profileId: 1, feature: Feature.vaping, rank: 1),
        ],
      );
      supabaseManager.currentProfile = profile;

      await pumpMaterial(tester, EditProfileFeaturesPage(profile));

      final Finder notSmokingFinder = find.descendant(
          of: find.ancestor(of: find.byKey(Key('${Feature.noSmoking} Tile')), matching: find.byType(ListTile)),
          matching: find.byKey(const Key('addButton')));
      final Finder notVapingFinder = find.descendant(
          of: find.ancestor(of: find.byKey(Key('${Feature.noVaping} Tile')), matching: find.byType(ListTile)),
          matching: find.byKey(const Key('addButton')));

      await tester.tap(notSmokingFinder);
      await tester.pumpAndSettle();
      expect(find.byKey(Key('${Feature.noSmoking} mutuallyExclusiveSnackBar')), findsOneWidget);

      await tester.tap(notVapingFinder);
      await tester.pumpAndSettle();
      expect(find.byKey(Key('${Feature.noSmoking} mutuallyExclusiveSnackBar')), findsNothing);
      expect(find.byKey(Key('${Feature.noVaping} mutuallyExclusiveSnackBar')), findsOneWidget);

      expect(notSmokingFinder, findsOneWidget);
      expect(notVapingFinder, findsOneWidget);
    });

    testWidgets('delete features', (WidgetTester tester) async {
      await pumpMaterial(tester, EditProfileFeaturesPage(profile));

      final Feature feature = profile.features!.first;
      final Finder deleteFinder = find.descendant(
          of: find.ancestor(of: find.byKey(Key('$feature Tile')), matching: find.byType(ListTile)),
          matching: find.byKey(const Key('removeButton')));
      expect(deleteFinder, findsOneWidget);

      await tester.tap(deleteFinder);
      await tester.pump();

      expect(deleteFinder, findsNothing);

      final Finder deletedFeatureFinder = find.descendant(
          of: find.ancestor(of: find.byKey(Key('$feature Tile')), matching: find.byType(ListTile)),
          matching: find.byKey(const Key('addButton')));
      await tester.scrollUntilVisible(deletedFeatureFinder, 100, scrollable: find.byType(Scrollable));
      expect(deletedFeatureFinder, findsOneWidget);
    });

    group('move features', () {
      testWidgets('move added feature', (WidgetTester tester) async {
        await pumpMaterial(tester, EditProfileFeaturesPage(profile));

        final Feature feature = profile.features!.first;
        final Finder dragFinder = find.descendant(
            of: find.ancestor(of: find.byKey(Key('$feature Tile')), matching: find.byType(ListTile)),
            matching: find.byKey(const Key('dragHandle')));
        expect(dragFinder, findsOneWidget);

        await tester.drag(dragFinder, const Offset(0, 50));
        await tester.pump();

        expect(find.descendant(of: find.byKey(const ValueKey<int>(0)), matching: find.byKey(Key('$feature Tile'))),
            findsNothing);

        //check if feature is at new position
        //1 if there were more than one added features (still in added features)
        //2 if there was only one added feature (now in not added features)
        final int newIndex = profile.features!.length == 1 ? 2 : 1;
        expect(find.descendant(of: find.byKey(ValueKey<int>(newIndex)), matching: find.byKey(Key('$feature Tile'))),
            findsOneWidget);
      });

      testWidgets('move not added feature', (WidgetTester tester) async {
        await pumpMaterial(tester, EditProfileFeaturesPage(profile));

        final Feature feature = Feature.values.where((Feature e) => !profile.features!.contains(e)).toList().first;
        final Finder dragFinder = find.descendant(
            of: find.ancestor(of: find.byKey(Key('$feature Tile')), matching: find.byType(ListTile)),
            matching: find.byKey(const Key('dragHandle')));
        expect(dragFinder, findsOneWidget);

        await tester.drag(dragFinder, const Offset(0, 50));
        await tester.pump();

        expect(
            find.descendant(
                of: find.byKey(ValueKey<int>(profile.profileFeatures!.length + 1)),
                matching: find.byKey(Key('$feature Tile'))),
            findsNothing);

        //check if feature now at the second position in the removed features
        expect(
            find.descendant(
                of: find.byKey(ValueKey<int>(profile.profileFeatures!.length + 2)),
                matching: find.byKey(Key('$feature Tile'))),
            findsOneWidget);
      });

      testWidgets('use move to add feature', (WidgetTester tester) async {
        await pumpMaterial(tester, EditProfileFeaturesPage(profile));

        final Feature feature = Feature.values.where((Feature e) => !profile.features!.contains(e)).toList().first;
        final Finder dragFinder = find.descendant(
            of: find.ancestor(of: find.byKey(Key('$feature Tile')), matching: find.byType(ListTile)),
            matching: find.byKey(const Key('dragHandle')));
        expect(dragFinder, findsOneWidget);

        await tester.drag(dragFinder, const Offset(0, -50));
        await tester.pump();

        expect(
            find.descendant(
                of: find.ancestor(of: find.byKey(Key('$feature Tile')), matching: find.byType(ListTile)),
                matching: find.byKey(const Key('removeButton'))),
            findsOneWidget);
      });

      testWidgets('use move to remove feature', (WidgetTester tester) async {
        await pumpMaterial(tester, EditProfileFeaturesPage(profile));

        final Feature feature = profile.features!.last;
        final Finder dragFinder = find.descendant(
            of: find.ancestor(of: find.byKey(Key('$feature Tile')), matching: find.byType(ListTile)),
            matching: find.byKey(const Key('dragHandle')));
        expect(dragFinder, findsOneWidget);

        await tester.drag(dragFinder, const Offset(0, 50));
        await tester.pump();

        expect(
            find.descendant(
                of: find.ancestor(of: find.byKey(Key('$feature Tile')), matching: find.byType(ListTile)),
                matching: find.byKey(const Key('addButton'))),
            findsOneWidget);
      });
    });

    testWidgets('no features', (WidgetTester tester) async {
      profile = ProfileFactory().generateFake(id: 1, createDependencies: false);
      supabaseManager.currentProfile = profile;

      await pumpMaterial(tester, EditProfileFeaturesPage(profile));

      expect(find.byKey(const Key('removeButton')), findsNothing);
      expect(find.byKey(const Key('emptyList')), findsOneWidget);
    });

    testWidgets('save Button', (WidgetTester tester) async {
      profile = ProfileFactory().generateFake(
        id: 1,
        profileFeatures: [
          ProfileFeatureFactory()
              .generateFake(profileId: 1, createdAt: DateTime.now(), feature: Feature.smoking, rank: 0),
          ProfileFeatureFactory()
              .generateFake(profileId: 1, createdAt: DateTime.now(), feature: Feature.petsAllowed, rank: 1),
          ProfileFeatureFactory()
              .generateFake(profileId: 1, createdAt: DateTime.now(), feature: Feature.quiet, rank: 2),
        ],
      );
      whenRequest(processor, urlMatcher: contains('/rest/v1/profile')).thenReturnJson(profile.toJsonForApi());

      supabaseManager.currentProfile = profile;

      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();

      await tester.scrollUntilVisible(find.byKey(const Key('features')), 100,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(
          find.descendant(of: find.byKey(const Key('features')), matching: find.byKey(const Key('editableRowButton'))));
      await tester.pumpAndSettle();
      expect(find.byType(EditProfileFeaturesPage), findsOneWidget);

      final deletedFeature = profile.features!.first;
      await tester.tap(find.descendant(
          of: find.ancestor(of: find.byKey(Key('$deletedFeature Tile')), matching: find.byType(ListTile)),
          matching: find.byKey(const Key('removeButton'))));
      await tester.pump();

      const addedFeature = Feature.noSmoking;
      await tester.tap(find.descendant(
          of: find.ancestor(of: find.byKey(Key('$addedFeature Tile')), matching: find.byType(ListTile)),
          matching: find.byKey(const Key('addButton'))));
      await tester.pump();

      expect(find.byKey(const Key('saveButton')), findsOneWidget);

      await tester.tap(find.byKey(const Key('saveButton')));
      await tester.pumpAndSettle();

      expect(find.byType(ProfilePage), findsOneWidget);

      //inserted feature
      verifyRequest(
        processor,
        urlMatcher: equals('/rest/v1/profile_features'),
        methodMatcher: equals('POST'),
        bodyMatcher: equals({'profile_id': 1, 'feature': addedFeature.index, 'rank': 2}),
      ).called(1);

      //moved feature
      verifyRequest(
        processor,
        urlMatcher: equals('/rest/v1/profile_features?profile_id=eq.1&feature=eq.${Feature.petsAllowed.index}'),
        methodMatcher: equals('PATCH'),
        bodyMatcher: equals({'rank': 0}),
      ).called(1);

      verifyRequest(
        processor,
        urlMatcher: equals('/rest/v1/profile_features?profile_id=eq.1&feature=eq.${Feature.quiet.index}'),
        methodMatcher: equals('PATCH'),
        bodyMatcher: equals({'rank': 1}),
      ).called(1);

      //deleted feature
      verifyRequest(
        processor,
        urlMatcher: equals('/rest/v1/profile_features?profile_id=eq.1&feature=eq.${deletedFeature.index}'),
        methodMatcher: equals('DELETE'),
      ).called(1);

      verifyRequest(
        processor,
        urlMatcher: startsWith('/rest/v1/profiles'),
        methodMatcher: equals('GET'),
      ).called(2);
    });
  });
}
