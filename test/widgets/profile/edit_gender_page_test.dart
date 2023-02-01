import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/account/pages/edit_account/edit_gender_page.dart';
import 'package:motis_mitfahr_app/account/pages/profile_page.dart';
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
    whenRequest(processor, urlMatcher: contains('/rest/v1/profiles')).thenReturnJson(profile.toJsonForApi());
  });
  group('edit_gender_page', () {
    testWidgets('display genderRadioListTile', (WidgetTester tester) async {
      //load page
      await pumpMaterial(tester, EditGenderPage(profile));
      await tester.pump();
      //check if male is displayed
      final maleGenderFinder = find.byKey(const Key('genderRadioListTile0'));
      expect(maleGenderFinder, findsOneWidget);

      //check if female is displayed
      final femaleGenderFinder = find.byKey(const Key('genderRadioListTile1'));
      expect(femaleGenderFinder, findsOneWidget);

      //check if diverse is displayed
      final diverseGenderFinder = find.byKey(const Key('genderRadioListTile2'));
      expect(diverseGenderFinder, findsOneWidget);

      //check if preferNotToSay is displayed
      final preferNotToSayGenderFinder = find.byKey(const Key('preferNotToSayGenderRadioListTile'));
      expect(preferNotToSayGenderFinder, findsOneWidget);
    });
    // don't know to test what I have selected
    testWidgets('change gender', (WidgetTester tester) async {
      // load page
      await pumpMaterial(tester, EditGenderPage(profile));
      await tester.pump();

      //tap male
      final maleGenderFinder = find.byKey(const Key('genderRadioListTile0'));
      await tester.tap(maleGenderFinder);
      await tester.pump();

      //check if male is selected

      //tap female
      final femaleGenderFinder = find.byKey(const Key('genderRadioListTile1'));
      await tester.tap(femaleGenderFinder);
      await tester.pump();

      //check if female is selected

      //expect(selected, Gender.female)
    });
    testWidgets('save Button', (WidgetTester tester) async {
      //sign in
      SupabaseManager.supabaseClient.auth.signInWithPassword(
        email: email,
        password: authId,
      );

      //load page
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();

      //load EditGenderPage
      await tester
          .tap(find.descendant(of: find.byKey(const Key('gender')), matching: find.byKey(const Key('editButton'))));
      await tester.pumpAndSettle();
      expect(find.byType(EditGenderPage), findsOneWidget);

      //check if save button is displayed
      expect(find.byKey(const Key('saveButton')), findsOneWidget);

      //tap save button
      await tester.tap(find.byKey(const Key('saveButton')));
      await tester.pumpAndSettle();

      //check if ProfilePage is displayed
      expect(find.byType(ProfilePage), findsOneWidget);
    });
  });
}
