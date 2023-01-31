import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/account/models/profile_feature.dart';
import 'package:motis_mitfahr_app/account/pages/edit_account/edit_profile_features_page.dart';
import 'package:motis_mitfahr_app/account/pages/profile_page.dart';
import 'package:motis_mitfahr_app/util/snackbar.dart';
import 'package:motis_mitfahr_app/util/supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../util/factories/profile_factory.dart';
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

  setUp(() {
    profile = ProfileFactory().generateFake(id: 1);
    SupabaseManager.setCurrentProfile(profile);
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
    whenRequest(processor, urlMatcher: contains('/rest/v1/profile')).thenReturnJson(profile.toJsonForApi());
  });
  group('edit_profile_features_page', () {
    testWidgets('show added features', (WidgetTester tester) async {
      // load page
      await pumpMaterial(tester, EditProfileFeaturesPage(profile));
      await tester.pump();

      // check if added features are shown
      for (int i = 0; i < profile.features!.length; i++) {
        final featureFinder = find.byKey(Key('${profile.features![i].toString()} Tile'));
        expect(featureFinder, findsOneWidget);
      }
    });
    testWidgets('show not added features', (WidgetTester tester) async {
      // load page
      await pumpMaterial(tester, EditProfileFeaturesPage(profile));
      await tester.pump();

      // find out what features are not added
      final List<Feature> notAddedFeatures =
          Feature.values.where((Feature e) => !profile.features!.contains(e)).toList();

      //check if any features are missing
      expect(notAddedFeatures.length + profile.features!.length, Feature.values.length);

      // check if not added features are shown
      for (int i = 0; i < notAddedFeatures.length; i++) {
        final featureFinder = find.byKey(Key('${notAddedFeatures[i].toString()} Tile'));
        await tester.scrollUntilVisible(featureFinder, 100, scrollable: find.byType(Scrollable));
        expect(featureFinder, findsOneWidget);
      }
    });
    testWidgets('add features', (WidgetTester tester) async {
      // load page
      await pumpMaterial(tester, EditProfileFeaturesPage(profile));
      await tester.pump();

      // find out what features are not added
      final List<Feature> notAddedFeatures =
          Feature.values.where((Feature e) => !profile.features!.contains(e)).toList();

      Feature feature = notAddedFeatures.first;
      late Finder addFinder;

      //try adding features until found one that is not mutually exclusive
      for (final Feature notAddedFeature in notAddedFeatures) {
        //check if feature is not added and exists
        addFinder = find.descendant(
            of: find.ancestor(
                of: find.byKey(Key('${notAddedFeature.toString()} Tile')), matching: find.byType(ListTile)),
            matching: find.byKey(const Key('addButton')));
        expect(addFinder, findsOneWidget);

        //tap add button
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

      //check if feature is removed from not added features
      expect(addFinder, findsNothing);

      //check if feature is added to added features
      final Finder addedFeatureFinder = find.descendant(
          of: find.ancestor(of: find.byKey(Key('${feature.toString()} Tile')), matching: find.byType(ListTile)),
          matching: find.byKey(const Key('removeButton')));
      expect(addedFeatureFinder, findsOneWidget);
    });
    testWidgets('delete features', (WidgetTester tester) async {
      // load page
      await pumpMaterial(tester, EditProfileFeaturesPage(profile));
      await tester.pump();

      //find feature to delete
      final Feature feature = profile.features!.first;
      final Finder deleteFinder = find.descendant(
          of: find.ancestor(of: find.byKey(Key('${feature.toString()} Tile')), matching: find.byType(ListTile)),
          matching: find.byKey(const Key('removeButton')));
      expect(deleteFinder, findsOneWidget);

      //delete feature
      await tester.tap(deleteFinder);
      await tester.pump();

      //check if feature is removed from added features
      expect(deleteFinder, findsNothing);

      //check if feature is added to not added features
      final Finder deletedFeatureFinder = find.descendant(
          of: find.ancestor(of: find.byKey(Key('${feature.toString()} Tile')), matching: find.byType(ListTile)),
          matching: find.byKey(const Key('addButton')));
      await tester.scrollUntilVisible(deletedFeatureFinder, 100, scrollable: find.byType(Scrollable));
      expect(deletedFeatureFinder, findsOneWidget);
    });
    testWidgets('move features', (WidgetTester tester) async {
      // load page
      await pumpMaterial(tester, EditProfileFeaturesPage(profile));
      await tester.pump();

      //find feature to move
      final Feature feature = profile.features!.first;
      expect(
          find.descendant(
              of: find.ancestor(of: find.byKey(Key('${feature.toString()} Tile')), matching: find.byType(ListTile)),
              matching: find.byKey(const Key('dragHandle'))),
          findsOneWidget);

      //find drag handle
      final Finder dragFinder = find.descendant(
          of: find.ancestor(of: find.byKey(Key('${feature.toString()} Tile')), matching: find.byType(ListTile)),
          matching: find.byKey(const Key('dragHandle')));
      expect(dragFinder, findsOneWidget);

      //move feature
      await tester.drag(dragFinder, const Offset(0, 50));
      await tester.pump();

      //check if feature is not at old position
      expect(
          find.descendant(
              of: find.byKey(const ValueKey<int>(0)), matching: find.byKey(Key('${feature.toString()} Tile'))),
          findsNothing);

      //check if feature is at new position
      //1 if there were more than one added features (still in added features)
      //2 if there was only one added feature (now in not added features)
      final int newIndex = profile.features!.length == 1 ? 2 : 1;
      expect(
          find.descendant(
              of: find.byKey(ValueKey<int>(newIndex)), matching: find.byKey(Key('${feature.toString()} Tile'))),
          findsOneWidget);
    });
    testWidgets('no features', (WidgetTester tester) async {
      //setup profile with no features
      profile = ProfileFactory().generateFake(id: 1, createDependencies: false);
      SupabaseManager.setCurrentProfile(profile);

      //load page
      await pumpMaterial(tester, EditProfileFeaturesPage(profile));
      await tester.pump();

      //check if no features are added
      expect(find.byKey(const Key('removeButton')), findsNothing);
      expect(find.byKey(const Key('emptyList')), findsOneWidget);
    });
    testWidgets('save Button', (WidgetTester tester) async {
      // sign in
      SupabaseManager.supabaseClient.auth.signInWithPassword(
        email: email,
        password: authId,
      );

      // load ProfilePage
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();

      //load EditProfileFeaturesPage
      await tester.scrollUntilVisible(find.byKey(const Key('features')), 100,
          scrollable: find.byType(Scrollable).first);
      await tester
          .tap(find.descendant(of: find.byKey(const Key('features')), matching: find.byKey(const Key('editButton'))));
      await tester.pumpAndSettle();
      expect(find.byType(EditProfileFeaturesPage), findsOneWidget);

      // check if save button is displayed
      expect(find.byKey(const Key('saveButton')), findsOneWidget);

      // tap save button
      await tester.tap(find.byKey(const Key('saveButton')));
      await tester.pumpAndSettle();

      // check if ProfilePage is loaded
      expect(find.byType(ProfilePage), findsOneWidget);
    });
  });
}
