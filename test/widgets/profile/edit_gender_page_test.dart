import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/account/pages/edit_account/edit_gender_page.dart';
import 'package:motis_mitfahr_app/account/pages/profile_page.dart';
import 'package:motis_mitfahr_app/util/supabase_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../util/factories/model_factory.dart';
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

  setUp(() async {
    profile = ProfileFactory().generateFake(id: 1, gender: NullableParameter(null));
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

    whenRequest(processor, urlMatcher: contains('/rest/v1/profiles')).thenReturnJson(profile.toJsonForApi());
  });

  group('edit_gender_page', () {
    testWidgets('display genderRadioListTile', (WidgetTester tester) async {
      await pumpMaterial(tester, EditGenderPage(profile));

      final maleGenderFinder = find.byKey(const Key('genderRadioListTile0'));
      expect(maleGenderFinder, findsOneWidget);

      final femaleGenderFinder = find.byKey(const Key('genderRadioListTile1'));
      expect(femaleGenderFinder, findsOneWidget);

      final diverseGenderFinder = find.byKey(const Key('genderRadioListTile2'));
      expect(diverseGenderFinder, findsOneWidget);

      final preferNotToSayGenderFinder = find.byKey(const Key('preferNotToSayGenderRadioListTile'));
      expect(preferNotToSayGenderFinder, findsOneWidget);
    });

    group('save Button', () {
      testWidgets('Switching to a gender', (WidgetTester tester) async {
        await pumpMaterial(tester, ProfilePage.fromProfile(profile));
        await tester.pump();
        await tester.tap(
          find.descendant(
              of: find.byKey(const Key('gender')), matching: find.byKey(const Key('editableRowIconButton'))),
        );
        await tester.pumpAndSettle();
        expect(find.byType(EditGenderPage), findsOneWidget);

        await tester.tap(find.byKey(const Key('genderRadioListTile1')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('saveButton')), findsOneWidget);

        await tester.tap(find.byKey(const Key('saveButton')));
        await tester.pumpAndSettle();

        expect(find.byType(ProfilePage), findsOneWidget);

        verifyRequest(
          processor,
          urlMatcher: equals('/rest/v1/profiles?id=eq.1'),
          methodMatcher: equals('PATCH'),
          bodyMatcher: equals({'gender': Gender.female.index}),
        ).called(1);

        verifyRequest(
          processor,
          urlMatcher: startsWith('/rest/v1/profiles'),
          methodMatcher: equals('GET'),
        ).called(3);
      });

      testWidgets('Preferring not to say', (WidgetTester tester) async {
        profile = ProfileFactory().generateFake(id: 1, gender: NullableParameter(Gender.male));
        supabaseManager.currentProfile = profile;
        whenRequest(processor).thenReturnJson(profile.toJsonForApi());

        await pumpMaterial(tester, ProfilePage.fromProfile(profile));
        await tester.pump();
        await tester.tap(
          find.descendant(
              of: find.byKey(const Key('gender')), matching: find.byKey(const Key('editableRowIconButton'))),
        );
        await tester.pumpAndSettle();
        expect(find.byType(EditGenderPage), findsOneWidget);

        await tester.tap(find.byKey(const Key('preferNotToSayGenderRadioListTile')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('saveButton')), findsOneWidget);

        await tester.tap(find.byKey(const Key('saveButton')));
        await tester.pumpAndSettle();

        expect(find.byType(ProfilePage), findsOneWidget);

        verifyRequest(
          processor,
          urlMatcher: equals('/rest/v1/profiles?id=eq.1'),
          methodMatcher: equals('PATCH'),
          bodyMatcher: equals({'gender': null}),
        ).called(1);

        verifyRequest(
          processor,
          urlMatcher: startsWith('/rest/v1/profiles'),
          methodMatcher: equals('GET'),
        ).called(3);
      });
    });
  });
}
