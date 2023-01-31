import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/account/models/profile_feature.dart';
import 'package:motis_mitfahr_app/account/pages/edit_account/edit_profile_features_page.dart';
import 'package:motis_mitfahr_app/util/supabase.dart';

import '../../util/factories/profile_factory.dart';
import '../../util/mocks/mock_server.dart';
import '../../util/mocks/request_processor.dart';
import '../../util/mocks/request_processor.mocks.dart';
import '../../util/pump_material.dart';

void main() {
  late Profile profile;
  final MockRequestProcessor processor = MockRequestProcessor();

  setUpAll(() async {
    MockServer.setProcessor(processor);
  });

  setUp(() {
    profile = ProfileFactory().generateFake(id: 1);
    SupabaseManager.setCurrentProfile(profile);
    whenRequest(processor, urlMatcher: equals('/rest/v1/profiles?id=eq.1')).thenReturnJson('');
  });
  group('edit_profile_features_page', () {
    testWidgets('show added features', (WidgetTester tester) async {
      await pumpMaterial(tester, EditProfileFeaturesPage(profile));
      await tester.pump();
      for (int i = 0; i < profile.features!.length; i++) {
        final featureFinder = find.byKey(Key('${profile.features![i].toString()} Tile'));
        expect(featureFinder, findsOneWidget);
      }
    });
    testWidgets('show not added features', (WidgetTester tester) async {
      await pumpMaterial(tester, EditProfileFeaturesPage(profile));
      await tester.pump();
      final List<Feature> notAddedFeatures =
          Feature.values.where((Feature e) => !profile.features!.contains(e)).toList();
      expect(notAddedFeatures.length + profile.features!.length, Feature.values.length);
      for (int i = 0; i < notAddedFeatures.length; i++) {
        final featureFinder = find.byKey(Key('${notAddedFeatures[i].toString()} Tile'));
        await tester.scrollUntilVisible(featureFinder, 100, scrollable: find.byType(Scrollable));
        expect(featureFinder, findsOneWidget);
      }
    });
    testWidgets('add features', (WidgetTester tester) async {
      await pumpMaterial(tester, EditProfileFeaturesPage(profile));
      await tester.pump();
      final List<Feature> notAddedFeatures = [];
      for (final feature in Feature.values) {
        if (!profile.features!.contains(feature)) {
          notAddedFeatures.add(feature);
        }
      }
      final Finder addFinder = find.descendant(
          of: find.ancestor(
              of: find.byKey(Key('${notAddedFeatures.first.toString()} Tile')), matching: find.byType(ListTile)),
          matching: find.byKey(const Key('addButton')));
      await tester.tap(addFinder);
      await tester.pump();
      expect(addFinder, findsNothing);
      final Finder addedFeatureFinder = find.descendant(
          of: find.ancestor(
              of: find.byKey(Key('${notAddedFeatures.first.toString()} Tile')), matching: find.byType(ListTile)),
          matching: find.byKey(const Key('removeButton')));
      expect(addedFeatureFinder, findsOneWidget);
    });
    testWidgets('delete features', (WidgetTester tester) async {
      await pumpMaterial(tester, EditProfileFeaturesPage(profile));
      await tester.pump();
      final Feature feature = profile.features!.first;
      final Finder deleteFinder = find.descendant(
          of: find.ancestor(of: find.byKey(Key('${feature.toString()} Tile')), matching: find.byType(ListTile)),
          matching: find.byKey(const Key('removeButton')));
      expect(deleteFinder, findsOneWidget);
      await tester.tap(deleteFinder);
      await tester.pump();
      expect(deleteFinder, findsNothing);
      final Finder deletedFeatureFinder = find.descendant(
          of: find.ancestor(of: find.byKey(Key('${feature.toString()} Tile')), matching: find.byType(ListTile)),
          matching: find.byKey(const Key('addButton')));
      await tester.scrollUntilVisible(deletedFeatureFinder, 100, scrollable: find.byType(Scrollable));
      expect(deletedFeatureFinder, findsOneWidget);
    });
    testWidgets('move features', (WidgetTester tester) async {
      await pumpMaterial(tester, EditProfileFeaturesPage(profile));
      await tester.pump();
      final Feature feature = profile.features!.first;
      expect(
          find.descendant(
              of: find.ancestor(of: find.byKey(Key('${feature.toString()} Tile')), matching: find.byType(ListTile)),
              matching: find.byKey(const Key('dragHandle'))),
          findsOneWidget);
      final Finder dragFinder = find.descendant(
          of: find.ancestor(of: find.byKey(Key('${feature.toString()} Tile')), matching: find.byType(ListTile)),
          matching: find.byKey(const Key('dragHandle')));
      expect(dragFinder, findsOneWidget);
      await tester.drag(dragFinder, const Offset(0, 50));
      await tester.pump();
      expect(
          find.descendant(
              of: find.byKey(const ValueKey<int>(0)), matching: find.byKey(Key('${feature.toString()} Tile'))),
          findsNothing);
      final int newIndex = profile.features!.length == 1 ? 2 : 1;
      expect(
          find.descendant(
              of: find.byKey(ValueKey<int>(newIndex)), matching: find.byKey(Key('${feature.toString()} Tile'))),
          findsOneWidget);
    });
    testWidgets('no features', (WidgetTester tester) async {
      profile = ProfileFactory().generateFake(id: 1, createDependencies: false);
      SupabaseManager.setCurrentProfile(profile);
      await pumpMaterial(tester, EditProfileFeaturesPage(profile));
      await tester.pump();
      expect(find.byKey(const Key('removeButton')), findsNothing);
      expect(find.byKey(const Key('emptyList')), findsOneWidget);
    });
    // same problem as with edit_username_page_test
    testWidgets('save Button', (WidgetTester tester) async {});
  });
}
