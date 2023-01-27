import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/account/models/profile_feature.dart';
import 'package:motis_mitfahr_app/account/pages/edit_account/edit_username_page.dart';
import 'package:motis_mitfahr_app/account/pages/profile_page.dart';
import 'package:motis_mitfahr_app/util/supabase.dart';

import '../util/factories/profile_factory.dart';
import '../util/mock_server.dart';
import '../util/pump_material.dart';
import '../util/request_processor.dart';
import '../util/request_processor.mocks.dart';

void main() {
  late Profile profile;
  final MockRequestProcessor processor = MockRequestProcessor();

  setUpAll(() async {
    MockServer.setProcessor(processor);
  });

  setUp(() {
    profile = ProfileFactory().generateFake(id: 1);
    SupabaseManager.setCurrentProfile(profile);
    whenRequest(processor,
            urlMatcher: equals(
                '/rest/v1/profiles?select=%2A%2Cprofile_features%28%2A%29%2Creviews_received%3Areviews%21reviews_receiver_id_fkey%28%2A%2Cwriter%3Awriter_id%28%2A%29%29%2Creports_received%3Areports%21reports_offender_id_fkey%28%2A%29&id=eq.1'))
        .thenReturnJson(profile.toJsonForApi());
  });

  group('currentUser', () {
    group('constructors', () {
      testWidgets('Works with id parameter', (WidgetTester tester) async {
        await pumpMaterial(tester, ProfilePage(profile.id!));
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        await tester.pump();

        expect(find.text(profile.username), findsNWidgets(2));
      });
      testWidgets('Works with object parameter', (WidgetTester tester) async {
        await pumpMaterial(tester, ProfilePage.fromProfile(profile));
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        await tester.pump();

        expect(find.text(profile.username), findsNWidgets(2));
      });
    });
    group('Profile content', () {
      testWidgets('Show username', (WidgetTester tester) async {
        await pumpMaterial(tester, ProfilePage.fromProfile(profile));
        await tester.pump();
        expect(find.text(profile.username), findsNWidgets(2));
      });
      testWidgets('Show email', (WidgetTester tester) async {
        await pumpMaterial(tester, ProfilePage.fromProfile(profile));
        await tester.pump();
        expect(find.text(profile.email), findsOneWidget);
      });
      testWidgets('Show fullName', (WidgetTester tester) async {
        await pumpMaterial(tester, ProfilePage.fromProfile(profile));
        await tester.pump();
        expect(find.text(profile.fullName), findsAtLeastNWidgets(1));
      });
      testWidgets('Show description', (WidgetTester tester) async {
        await pumpMaterial(tester, ProfilePage.fromProfile(profile));
        await tester.pump();
        expect(find.text(profile.description!), findsOneWidget);
      });
      testWidgets('Show age', (WidgetTester tester) async {
        await pumpMaterial(tester, ProfilePage.fromProfile(profile));
        await tester.pump();
        expect(find.text(profile.age.toString()), findsOneWidget);
      });
      testWidgets('Show gender', (WidgetTester tester) async {
        await pumpMaterial(tester, ProfilePage.fromProfile(profile));
        await tester.pump();
        final genderFinder = find.byKey(const Key('genderText'));
        expect(genderFinder, findsOneWidget);
      });
      testWidgets('Show features', (WidgetTester tester) async {
        await pumpMaterial(tester, ProfilePage.fromProfile(profile));
        await tester.pump();
        final scrollableFinder = find.byType(Scrollable).first;
        expect(scrollableFinder, findsOneWidget);
        for (final Feature feature in profile.features!) {
          final featureFinder = find.text(feature.name);
          tester.scrollUntilVisible(featureFinder, 100, scrollable: scrollableFinder);
          expect(featureFinder, findsOneWidget);
        }
      });
      testWidgets('Show review', (WidgetTester tester) async {
        await pumpMaterial(tester, ProfilePage.fromProfile(profile));
        await tester.pump();
      });
    });
    group('Buttons', () {
      testWidgets('Show Sign Out button', (WidgetTester tester) async {
        await pumpMaterial(tester, ProfilePage.fromProfile(profile));
        await tester.pump();
        final signOutButtonFinder = find.byKey(const Key('signOutButton'));
        expect(signOutButtonFinder, findsOneWidget);
        //await tester.tap(signOutButtonFinder);
        //await tester.pump();
        //expect(find.byType(WelcomePage).hitTestable(), findsOneWidget);
        //expect(SupabaseManager.getCurrentProfile(), null);
      });
      testWidgets('Avatar is tappable', (WidgetTester tester) async {
        await pumpMaterial(tester, ProfilePage.fromProfile(profile));
        await tester.pump();
        expect(find.byKey(const Key('AvatarTappable')), findsOneWidget);
      });
      testWidgets('Show edit Avatar button', (WidgetTester tester) async {
        await pumpMaterial(tester, ProfilePage.fromProfile(profile));
        await tester.pump();
        expect(find.byKey(const Key('AvatarUpload')), findsOneWidget);
      });
      testWidgets('Show edit Username button', (WidgetTester tester) async {
        await pumpMaterial(tester, ProfilePage.fromProfile(profile));
        await tester.pump();
        await tester.tap(find.byKey(const Key('editUsernameButton')));
        await tester.pumpAndSettle();
        expect(find.byType(EditUsernamePage).hitTestable(), findsOneWidget);
      });
      testWidgets('Show edit FullName button', (WidgetTester tester) async {
        await pumpMaterial(tester, ProfilePage.fromProfile(profile));
        await tester.pump();
        final editFullNameFinder = find.byKey(const Key('editFullNameButton'));
        expect(editFullNameFinder, findsOneWidget);
        //await tester.tap(editFullNameFinder);
        //await tester.pumpAndSettle();
        //expect(find.byType(EditFullNamePage).hitTestable(), findsOneWidget);
      });
      testWidgets('Show edit Description button', (WidgetTester tester) async {
        await pumpMaterial(tester, ProfilePage.fromProfile(profile));
        await tester.pump();
        final editDescriptionFinder = find.byKey(const Key('editDescriptionButton'));
        expect(editDescriptionFinder, findsOneWidget);
      });
      testWidgets('Show edit Age button', (WidgetTester tester) async {
        await pumpMaterial(tester, ProfilePage.fromProfile(profile));
        await tester.pump();
        final editAgeFinder = find.byKey(const Key('editAgeButton'));
        expect(editAgeFinder, findsOneWidget);
      });
      testWidgets('Show edit Gender button', (WidgetTester tester) async {
        await pumpMaterial(tester, ProfilePage.fromProfile(profile));
        await tester.pump();
        final editGenderFinder = find.byKey(const Key('editGenderButton'));
        expect(editGenderFinder, findsOneWidget);
      });
      testWidgets('Show edit Features button', (WidgetTester tester) async {
        await pumpMaterial(tester, ProfilePage.fromProfile(profile));
        await tester.pump();
        final editFeaturesFinder = find.byKey(const Key('editFeaturesButton'));
        expect(editFeaturesFinder, findsOneWidget);
      });
      testWidgets('Show Reviews button', (WidgetTester tester) async {
        await pumpMaterial(tester, ProfilePage.fromProfile(profile));
        await tester.pump();
        final reviewsFinder = find.byKey(const Key('reviewsButton'));
        expect(reviewsFinder, findsOneWidget);
      });
    });
  });
  group('not currentUser', () {
    SupabaseManager.setCurrentProfile(ProfileFactory().generateFake(id: 2));
    group('constructors', () {
      testWidgets('Works with id parameter', (WidgetTester tester) async {
        await pumpMaterial(tester, ProfilePage(profile.id!));
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        await tester.pump();

        expect(find.text(profile.username), findsNWidgets(2));
      });

      testWidgets('Works with object parameter', (WidgetTester tester) async {
        await pumpMaterial(tester, ProfilePage.fromProfile(profile));
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        await tester.pump();

        expect(find.text(profile.username), findsNWidgets(2));
      });
    });
    group('Profile content', () {
      testWidgets('Show username', (WidgetTester tester) async {
        await pumpMaterial(tester, ProfilePage.fromProfile(profile));
        await tester.pump();
        expect(find.text(profile.username), findsNWidgets(2));
      });
      testWidgets('Show email', (WidgetTester tester) async {
        await pumpMaterial(tester, ProfilePage.fromProfile(profile));
        await tester.pump();
        expect(find.text(profile.email), findsOneWidget);
      });
      testWidgets('Show fullName', (WidgetTester tester) async {
        await pumpMaterial(tester, ProfilePage.fromProfile(profile));
        await tester.pump();
        expect(find.text(profile.fullName), findsAtLeastNWidgets(1));
      });
      testWidgets('Show description', (WidgetTester tester) async {
        await pumpMaterial(tester, ProfilePage.fromProfile(profile));
        await tester.pump();
        expect(find.text(profile.description!), findsOneWidget);
      });
      testWidgets('Show age', (WidgetTester tester) async {
        await pumpMaterial(tester, ProfilePage.fromProfile(profile));
        await tester.pump();
        expect(find.text(profile.age.toString()), findsOneWidget);
      });
      testWidgets('Show gender', (WidgetTester tester) async {
        await pumpMaterial(tester, ProfilePage.fromProfile(profile));
        await tester.pump();
        final genderFinder = find.byKey(const Key('genderText'));
        expect(genderFinder, findsOneWidget);
      });
      testWidgets('Show features', (WidgetTester tester) async {
        await pumpMaterial(tester, ProfilePage.fromProfile(profile));
        await tester.pump();
        final scrollableFinder = find.byType(Scrollable).first;
        expect(scrollableFinder, findsOneWidget);
        for (final Feature feature in profile.features!) {
          final featureFinder = find.text(feature.name);
          tester.scrollUntilVisible(featureFinder, 100, scrollable: scrollableFinder);
          expect(featureFinder, findsOneWidget);
        }
      });
      testWidgets('Show review', (WidgetTester tester) async {
        await pumpMaterial(tester, ProfilePage.fromProfile(profile));
        await tester.pump();
      });
    });
    group('Buttons', () {
      testWidgets('Show Sign Out button', (WidgetTester tester) async {
        await pumpMaterial(tester, ProfilePage.fromProfile(profile));
        await tester.pump();
        final signOutButtonFinder = find.byKey(const Key('signOutButton'));
        expect(signOutButtonFinder, findsOneWidget);
        //await tester.tap(signOutButtonFinder);
        //await tester.pump();
        //expect(find.byType(WelcomePage).hitTestable(), findsOneWidget);
        //expect(SupabaseManager.getCurrentProfile(), null);
      });
      testWidgets('Avatar is tappable', (WidgetTester tester) async {
        await pumpMaterial(tester, ProfilePage.fromProfile(profile));
        await tester.pump();
        expect(find.byKey(const Key('AvatarTappable')), findsOneWidget);
      });
      testWidgets('Show edit Avatar button', (WidgetTester tester) async {
        await pumpMaterial(tester, ProfilePage.fromProfile(profile));
        await tester.pump();
        expect(find.byKey(const Key('AvatarUpload')), findsOneWidget);
      });
      testWidgets('Show edit Username button', (WidgetTester tester) async {
        await pumpMaterial(tester, ProfilePage.fromProfile(profile));
        await tester.pump();
        await tester.tap(find.byKey(const Key('editUsernameButton')));
        await tester.pumpAndSettle();
        expect(find.byType(EditUsernamePage).hitTestable(), findsOneWidget);
      });
      testWidgets('Show edit FullName button', (WidgetTester tester) async {
        await pumpMaterial(tester, ProfilePage.fromProfile(profile));
        await tester.pump();
        final editFullNameFinder = find.byKey(const Key('editFullNameButton'));
        expect(editFullNameFinder, findsOneWidget);
        //await tester.tap(editFullNameFinder);
        //await tester.pumpAndSettle();
        //expect(find.byType(EditFullNamePage).hitTestable(), findsOneWidget);
      });
      testWidgets('Show edit Description button', (WidgetTester tester) async {
        await pumpMaterial(tester, ProfilePage.fromProfile(profile));
        await tester.pump();
        final editDescriptionFinder = find.byKey(const Key('editDescriptionButton'));
        expect(editDescriptionFinder, findsOneWidget);
      });
      testWidgets('Show edit Age button', (WidgetTester tester) async {
        await pumpMaterial(tester, ProfilePage.fromProfile(profile));
        await tester.pump();
        final editAgeFinder = find.byKey(const Key('editAgeButton'));
        expect(editAgeFinder, findsOneWidget);
      });
      testWidgets('Show edit Gender button', (WidgetTester tester) async {
        await pumpMaterial(tester, ProfilePage.fromProfile(profile));
        await tester.pump();
        final editGenderFinder = find.byKey(const Key('editGenderButton'));
        expect(editGenderFinder, findsOneWidget);
      });
      testWidgets('Show edit Features button', (WidgetTester tester) async {
        await pumpMaterial(tester, ProfilePage.fromProfile(profile));
        await tester.pump();
        final editFeaturesFinder = find.byKey(const Key('editFeaturesButton'));
        expect(editFeaturesFinder, findsOneWidget);
      });
      testWidgets('Show Reviews button', (WidgetTester tester) async {
        await pumpMaterial(tester, ProfilePage.fromProfile(profile));
        await tester.pump();
        final reviewsFinder = find.byKey(const Key('reviewsButton'));
        expect(reviewsFinder, findsOneWidget);
      });
    });
  });
}
