import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/account/pages/avatar_picture_page.dart';
import 'package:motis_mitfahr_app/account/pages/edit_account/edit_birth_date_page.dart';
import 'package:motis_mitfahr_app/account/pages/edit_account/edit_description_page.dart';
import 'package:motis_mitfahr_app/account/pages/edit_account/edit_full_name_page.dart';
import 'package:motis_mitfahr_app/account/pages/edit_account/edit_gender_page.dart';
import 'package:motis_mitfahr_app/account/pages/edit_account/edit_profile_features_page.dart';
import 'package:motis_mitfahr_app/account/pages/edit_account/edit_username_page.dart';
import 'package:motis_mitfahr_app/account/pages/profile_page.dart';
import 'package:motis_mitfahr_app/account/pages/reviews_page.dart';
import 'package:motis_mitfahr_app/account/pages/write_report_page.dart';
import 'package:motis_mitfahr_app/util/supabase.dart';
import 'package:motis_mitfahr_app/welcome/pages/welcome_page.dart';

import '../util/factories/model_factory.dart';
import '../util/factories/profile_factory.dart';
import '../util/factories/report_factory.dart';
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

// no random
  group('constructors', () {
    for (int i = 0; i < 2; i++) {
      i == 0
          ? SupabaseManager.setCurrentProfile(profile)
          : SupabaseManager.setCurrentProfile(ProfileFactory().generateFake(id: 2));
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
    }
  });
  group('Profile content', () {
    testWidgets('Show username', (WidgetTester tester) async {
      final Random random = Random();
      if (random.nextBool()) SupabaseManager.setCurrentProfile(ProfileFactory().generateFake(id: 2));
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();
      expect(find.text(profile.username), findsNWidgets(2));
    });
    testWidgets('Show email', (WidgetTester tester) async {
      final Random random = Random();
      final bool currentProfile = random.nextBool();
      if (random.nextBool()) SupabaseManager.setCurrentProfile(ProfileFactory().generateFake(id: 2));
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();
      currentProfile
          ? expect(find.text(profile.email), findsOneWidget)
          : expect(find.text(profile.email), findsNothing);
    });
    testWidgets('Show fullName', (WidgetTester tester) async {
      final Random random = Random();
      if (random.nextBool()) SupabaseManager.setCurrentProfile(ProfileFactory().generateFake(id: 2));
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();
      expect(find.text(profile.fullName), findsAtLeastNWidgets(1));
    });
    testWidgets('Show description', (WidgetTester tester) async {
      final Random random = Random();
      if (random.nextBool()) SupabaseManager.setCurrentProfile(ProfileFactory().generateFake(id: 2));
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();
      expect(find.text(profile.description!), findsOneWidget);
    });
    testWidgets('Show age', (WidgetTester tester) async {
      final Random random = Random();
      if (random.nextBool()) SupabaseManager.setCurrentProfile(ProfileFactory().generateFake(id: 2));
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();
      expect(find.text(profile.age.toString()), findsOneWidget);
    });
    testWidgets('Show gender', (WidgetTester tester) async {
      final Random random = Random();
      if (random.nextBool()) SupabaseManager.setCurrentProfile(ProfileFactory().generateFake(id: 2));
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();
      final genderFinder = find.byKey(const Key('genderText'));
      expect(genderFinder, findsOneWidget);
    });
    testWidgets('Show features', (WidgetTester tester) async {
      final Random random = Random();
      if (random.nextBool()) SupabaseManager.setCurrentProfile(ProfileFactory().generateFake(id: 2));
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();
      final scrollableFinder = find.byType(Scrollable).first;
      expect(scrollableFinder, findsOneWidget);
      //for (final Feature feature in profile.features!) {
      //  final featureFinder = find.text(feature.name);
      //  tester.scrollUntilVisible(featureFinder, 100, scrollable: scrollableFinder);
      //  expect(featureFinder, findsOneWidget);
      //}
    });
    testWidgets('Show review', (WidgetTester tester) async {
      final Random random = Random();
      if (random.nextBool()) SupabaseManager.setCurrentProfile(ProfileFactory().generateFake(id: 2));
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();
      expect(find.byKey(const Key('reviewsPreview')), findsOneWidget);
    });
    // todo: does not show anything if no details
    testWidgets('not currentUser no details', (WidgetTester tester) async {
      final Profile profile = ProfileFactory().generateFake(
        id: 1,
        surname: NullableParameter(null),
        name: NullableParameter(null),
        description: NullableParameter(null),
        gender: NullableParameter(null),
        birthDate: NullableParameter(null),
        profileFeatures: [],
      );
      SupabaseManager.setCurrentProfile(ProfileFactory().generateFake(id: 2));
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();
      expect(find.byKey(const Key('fullName')), findsNothing);
      expect(find.byKey(const Key('description')), findsNothing);
      expect(find.byKey(const Key('age')), findsNothing);
      expect(find.byKey(const Key('gender')), findsNothing);
      expect(find.byKey(const Key('features')), findsNothing);
    });
    //todo: find no info text 5 times
    testWidgets('currentUser no details', (WidgetTester tester) async {
      profile = ProfileFactory().generateFake(
          id: 1,
          surname: NullableParameter(null),
          name: NullableParameter(null),
          description: NullableParameter(null),
          gender: NullableParameter(null),
          birthDate: NullableParameter(null),
          profileFeatures: []);
      SupabaseManager.setCurrentProfile(profile);
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();
      expect(find.byKey(const Key('noInfoText')), findsNWidgets(5));
    });
  });
  group('Buttons', () {
    testWidgets('not currentUser buttons', (WidgetTester tester) async {
      SupabaseManager.setCurrentProfile(ProfileFactory().generateFake(id: 2));
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();
      expect(find.byIcon(Icons.edit), findsNothing);
      expect(find.byKey(const Key('AvatarUpload')), findsNothing);
      expect(find.byKey(const Key('signOutButton')), findsNothing);
    });
    testWidgets('currentUser buttons', (WidgetTester tester) async {
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();
      expect(find.byIcon(Icons.edit), findsNWidgets(6));
      expect(find.byKey(const Key('AvatarUpload')), findsOneWidget);
      expect(find.byKey(const Key('signOutButton')), findsOneWidget);
      expect(find.byKey(const Key('reportButton')), findsNothing);
      expect(find.byKey(const Key('disabledReportButton')), findsNothing);
    });
    //todo: tap signout process
    testWidgets('Sign out button', (WidgetTester tester) async {
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();
      await tester.tap(find.byKey(const Key('signOutButton')));
      await tester.pumpAndSettle();
      expect(find.byType(WelcomePage), findsOneWidget);
    });
    testWidgets('Avatar is tappable', (WidgetTester tester) async {
      final Random random = Random();
      random.nextBool()
          ? SupabaseManager.setCurrentProfile(profile)
          : SupabaseManager.setCurrentProfile(ProfileFactory().generateFake(id: 2));
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();
      final Finder avatar = find.byKey(const Key('AvatarTappable'));
      expect(avatar, findsOneWidget);
      await tester.tap(avatar);
      await tester.pumpAndSettle();
      expect(find.byType(AvatarPicturePage), findsOneWidget);
    });
    // todo: upload avatar and what is avatar is null
    testWidgets('Edit avatar button', (WidgetTester tester) async {
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();
      await tester.tap(find.byKey(const Key('AvatarUpload')));
      await tester.pumpAndSettle();
      expect(find.byType(SimpleDialog), findsOneWidget);
    });
    testWidgets('Edit username button', (WidgetTester tester) async {
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.edit).first);
      await tester.pumpAndSettle();
      expect(find.byType(EditUsernamePage), findsOneWidget);
    });
    testWidgets('Edit full name button', (WidgetTester tester) async {
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.edit).at(1));
      await tester.pumpAndSettle();
      expect(find.byType(EditFullNamePage), findsOneWidget);
    });
    testWidgets('Edit description button', (WidgetTester tester) async {
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.edit).at(2));
      await tester.pumpAndSettle();
      expect(find.byType(EditDescriptionPage), findsOneWidget);
    });
    testWidgets('Edit age button', (WidgetTester tester) async {
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.edit).at(3));
      await tester.pumpAndSettle();
      expect(find.byType(EditBirthDatePage), findsOneWidget);
    });
    testWidgets('Edit gender button', (WidgetTester tester) async {
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.edit).at(4));
      await tester.pumpAndSettle();
      expect(find.byType(EditGenderPage), findsOneWidget);
    });
    //todo: edit features navigation
    testWidgets('Edit features button', (WidgetTester tester) async {
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.edit).last);
      await tester.pumpAndSettle();
      expect(find.byType(EditProfileFeaturesPage), findsOneWidget);
    });
    //todo: navigation to reviews page
    testWidgets('Reviews button', (WidgetTester tester) async {
      final Random random = Random();
      if (random.nextBool()) SupabaseManager.setCurrentProfile(ProfileFactory().generateFake(id: 2));
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();
      await tester.tap(find.byKey(const Key('reviewsPreview')));
      await tester.pumpAndSettle();
      expect(find.byType(ReviewsPage), findsOneWidget);
    });
    //todo: navigation to reports page
    testWidgets('Report button', (WidgetTester tester) async {
      profile = ProfileFactory().generateFake(id: 1, reportsReceived: [
        ReportFactory().generateFake(
            createdAt: DateTime.now().subtract(const Duration(days: 4)),
            reporterId: 2,
            offenderId: 1,
            createDependencies: false),
        ReportFactory().generateFake(reporterId: 3, offenderId: 1, createDependencies: false)
      ]);
      SupabaseManager.setCurrentProfile(ProfileFactory().generateFake(id: 2));
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();
      expect(find.byKey(const Key('disabledReportButton')), findsNothing);
      final reportFinder = find.byKey(const Key('reportButton'));
      expect(reportFinder, findsOneWidget);
      await tester.tap(reportFinder);
      await tester.pumpAndSettle();
      expect(find.byType(WriteReportPage), findsOneWidget);
    });
    //todo: disable report button
    testWidgets('Disabled report button', (WidgetTester tester) async {
      SupabaseManager.setCurrentProfile(ProfileFactory().generateFake(id: 2));
      profile = ProfileFactory().generateFake(id: 1, reportsReceived: [
        ReportFactory().generateFake(createdAt: DateTime.now(), reporterId: 2, offenderId: 1, createDependencies: false)
      ]);
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();
      expect(find.byKey(const Key('reportButton')), findsNothing);
      final disabledreportFinder = find.byKey(const Key('disabledReportButton'));
      expect(disabledreportFinder, findsOneWidget);
      await tester.tap(disabledreportFinder);
      await tester.pumpAndSettle();
      //expect(find.byType(WriteReportPage), findsOneWidget);
    });
  });
}
