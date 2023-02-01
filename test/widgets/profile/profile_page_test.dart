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
import 'package:motis_mitfahr_app/account/widgets/avatar.dart';
import 'package:motis_mitfahr_app/util/supabase.dart';
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

  setUp(() {
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
    whenRequest(processor,
            urlMatcher: equals(
                '/rest/v1/profiles?select=%2A%2Cprofile_features%28%2A%29%2Creviews_received%3Areviews%21reviews_receiver_id_fkey%28%2A%2Cwriter%3Awriter_id%28%2A%29%29%2Creports_received%3Areports%21reports_offender_id_fkey%28%2A%29&id=eq.1'))
        .thenReturnJson(profile.toJsonForApi());
    whenRequest(processor,
            urlMatcher: equals(
                '/rest/v1/profiles?select=%2A%2Creviews_received%3Areviews%21reviews_receiver_id_fkey%28%2A%2Cwriter%3Awriter_id%28%2A%29%29&id=eq.1'))
        .thenReturnJson(profile.toJsonForApi());
    whenRequest(processor,
            urlMatcher: equals(
                '/rest/v1/rides?select=%2A%2Cdrive%3Adrives%21inner%28%2A%29&rider_id=eq.1&drive.driver_id=eq.1'))
        .thenReturnJson([]);
    whenRequest(processor, urlMatcher: equals('/auth/v1/logout?')).thenReturnJson('');
  });

  group('constructors', () {
    // run for both own and other profile
    for (int i = 0; i < 2; i++) {
      i == 0
          ? SupabaseManager.setCurrentProfile(profile)
          : SupabaseManager.setCurrentProfile(ProfileFactory().generateFake(id: 2));
      testWidgets('Works with id parameter', (WidgetTester tester) async {
        // load page
        await pumpMaterial(tester, ProfilePage(profile.id!));

        // check if loading indicator is shown
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        //finish loading
        await tester.pump();

        // check if page is loaded
        expect(find.text(profile.username), findsNWidgets(2));
      });
      testWidgets('Works with object parameter', (WidgetTester tester) async {
        // load page
        await pumpMaterial(tester, ProfilePage.fromProfile(profile));

        // check if loading indicator is shown
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        //finish loading
        await tester.pump();

        // check if page is loaded
        expect(find.text(profile.username), findsNWidgets(2));
      });
    }
  });
  group('Profile content', () {
    // run for both own and other profile
    for (int i = 0; i < 2; i++) {
      i == 0
          ? SupabaseManager.setCurrentProfile(profile)
          : SupabaseManager.setCurrentProfile(ProfileFactory().generateFake(id: 2));

      testWidgets('avatar$i', (WidgetTester tester) async {
        // load page
        await pumpMaterial(tester, ProfilePage.fromProfile(profile));
        await tester.pump();

        // check if avatar is shown
        expect(find.descendant(of: find.byType(Avatar), matching: find.byKey(const Key('avatarTappable'))),
            findsOneWidget);
      });
      testWidgets('username$i', (WidgetTester tester) async {
        // load page
        await pumpMaterial(tester, ProfilePage.fromProfile(profile));
        await tester.pump();

        // check if username is shown
        expect(find.text(profile.username), findsNWidgets(2));
      });
      testWidgets('fullName$i', (WidgetTester tester) async {
        // load page
        await pumpMaterial(tester, ProfilePage.fromProfile(profile));
        await tester.pump();

        // check if fullName is shown
        expect(find.text(profile.fullName), findsAtLeastNWidgets(1));
      });
      testWidgets('description$i', (WidgetTester tester) async {
        // load page
        await pumpMaterial(tester, ProfilePage.fromProfile(profile));
        await tester.pump();

        // check if description is shown
        expect(find.text(profile.description!), findsOneWidget);
      });
      testWidgets('age$i', (WidgetTester tester) async {
        // load page
        await pumpMaterial(tester, ProfilePage.fromProfile(profile));
        await tester.pump();

        // check if age is shown
        expect(find.text(profile.age.toString()), findsOneWidget);
      });
      testWidgets('gender$i', (WidgetTester tester) async {
        // load page
        await pumpMaterial(tester, ProfilePage.fromProfile(profile));
        await tester.pump();

        // check if gender is shown
        final genderFinder = find.byKey(const Key('gender'));
        expect(genderFinder, findsOneWidget);
      });
      testWidgets('features$i', (WidgetTester tester) async {
        // load page
        await pumpMaterial(tester, ProfilePage.fromProfile(profile));
        await tester.pump();

        // check if scrollable is found
        final scrollableFinder = find.byType(Scrollable).first;
        expect(scrollableFinder, findsOneWidget);

        // check if features are shown
        for (int h = 0; h < profile.features!.length; h++) {
          final feature = profile.features![h];
          final featureFinder = find.byKey(Key('feature_${feature.name}'));
          await tester.scrollUntilVisible(featureFinder, 500, scrollable: scrollableFinder);
          expect(featureFinder, findsOneWidget);
        }
      });
      testWidgets('review$i', (WidgetTester tester) async {
        // load page
        await pumpMaterial(tester, ProfilePage.fromProfile(profile));
        await tester.pump();

        // check if review is shown
        expect(find.byKey(const Key('reviewsPreview')), findsOneWidget);
      });
    }
    testWidgets('currentUser email', (WidgetTester tester) async {
      // load page
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();

      // check if email is shown
      expect(find.text(profile.email), findsOneWidget);
    });
    testWidgets('not currentUser email', (WidgetTester tester) async {
      // set other profile as current
      SupabaseManager.setCurrentProfile(ProfileFactory().generateFake(id: 2));

      // load page
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();

      // check if email is not shown
      expect(find.text(profile.email), findsNothing);
    });
    testWidgets('not currentUser no details', (WidgetTester tester) async {
      // set other profile as current
      SupabaseManager.setCurrentProfile(ProfileFactory().generateFake(id: 2));

      // create profile without details
      profile = ProfileFactory().generateFake(
          id: 1,
          surname: NullableParameter(null),
          name: NullableParameter(null),
          description: NullableParameter(null),
          gender: NullableParameter(null),
          birthDate: NullableParameter(null),
          profileFeatures: [],
          createDependencies: false);

      // declare that the request will return the new profile
      whenRequest(processor,
              urlMatcher: equals(
                  '/rest/v1/profiles?select=%2A%2Cprofile_features%28%2A%29%2Creviews_received%3Areviews%21reviews_receiver_id_fkey%28%2A%2Cwriter%3Awriter_id%28%2A%29%29%2Creports_received%3Areports%21reports_offender_id_fkey%28%2A%29&id=eq.1'))
          .thenReturnJson(profile.toJsonForApi());

      // load page
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();

      // check if details are not shown
      expect(find.byKey(const Key('fullName')), findsNothing);
      expect(find.byKey(const Key('description')), findsNothing);
      expect(find.byKey(const Key('age')), findsNothing);
      expect(find.byKey(const Key('gender')), findsNothing);
      expect(find.byKey(const Key('features')), findsNothing);
    });
    testWidgets('currentUser no details', (WidgetTester tester) async {
      // create profile without details
      profile = ProfileFactory().generateFake(
          id: 1,
          surname: NullableParameter(null),
          name: NullableParameter(null),
          description: NullableParameter(null),
          gender: NullableParameter(null),
          birthDate: NullableParameter(null),
          profileFeatures: []);

      // declare that the request will return the new profile
      whenRequest(processor,
              urlMatcher: equals(
                  '/rest/v1/profiles?select=%2A%2Cprofile_features%28%2A%29%2Creviews_received%3Areviews%21reviews_receiver_id_fkey%28%2A%2Cwriter%3Awriter_id%28%2A%29%29%2Creports_received%3Areports%21reports_offender_id_fkey%28%2A%29&id=eq.1'))
          .thenReturnJson(profile.toJsonForApi());

      // set profile as current
      SupabaseManager.setCurrentProfile(profile);

      // load page
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();

      // check if details placeholders are shown
      expect(find.byKey(const Key('noInfoText')), findsNWidgets(5));
    });
  });
  group('Buttons', () {
    testWidgets('not currentUser buttons', (WidgetTester tester) async {
      // set other profile as current
      SupabaseManager.setCurrentProfile(ProfileFactory().generateFake(id: 2));

      // load page
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();

      // check if edit buttons are not shown
      expect(find.byKey(const Key('editButton')), findsNothing);
      expect(find.byKey(const Key('editUsername')), findsNothing);
      expect(find.byKey(const Key('avatarUpload')), findsNothing);
      expect(find.byKey(const Key('signOutButton')), findsNothing);
    });
    testWidgets('currentUser buttons', (WidgetTester tester) async {
      //load page
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();

      // check if edit buttons are shown
      expect(find.byKey(const Key('editButton')), findsNWidgets(5));
      expect(find.byKey(const Key('editUsername')), findsOneWidget);
      expect(find.byKey(const Key('avatarUpload')), findsOneWidget);
      expect(find.byKey(const Key('signOutButton')), findsOneWidget);
      expect(find.byKey(const Key('reportButton')), findsNothing);
      expect(find.byKey(const Key('disabledReportButton')), findsNothing);
    });
    testWidgets('Sign out button', (WidgetTester tester) async {
      // sign in
      await SupabaseManager.supabaseClient.auth.signInWithPassword(
        email: email,
        password: authId,
      );

      //load page
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();

      // tap sign out button
      await tester.tap(find.byKey(const Key('signOutButton')));
      await tester.pumpAndSettle();

      // check if sign out request is sent
      expect(verifyRequest(processor, urlMatcher: equals('/auth/v1/logout?')).callCount, 1);
    });

    // run for both current and other profile
    for (int i = 0; i < 2; i++) {
      i == 0
          ? SupabaseManager.setCurrentProfile(profile)
          : SupabaseManager.setCurrentProfile(ProfileFactory().generateFake(id: 2));
      testWidgets('Avatar is tappable $i', (WidgetTester tester) async {
        //load page
        await pumpMaterial(tester, ProfilePage.fromProfile(profile));
        await tester.pump();

        //check if avatar is displayed
        final Finder avatar = find.byKey(const Key('avatarTappable'));
        expect(avatar, findsOneWidget);

        //tap avatar
        await tester.tap(avatar);
        await tester.pumpAndSettle();

        //check if avatar page is displayed
        expect(find.byType(AvatarPicturePage), findsOneWidget);
      });
      testWidgets('Reviews button $i', (WidgetTester tester) async {
        //load page
        await pumpMaterial(tester, ProfilePage.fromProfile(profile));
        await tester.pump();

        //check if reviewPreview is tappable
        final reviewFinder = find.byKey(const Key('reviewsPreview'));
        await tester.scrollUntilVisible(reviewFinder, 100, scrollable: find.byType(Scrollable).first);
        await tester.tap(reviewFinder);
        await tester.pumpAndSettle();

        //check if reviews page is displayed
        expect(find.byType(ReviewsPage), findsOneWidget);
      });
    }
    testWidgets('Edit username button', (WidgetTester tester) async {
      //load page
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();

      //tap edit username button
      await tester.tap(find.byKey(const Key('editUsername')));
      await tester.pumpAndSettle();

      //check if edit username page is displayed
      expect(find.byType(EditUsernamePage), findsOneWidget);
    });
    testWidgets('Edit full name button', (WidgetTester tester) async {
      //load page
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();

      //tap edit full name button
      await tester
          .tap(find.descendant(of: find.byKey(const Key('fullName')), matching: find.byKey(const Key('editButton'))));
      await tester.pumpAndSettle();

      //check if edit full name page is displayed
      expect(find.byType(EditFullNamePage), findsOneWidget);
    });
    testWidgets('Edit description button', (WidgetTester tester) async {
      //load page
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();

      //tap edit description button
      await tester.tap(
          find.descendant(of: find.byKey(const Key('description')), matching: find.byKey(const Key('editButton'))));
      await tester.pumpAndSettle();

      //check if edit description page is displayed
      expect(find.byType(EditDescriptionPage), findsOneWidget);
    });
    testWidgets('Edit age button', (WidgetTester tester) async {
      //load page
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();

      //tap edit age button
      await tester
          .tap(find.descendant(of: find.byKey(const Key('age')), matching: find.byKey(const Key('editButton'))));
      await tester.pumpAndSettle();

      //check if edit age page is displayed
      expect(find.byType(EditBirthDatePage), findsOneWidget);
    });
    testWidgets('Edit gender button', (WidgetTester tester) async {
      //load page
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();

      //tap edit gender button
      await tester
          .tap(find.descendant(of: find.byKey(const Key('gender')), matching: find.byKey(const Key('editButton'))));
      await tester.pumpAndSettle();

      //check  if edit gender page is displayed
      expect(find.byType(EditGenderPage), findsOneWidget);
    });
    testWidgets('Edit features button', (WidgetTester tester) async {
      //load page
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();

      //tap edit features button
      final Finder editFeaturesButton =
          find.descendant(of: find.byKey(const Key('features')), matching: find.byKey(const Key('editButton')));
      await tester.scrollUntilVisible(editFeaturesButton, 100, scrollable: find.byType(Scrollable).first);
      await tester.tap(editFeaturesButton);
      await tester.pumpAndSettle();

      //check if edit features page is displayed
      expect(find.byType(EditProfileFeaturesPage), findsOneWidget);
    });
    testWidgets('Report button', (WidgetTester tester) async {
      // set current to other profile
      SupabaseManager.setCurrentProfile(ProfileFactory().generateFake(id: 2));

      //create profile with no reports report from current user
      profile = ProfileFactory().generateFake(id: 1, reportsReceived: [
        ReportFactory().generateFake(
            createdAt: DateTime.now().subtract(const Duration(days: 4)),
            reporterId: 2,
            offenderId: 1,
            createDependencies: false),
        ReportFactory().generateFake(reporterId: 3, offenderId: 1, createDependencies: false)
      ]);

      //declare to return profile
      whenRequest(processor,
              urlMatcher: equals(
                  '/rest/v1/profiles?select=%2A%2Cprofile_features%28%2A%29%2Creviews_received%3Areviews%21reviews_receiver_id_fkey%28%2A%2Cwriter%3Awriter_id%28%2A%29%29%2Creports_received%3Areports%21reports_offender_id_fkey%28%2A%29&id=eq.1'))
          .thenReturnJson(profile.toJsonForApi());

      //load page
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();

      //check if report button is displayed
      final reportFinder = find.byKey(const Key('reportButton'));
      await tester.scrollUntilVisible(reportFinder, 100, scrollable: find.byType(Scrollable).first);
      expect(reportFinder, findsOneWidget);

      //check if report button is not disabled
      expect(find.byKey(const Key('disabledReportButton')), findsNothing);

      //tap report button
      await tester.tap(reportFinder);
      await tester.pumpAndSettle();

      //check if write report page is displayed
      expect(find.byType(WriteReportPage), findsOneWidget);
    });
    testWidgets('Disabled report button', (WidgetTester tester) async {
      // set current to other profile
      SupabaseManager.setCurrentProfile(ProfileFactory().generateFake(id: 2));

      //create profile with recent report from current user
      profile = ProfileFactory().generateFake(id: 1, reportsReceived: [
        ReportFactory().generateFake(
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
            reporterId: 2,
            offenderId: 1,
            createDependencies: false)
      ]);

      //declare to return profile
      whenRequest(processor,
              urlMatcher: equals(
                  '/rest/v1/profiles?select=%2A%2Cprofile_features%28%2A%29%2Creviews_received%3Areviews%21reviews_receiver_id_fkey%28%2A%2Cwriter%3Awriter_id%28%2A%29%29%2Creports_received%3Areports%21reports_offender_id_fkey%28%2A%29&id=eq.1'))
          .thenReturnJson(profile.toJsonForApi());

      //load page
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();

      //check if report button is not displayed
      final disabledreportFinder = find.byKey(const Key('disabledReportButton'));
      await tester.scrollUntilVisible(disabledreportFinder, 100, scrollable: find.byType(Scrollable).first);
      expect(find.byKey(const Key('reportButton')), findsNothing);

      //check if report button is disabled
      expect(disabledreportFinder, findsOneWidget);

      //check if after tap nothing happens
      await tester.tap(disabledreportFinder);
      await tester.pumpAndSettle();
      expect(find.byType(ProfilePage), findsOneWidget);
    });
  });
}
