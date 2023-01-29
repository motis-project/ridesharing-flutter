import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/account/pages/edit_account/edit_birth_date_page.dart';
import 'package:motis_mitfahr_app/account/pages/edit_account/edit_description_page.dart';
import 'package:motis_mitfahr_app/account/pages/edit_account/edit_full_name_page.dart';
import 'package:motis_mitfahr_app/account/pages/edit_account/edit_gender_page.dart';
import 'package:motis_mitfahr_app/account/pages/edit_account/edit_profile_features_page.dart';
import 'package:motis_mitfahr_app/account/pages/edit_account/edit_username_page.dart';
import 'package:motis_mitfahr_app/account/pages/profile_page.dart';
import 'package:motis_mitfahr_app/account/pages/write_report_page.dart';
import 'package:motis_mitfahr_app/util/supabase.dart';

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

  group('constructors', () {
    testWidgets('Works with id parameter', (WidgetTester tester) async {
      final Random random = Random();
      random.nextBool()
          ? SupabaseManager.setCurrentProfile(profile)
          : SupabaseManager.setCurrentProfile(ProfileFactory().generateFake(id: 2));
      await pumpMaterial(tester, ProfilePage(profile.id!));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pump();
      expect(find.text(profile.username), findsNWidgets(2));
    });
    testWidgets('Works with object parameter', (WidgetTester tester) async {
      final Random random = Random();
      random.nextBool()
          ? SupabaseManager.setCurrentProfile(profile)
          : SupabaseManager.setCurrentProfile(ProfileFactory().generateFake(id: 2));
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pump();

      expect(find.text(profile.username), findsNWidgets(2));
    });
  });
  group('Profile content', () {
    testWidgets('Show username', (WidgetTester tester) async {
      final Random random = Random();
      random.nextBool()
          ? SupabaseManager.setCurrentProfile(profile)
          : SupabaseManager.setCurrentProfile(ProfileFactory().generateFake(id: 2));
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();
      expect(find.text(profile.username), findsNWidgets(2));
    });
    testWidgets('Show email', (WidgetTester tester) async {
      final Random random = Random();
      final bool currentProfile = random.nextBool();
      currentProfile
          ? SupabaseManager.setCurrentProfile(profile)
          : SupabaseManager.setCurrentProfile(ProfileFactory().generateFake(id: 2));
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();
      currentProfile
          ? expect(find.text(profile.email), findsOneWidget)
          : expect(find.text(profile.email), findsNothing);
    });
    testWidgets('Show fullName', (WidgetTester tester) async {
      final Random random = Random();
      random.nextBool()
          ? SupabaseManager.setCurrentProfile(profile)
          : SupabaseManager.setCurrentProfile(ProfileFactory().generateFake(id: 2));
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();
      expect(find.text(profile.fullName), findsAtLeastNWidgets(1));
    });
    testWidgets('Show description', (WidgetTester tester) async {
      final Random random = Random();
      random.nextBool()
          ? SupabaseManager.setCurrentProfile(profile)
          : SupabaseManager.setCurrentProfile(ProfileFactory().generateFake(id: 2));
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();
      expect(find.text(profile.description!), findsOneWidget);
    });
    testWidgets('Show age', (WidgetTester tester) async {
      final Random random = Random();
      random.nextBool()
          ? SupabaseManager.setCurrentProfile(profile)
          : SupabaseManager.setCurrentProfile(ProfileFactory().generateFake(id: 2));
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();
      expect(find.text(profile.age.toString()), findsOneWidget);
    });
    testWidgets('Show gender', (WidgetTester tester) async {
      final Random random = Random();
      random.nextBool()
          ? SupabaseManager.setCurrentProfile(profile)
          : SupabaseManager.setCurrentProfile(ProfileFactory().generateFake(id: 2));
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();
      final genderFinder = find.byKey(const Key('genderText'));
      expect(genderFinder, findsOneWidget);
    });
    testWidgets('Show features', (WidgetTester tester) async {
      final Random random = Random();
      random.nextBool()
          ? SupabaseManager.setCurrentProfile(profile)
          : SupabaseManager.setCurrentProfile(ProfileFactory().generateFake(id: 2));
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
      random.nextBool()
          ? SupabaseManager.setCurrentProfile(profile)
          : SupabaseManager.setCurrentProfile(ProfileFactory().generateFake(id: 2));
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();
    });
    testWidgets('No Content', (WidgetTester tester) async {
      profile = ProfileFactory().generateFake(
          id: 1,
          surname: NullableParameter(null),
          name: NullableParameter(null),
          description: NullableParameter(null),
          gender: NullableParameter(null),
          birthDate: NullableParameter(null),
          profileFeatures: []);
      final Random random = Random();
      random.nextBool()
          ? SupabaseManager.setCurrentProfile(profile)
          : SupabaseManager.setCurrentProfile(ProfileFactory().generateFake(id: 2));
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();
      expect(find.text(profile.fullName), findsNothing);
    });
  });
  group('Buttons', () {
    testWidgets('Sign out button', (WidgetTester tester) async {
      final Random random = Random();
      final bool currentProfile = random.nextBool();
      currentProfile
          ? SupabaseManager.setCurrentProfile(profile)
          : SupabaseManager.setCurrentProfile(ProfileFactory().generateFake(id: 2));
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();
      final signOutButtonFinder = find.byKey(const Key('signOutButton'));
      if (currentProfile) {
        expect(signOutButtonFinder, findsOneWidget);
        //await tester.tap(signOutButtonFinder);
        //await tester.pump();
        //expect(find.byType(WelcomePage).hitTestable(), findsOneWidget);
        //expect(SupabaseManager.getCurrentProfile(), null);
      } else {
        expect(signOutButtonFinder, findsNothing);
      }
    });
    testWidgets('Avatar is tappable', (WidgetTester tester) async {
      final Random random = Random();
      final bool currentProfile = random.nextBool();
      currentProfile
          ? SupabaseManager.setCurrentProfile(profile)
          : SupabaseManager.setCurrentProfile(ProfileFactory().generateFake(id: 2));
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();
      expect(find.byKey(const Key('AvatarTappable')), findsOneWidget);
    });
    testWidgets('Edit avatar button', (WidgetTester tester) async {
      final Random random = Random();
      final bool currentProfile = random.nextBool();
      currentProfile
          ? SupabaseManager.setCurrentProfile(profile)
          : SupabaseManager.setCurrentProfile(ProfileFactory().generateFake(id: 2));
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();
      if (currentProfile) {
        expect(find.byKey(const Key('AvatarUpload')), findsOneWidget);
        //navigate to AvatarUploadPage
      } else {
        expect(find.byKey(const Key('AvatarUpload')), findsNothing);
      }
    });
    testWidgets('Edit username button', (WidgetTester tester) async {
      final Random random = Random();
      final bool currentProfile = random.nextBool();
      currentProfile
          ? SupabaseManager.setCurrentProfile(profile)
          : SupabaseManager.setCurrentProfile(ProfileFactory().generateFake(id: 2));
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();
      final Finder editUsernameFinder = find.byKey(const Key('editUsernameButton'));
      if (currentProfile) {
        expect(editUsernameFinder, findsOneWidget);
        await tester.tap(editUsernameFinder);
        await tester.pumpAndSettle();
        expect(find.byType(EditUsernamePage).hitTestable(), findsOneWidget);
      } else {
        expect(editUsernameFinder, findsNothing);
      }
    });
    testWidgets('Edit fullName button', (WidgetTester tester) async {
      final Random random = Random();
      final bool currentProfile = random.nextBool();
      currentProfile
          ? SupabaseManager.setCurrentProfile(profile)
          : SupabaseManager.setCurrentProfile(ProfileFactory().generateFake(id: 2));
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();
      final editFullNameFinder = find.byKey(const Key('editFullNameButton'));
      if (currentProfile) {
        expect(editFullNameFinder, findsOneWidget);
        await tester.tap(editFullNameFinder);
        await tester.pumpAndSettle();
        expect(find.byType(EditFullNamePage).hitTestable(), findsOneWidget);
      } else {
        expect(editFullNameFinder, findsNothing);
      }
    });
    testWidgets('Edit description button', (WidgetTester tester) async {
      final Random random = Random();
      final bool currentProfile = random.nextBool();
      currentProfile
          ? SupabaseManager.setCurrentProfile(profile)
          : SupabaseManager.setCurrentProfile(ProfileFactory().generateFake(id: 2));
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();
      final editDescriptionFinder = find.byKey(const Key('editDescriptionButton'));
      if (currentProfile) {
        expect(editDescriptionFinder, findsOneWidget);
        await tester.tap(editDescriptionFinder);
        await tester.pumpAndSettle();
        expect(find.byType(EditDescriptionPage).hitTestable(), findsOneWidget);
      } else {
        expect(editDescriptionFinder, findsNothing);
      }
    });
    testWidgets('Edit age button', (WidgetTester tester) async {
      final Random random = Random();
      final bool currentProfile = random.nextBool();
      currentProfile
          ? SupabaseManager.setCurrentProfile(profile)
          : SupabaseManager.setCurrentProfile(ProfileFactory().generateFake(id: 2));
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();
      final editAgeFinder = find.byKey(const Key('editAgeButton'));
      if (currentProfile) {
        expect(editAgeFinder, findsOneWidget);
        await tester.tap(editAgeFinder);
        await tester.pumpAndSettle();
        expect(find.byType(EditBirthDatePage).hitTestable(), findsOneWidget);
      } else {
        expect(editAgeFinder, findsNothing);
      }
    });
    testWidgets('Edit gender button', (WidgetTester tester) async {
      final Random random = Random();
      final bool currentProfile = random.nextBool();
      currentProfile
          ? SupabaseManager.setCurrentProfile(profile)
          : SupabaseManager.setCurrentProfile(ProfileFactory().generateFake(id: 2));
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();
      final editGenderFinder = find.byKey(const Key('editGenderButton'));
      if (currentProfile) {
        expect(editGenderFinder, findsOneWidget);
        await tester.tap(editGenderFinder);
        await tester.pumpAndSettle();
        expect(find.byType(EditGenderPage).hitTestable(), findsOneWidget);
      } else {
        expect(editGenderFinder, findsNothing);
      }
    });
    testWidgets('Edit features button', (WidgetTester tester) async {
      final Random random = Random();
      final bool currentProfile = random.nextBool();
      currentProfile
          ? SupabaseManager.setCurrentProfile(profile)
          : SupabaseManager.setCurrentProfile(ProfileFactory().generateFake(id: 2));
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();
      final editFeaturesFinder = find.byKey(const Key('editFeaturesButton'));
      if (currentProfile) {
        expect(editFeaturesFinder, findsOneWidget);
        await tester.tap(editFeaturesFinder);
        await tester.pumpAndSettle();
        expect(find.byType(EditProfileFeaturesPage).hitTestable(), findsOneWidget);
      } else {
        expect(editFeaturesFinder, findsNothing);
      }
    });
    testWidgets('Reviews button', (WidgetTester tester) async {
      final Random random = Random();
      final bool currentProfile = random.nextBool();
      currentProfile
          ? SupabaseManager.setCurrentProfile(profile)
          : SupabaseManager.setCurrentProfile(ProfileFactory().generateFake(id: 2));
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();
      final reviewsFinder = find.byKey(const Key('reviewsButton'));
      expect(reviewsFinder, findsOneWidget);
    });
    testWidgets('Report button', (WidgetTester tester) async {
      profile = ProfileFactory().generateFake(id: 1, reportsReceived: [ReportFactory().generateFake(reporterId: 3)]);
      final Random random = Random();
      final bool currentProfile = random.nextBool();
      currentProfile
          ? SupabaseManager.setCurrentProfile(profile)
          : SupabaseManager.setCurrentProfile(ProfileFactory().generateFake(id: 2));
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();
      final reportFinder = find.byKey(const Key('reportButton'));
      if (currentProfile) {
        expect(reportFinder, findsNothing);
      } else {
        expect(reportFinder, findsOneWidget);
        await tester.tap(reportFinder);
        await tester.pumpAndSettle();
        expect(find.byType(WriteReportPage).hitTestable(), findsOneWidget);
      }
    });
    testWidgets('Disabled report button', (WidgetTester tester) async {
      profile = ProfileFactory().generateFake(id: 1, reportsReceived: [ReportFactory().generateFake(reporterId: 2)]);
      final Random random = Random();
      final bool currentProfile = random.nextBool();
      currentProfile
          ? SupabaseManager.setCurrentProfile(profile)
          : SupabaseManager.setCurrentProfile(ProfileFactory().generateFake(id: 2));
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();
      final disabledreportFinder = find.byKey(const Key('disabledReportButton'));
      if (currentProfile) {
        expect(disabledreportFinder, findsNothing);
      } else {
        expect(disabledreportFinder, findsOneWidget);
        await tester.tap(disabledreportFinder);
        await tester.pumpAndSettle();
        expect(find.byType(WriteReportPage).hitTestable(), findsNothing);
      }
    });
  });
}
