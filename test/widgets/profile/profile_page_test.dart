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
import 'package:motis_mitfahr_app/account/pages/write_report_page.dart';
import 'package:motis_mitfahr_app/account/widgets/avatar.dart';
import 'package:motis_mitfahr_app/account/widgets/reviews_preview.dart';
import 'package:motis_mitfahr_app/util/supabase_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../util/factories/model_factory.dart';
import '../../util/factories/profile_factory.dart';
import '../../util/factories/report_factory.dart';
import '../../util/mocks/mock_server.dart';
import '../../util/mocks/request_processor.dart';
import '../../util/mocks/request_processor.mocks.dart';
import '../../util/pump_material.dart';

void main() {
  Profile profile = ProfileFactory().generateFake(id: 1);
  final MockRequestProcessor processor = MockRequestProcessor();
  const String email = 'motismitfahrapp@gmail.com';
  const String authId = '123';

  setUpAll(() async {
    MockServer.setProcessor(processor);
  });

  setUp(() async {
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

    whenRequest(processor, urlMatcher: startsWith('/rest/v1/profiles'), methodMatcher: equals('GET'))
        .thenReturnJson(profile.toJsonForApi());

    whenRequest(processor, urlMatcher: equals('/auth/v1/logout?')).thenReturnJson('');
  });

  group('constructors', () {
    group('currentProfile', () {
      testWidgets('Works with id parameter', (WidgetTester tester) async {
        await pumpMaterial(tester, ProfilePage(profile.id!));
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        await tester.pump();

        // you see it once in the AppBar and once in the body
        expect(find.text(profile.username), findsNWidgets(2));
      });

      testWidgets('Works with object parameter', (WidgetTester tester) async {
        await pumpMaterial(tester, ProfilePage.fromProfile(profile));
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await tester.pump();

        expect(find.text(profile.username), findsNWidgets(2));
      });
    });

    group('not currentProfile', () {
      setUp(() {
        supabaseManager.currentProfile = ProfileFactory().generateFake(id: 2);
      });

      testWidgets('Works with id parameter', (WidgetTester tester) async {
        await pumpMaterial(tester, ProfilePage(profile.id!));
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        await tester.pump();

        // you see it once in the AppBar and once in the body
        expect(find.text(profile.username), findsNWidgets(2));
      });

      testWidgets('Works with object parameter', (WidgetTester tester) async {
        await pumpMaterial(tester, ProfilePage.fromProfile(profile));
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await tester.pump();

        expect(find.text(profile.username), findsNWidgets(2));
      });
    });
  });

  group('Profile content', () {
    testWidgets('Own profile', (WidgetTester tester) async {
      supabaseManager.currentProfile = profile;

      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();

      expect(
          find.descendant(of: find.byType(Avatar), matching: find.byKey(const Key('avatarTappable'))), findsOneWidget);
      expect(find.text(profile.username), findsNWidgets(2));
      expect(find.text(profile.email), findsOneWidget);
      expect(find.text(profile.fullName), findsAtLeastNWidgets(1));
      expect(find.text(profile.description!), findsOneWidget);
      expect(find.text(profile.age.toString()), findsOneWidget);
      expect(find.byKey(const Key('gender')), findsOneWidget);

      final scrollableFinder = find.byType(Scrollable).first;
      expect(scrollableFinder, findsOneWidget);

      for (int h = 0; h < profile.features!.length; h++) {
        final feature = profile.features![h];
        final featureFinder = find.byKey(Key('feature_${feature.name}'));
        await tester.scrollUntilVisible(featureFinder, 500, scrollable: scrollableFinder);
        expect(featureFinder, findsOneWidget);
      }

      expect(find.descendant(of: find.byKey(const Key('features')), matching: find.byType(ListTile)),
          findsNWidgets(profile.features!.length));

      expect(find.byType(ReviewsPreview), findsOneWidget);
    });

    testWidgets('Other profile', (WidgetTester tester) async {
      supabaseManager.currentProfile = ProfileFactory().generateFake(id: 2);

      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();

      expect(
          find.descendant(of: find.byType(Avatar), matching: find.byKey(const Key('avatarTappable'))), findsOneWidget);
      expect(find.text(profile.username), findsNWidgets(2));
      expect(find.text(profile.email), findsNothing);
      expect(find.text(profile.fullName), findsAtLeastNWidgets(1));
      expect(find.text(profile.description!), findsOneWidget);
      expect(find.text(profile.age.toString()), findsOneWidget);
      expect(find.byKey(const Key('gender')), findsOneWidget);

      final scrollableFinder = find.byType(Scrollable).first;
      expect(scrollableFinder, findsOneWidget);

      for (int h = 0; h < profile.features!.length; h++) {
        final feature = profile.features![h];
        final featureFinder = find.byKey(Key('feature_${feature.name}'));
        await tester.scrollUntilVisible(featureFinder, 500, scrollable: scrollableFinder);
        expect(featureFinder, findsOneWidget);
      }

      expect(find.descendant(of: find.byKey(const Key('features')), matching: find.byType(ListTile)),
          findsNWidgets(profile.features!.length));

      expect(find.byType(ReviewsPreview), findsOneWidget);
    });

    testWidgets('not currentUser no details', (WidgetTester tester) async {
      supabaseManager.currentProfile = ProfileFactory().generateFake(id: 2);

      profile = ProfileFactory().generateFake(
          id: 1,
          surname: NullableParameter(null),
          name: NullableParameter(null),
          description: NullableParameter(null),
          gender: NullableParameter(null),
          birthDate: NullableParameter(null),
          profileFeatures: [],
          createDependencies: false);

      whenRequest(
        processor,
        urlMatcher: startsWith('/rest/v1/profiles'),
        methodMatcher: equals('GET'),
      ).thenReturnJson(profile.toJsonForApi());

      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();

      expect(find.byKey(const Key('fullName')), findsNothing);
      expect(find.byKey(const Key('description')), findsNothing);
      expect(find.byKey(const Key('age')), findsNothing);
      expect(find.byKey(const Key('gender')), findsNothing);
      expect(find.byKey(const Key('features')), findsNothing);
    });

    testWidgets('currentUser no details', (WidgetTester tester) async {
      profile = ProfileFactory().generateFake(
          id: 1,
          surname: NullableParameter(null),
          name: NullableParameter(null),
          description: NullableParameter(null),
          gender: NullableParameter(null),
          birthDate: NullableParameter(null),
          profileFeatures: []);

      whenRequest(
        processor,
        urlMatcher: startsWith('/rest/v1/profiles'),
        methodMatcher: equals('GET'),
      ).thenReturnJson(profile.toJsonForApi());

      supabaseManager.currentProfile = profile;

      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();

      expect(find.byKey(const Key('noInfoText')), findsNWidgets(5));
    });
  });

  group('Buttons', () {
    testWidgets('not currentUser buttons', (WidgetTester tester) async {
      supabaseManager.currentProfile = ProfileFactory().generateFake(id: 2);

      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();

      expect(find.byKey(const Key('editableRowIconButton')), findsNothing);
      expect(find.byKey(const Key('editableRowTitleButton')), findsNothing);
      expect(find.byKey(const Key('editableRowInnerButton')), findsNothing);
      expect(find.byKey(const Key('editUsernameIcon')), findsNothing);
      expect(find.byKey(const Key('editUsernameText')), findsNothing);
      expect(find.byKey(const Key('avatarUpload')), findsNothing);
      expect(find.byKey(const Key('signOutButton')), findsNothing);
    });

    testWidgets('currentUser buttons', (WidgetTester tester) async {
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();

      expect(find.byKey(const Key('editableRowIconButton')), findsNWidgets(5));
      expect(find.byKey(const Key('editableRowTitleButton')), findsNWidgets(5));
      expect(find.byKey(const Key('editableRowInnerButton')), findsNWidgets(5));
      expect(find.byKey(const Key('editUsernameIcon')), findsOneWidget);
      expect(find.byKey(const Key('editUsernameText')), findsOneWidget);
      expect(find.byKey(const Key('avatarUpload')), findsOneWidget);
      expect(find.byKey(const Key('signOutButton')), findsOneWidget);
      expect(find.byKey(const Key('reportButton')), findsNothing);
      expect(find.byKey(const Key('disabledReportButton')), findsNothing);
    });

    testWidgets('Sign out button', (WidgetTester tester) async {
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();

      await tester.tap(find.byKey(const Key('signOutButton')));
      await tester.pumpAndSettle();

      verifyRequest(processor, urlMatcher: equals('/auth/v1/logout?')).called(1);
    });

    // run for both current and other profile
    for (int i = 0; i < 2; i++) {
      i == 0
          ? supabaseManager.currentProfile = profile
          : supabaseManager.currentProfile = ProfileFactory().generateFake(id: 2);

      testWidgets('Avatar is tappable $i', (WidgetTester tester) async {
        whenRequest(
          processor,
          urlMatcher: startsWith('/rest/v1/profiles'),
        ).thenReturnJson(profile.toJsonForApi());
        whenRequest(
          processor,
          urlMatcher: startsWith('/rest/v1/rides'),
        ).thenReturnJson([]);

        await pumpMaterial(tester, ProfilePage.fromProfile(profile));
        await tester.pump();

        await tester.tap(find.byKey(const Key('avatarTappable')));
        await tester.pumpAndSettle();

        expect(find.byType(AvatarPicturePage), findsOneWidget);
      });
    }

    testWidgets('Edit username button', (WidgetTester tester) async {
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();

      await tester.tap(find.byKey(const Key('editUsernameIcon')));
      await tester.pumpAndSettle();

      expect(find.byType(EditUsernamePage), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('editUsernameText')));
      await tester.pumpAndSettle();

      expect(find.byType(EditUsernamePage), findsOneWidget);
    });

    testWidgets('Edit full name button', (WidgetTester tester) async {
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();

      await tester.tap(find.descendant(
          of: find.byKey(const Key('fullName')), matching: find.byKey(const Key('editableRowIconButton'))));
      await tester.pumpAndSettle();

      expect(find.byType(EditFullNamePage), findsOneWidget);

      await tester.pageBack();
      await tester.pump();

      await tester.tap(find.descendant(
          of: find.byKey(const Key('fullName')), matching: find.byKey(const Key('editableRowTitleButton'))));
      await tester.pumpAndSettle();

      expect(find.byType(EditFullNamePage), findsOneWidget);

      await tester.pageBack();
      await tester.pump();

      await tester.tap(find.descendant(
          of: find.byKey(const Key('fullName')), matching: find.byKey(const Key('editableRowInnerButton'))));
      await tester.pumpAndSettle();

      expect(find.byType(EditFullNamePage), findsOneWidget);
    });

    testWidgets('Edit description button', (WidgetTester tester) async {
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();

      await tester.tap(find.descendant(
          of: find.byKey(const Key('description')), matching: find.byKey(const Key('editableRowIconButton'))));
      await tester.pumpAndSettle();

      expect(find.byType(EditDescriptionPage), findsOneWidget);
    });

    testWidgets('Edit age button', (WidgetTester tester) async {
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();

      await tester.tap(
          find.descendant(of: find.byKey(const Key('age')), matching: find.byKey(const Key('editableRowIconButton'))));
      await tester.pumpAndSettle();

      expect(find.byType(EditBirthDatePage), findsOneWidget);
    });

    testWidgets('Edit gender button', (WidgetTester tester) async {
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();

      await tester.tap(find.descendant(
          of: find.byKey(const Key('gender')), matching: find.byKey(const Key('editableRowIconButton'))));
      await tester.pumpAndSettle();

      expect(find.byType(EditGenderPage), findsOneWidget);
    });

    testWidgets('Edit features button', (WidgetTester tester) async {
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();

      final Finder editFeaturesButton = find.descendant(
          of: find.byKey(const Key('features')), matching: find.byKey(const Key('editableRowIconButton')));
      await tester.scrollUntilVisible(editFeaturesButton, 100, scrollable: find.byType(Scrollable).first);
      await tester.tap(editFeaturesButton);
      await tester.pumpAndSettle();

      expect(find.byType(EditProfileFeaturesPage), findsOneWidget);
    });

    testWidgets('Report button', (WidgetTester tester) async {
      supabaseManager.currentProfile = ProfileFactory().generateFake(id: 2);

      profile = ProfileFactory().generateFake(id: 1, reportsReceived: [
        ReportFactory().generateFake(
            createdAt: DateTime.now().subtract(const Duration(days: 4)),
            reporterId: 2,
            offenderId: 1,
            createDependencies: false),
        ReportFactory().generateFake(reporterId: 3, offenderId: 1, createDependencies: false)
      ]);

      whenRequest(
        processor,
        urlMatcher: startsWith('/rest/v1/profiles'),
        methodMatcher: equals('GET'),
      ).thenReturnJson(profile.toJsonForApi());

      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();

      final reportFinder = find.byKey(const Key('reportButton'));
      await tester.scrollUntilVisible(reportFinder, 100, scrollable: find.byType(Scrollable).first);
      expect(reportFinder, findsOneWidget);

      expect(find.byKey(const Key('disabledReportButton')), findsNothing);

      await tester.tap(reportFinder);
      await tester.pumpAndSettle();

      expect(find.byType(WriteReportPage), findsOneWidget);
    });

    testWidgets('Disabled report button', (WidgetTester tester) async {
      supabaseManager.currentProfile = ProfileFactory().generateFake(id: 2);

      profile = ProfileFactory().generateFake(id: 1, reportsReceived: [
        ReportFactory().generateFake(
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
            reporterId: 2,
            offenderId: 1,
            createDependencies: false)
      ]);

      whenRequest(
        processor,
        urlMatcher: startsWith('/rest/v1/profiles'),
        methodMatcher: equals('GET'),
      ).thenReturnJson(profile.toJsonForApi());

      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();

      final disabledReportFinder = find.byKey(const Key('disabledReportButton'));
      await tester.scrollUntilVisible(disabledReportFinder, 100, scrollable: find.byType(Scrollable).first);
      expect(find.byKey(const Key('reportButton')), findsNothing);

      expect(disabledReportFinder, findsOneWidget);

      await tester.tap(disabledReportFinder);
      await tester.pumpAndSettle();
      expect(find.byType(ProfilePage), findsOneWidget);
    });
  });
  testWidgets('Accessibility', (WidgetTester tester) async {
    await expectMeetsAccessibilityGuidelines(tester, ProfilePage.fromProfile(profile));
  });
}
