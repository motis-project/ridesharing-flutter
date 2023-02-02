import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/account/pages/edit_account/edit_full_name_page.dart';
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

  setUp(() async {
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

    await SupabaseManager.supabaseClient.auth.signInWithPassword(
      email: email,
      password: authId,
    );

    whenRequest(processor, urlMatcher: contains('/rest/v1/profiles')).thenReturnJson(profile.toJsonForApi());
  });
  group('edit_full_name_page', () {
    testWidgets('surname TextField', (WidgetTester tester) async {
      await pumpMaterial(tester, EditFullNamePage(profile));
      await tester.pump();

      expect(find.text(profile.surname!), findsOneWidget);

      final Finder surnameInput = find.byKey(const Key('surname'));
      expect(surnameInput, findsOneWidget);

      await tester.tap(surnameInput);
      await tester.pump();
      await tester.enterText(surnameInput, 'newSurname');
      expect(find.text('newSurname'), findsOneWidget);
    });
    testWidgets('name TextField', (WidgetTester tester) async {
      await pumpMaterial(tester, EditFullNamePage(profile));
      await tester.pump();

      expect(find.text(profile.name!), findsOneWidget);

      final Finder nameInput = find.byKey(const Key('name'));
      expect(nameInput, findsOneWidget);

      await tester.tap(nameInput);
      await tester.pump();
      await tester.enterText(nameInput, 'newName');
      expect(find.text('newName'), findsOneWidget);
    });
    testWidgets('surname clear Button', (WidgetTester tester) async {
      await pumpMaterial(tester, EditFullNamePage(profile));
      await tester.pump();

      expect(find.text(profile.surname!), findsOneWidget);

      final Finder clearButton = find.byKey(const Key('clearButton')).first;
      expect(clearButton, findsOneWidget);

      await tester.tap(clearButton);
      await tester.pump();
      expect(find.text(profile.surname!), findsNothing);
    });
    testWidgets('name clear Button', (WidgetTester tester) async {
      await pumpMaterial(tester, EditFullNamePage(profile));
      await tester.pump();

      expect(find.text(profile.name!), findsOneWidget);

      final Finder clearButton = find.byKey(const Key('clearButton')).last;
      expect(clearButton, findsOneWidget);

      await tester.tap(clearButton);
      await tester.pump();
      expect(find.text(profile.name!), findsNothing);
    });
    testWidgets('save Button', (WidgetTester tester) async {
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();

      expect(find.text(profile.fullName), findsOneWidget);

      await tester
          .tap(find.descendant(of: find.byKey(const Key('fullName')), matching: find.byKey(const Key('editButton'))));
      await tester.pumpAndSettle();
      expect(find.byType(EditFullNamePage), findsOneWidget);

      await tester.tap(find.byKey(const Key('clearButton')).first);
      await tester.pump();
      await tester.tap(find.byKey(const Key('clearButton')).last);
      await tester.pump();

      expect(find.byKey(const Key('saveButton')), findsOneWidget);
      await tester.tap(find.byKey(const Key('saveButton')));
      await tester.pumpAndSettle();

      expect(find.byType(ProfilePage), findsOneWidget);

      verifyRequest(
        processor,
        urlMatcher: equals('/rest/v1/profiles?id=eq.1'),
        methodMatcher: equals('PATCH'),
        bodyMatcher: equals({'surname': null, 'name': null}),
      ).called(1);

      verifyRequest(processor,
              urlMatcher: equals(
                  '/rest/v1/profiles?select=%2A%2Cprofile_features%28%2A%29%2Creviews_received%3Areviews%21reviews_receiver_id_fkey%28%2A%2Cwriter%3Awriter_id%28%2A%29%29%2Creports_received%3Areports%21reports_offender_id_fkey%28%2A%29&id=eq.1'))
          .called(2);
    });
  });
}
