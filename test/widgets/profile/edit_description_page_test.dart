import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/account/pages/edit_account/edit_description_page.dart';
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
  group('edit_description_page', () {
    testWidgets('description TextField', (WidgetTester tester) async {
      //load page
      await pumpMaterial(tester, EditDescriptionPage(profile));
      await tester.pump();

      //check if description is displayed
      expect(find.text(profile.description!), findsOneWidget);

      //check if description TextField is displayed
      final Finder descriptionInput = find.byKey(const Key('description'));
      expect(descriptionInput, findsOneWidget);

      //check if description TextField is editable
      await tester.tap(descriptionInput);
      await tester.pumpAndSettle();
      await tester.enterText(descriptionInput, 'newDescription');
      expect(find.text('newDescription'), findsOneWidget);
    });
    testWidgets('description clear Button', (WidgetTester tester) async {
      //load page
      await pumpMaterial(tester, EditDescriptionPage(profile));
      await tester.pump();

      //check if description is displayed
      expect(find.text(profile.description!), findsOneWidget);

      //check if clear Button is displayed
      final Finder clearButton = find.byKey(const Key('clearButton'));
      expect(clearButton, findsOneWidget);

      //check if description is cleared
      await tester.tap(clearButton);
      await tester.pump();
      expect(find.text(profile.description!), findsNothing);
    });
    testWidgets('save Button', (WidgetTester tester) async {
      //sign in
      SupabaseManager.supabaseClient.auth.signInWithPassword(
        email: email,
        password: authId,
      );

      // load ProfilePage
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();

      // load EditDescriptionPage
      await tester.tap(
          find.descendant(of: find.byKey(const Key('description')), matching: find.byKey(const Key('editButton'))));
      await tester.pumpAndSettle();
      expect(find.byType(EditDescriptionPage), findsOneWidget);

      // check if save Button is displayed
      expect(find.byKey(const Key('saveButton')), findsOneWidget);

      //tap save Button
      await tester.tap(find.byKey(const Key('saveButton')));
      await tester.pumpAndSettle();

      //check if ProfilePage is displayed
      expect(find.byType(ProfilePage), findsOneWidget);
    });
  });
}
