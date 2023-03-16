import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/account/pages/edit_profile/edit_username_page.dart';
import 'package:motis_mitfahr_app/account/pages/profile_page.dart';
import 'package:motis_mitfahr_app/managers/supabase_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../test_util/factories/profile_factory.dart';
import '../../../test_util/mocks/mock_server.dart';
import '../../../test_util/mocks/request_processor.dart';
import '../../../test_util/mocks/request_processor.mocks.dart';
import '../../../test_util/pump_material.dart';

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

  group('edit_username_page', () {
    testWidgets('username TextField', (WidgetTester tester) async {
      await pumpMaterial(tester, EditUsernamePage(profile));

      final Finder usernameFinder = find.text(profile.username);

      expect(usernameFinder, findsOneWidget);

      await tester.enterText(usernameFinder, 'newUsername');
      expect(find.text('newUsername'), findsOneWidget);
    });

    testWidgets('username clear Button', (WidgetTester tester) async {
      await pumpMaterial(tester, EditUsernamePage(profile));

      expect(find.text(profile.username), findsOneWidget);

      final Finder clearButton = find.byKey(const Key('clearButton'));
      expect(clearButton, findsOneWidget);

      await tester.tap(clearButton);
      await tester.pump();
      expect(find.text(profile.username), findsNothing);
    });

    testWidgets('save Button', (WidgetTester tester) async {
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();

      await tester.tap(find.byKey(const Key('editUsernameIcon')));
      await tester.pumpAndSettle();
      expect(find.byType(EditUsernamePage), findsOneWidget);

      await tester.tap(find.byKey(const Key('clearButton')));
      await tester.pump();

      final Finder saveButton = find.byKey(const Key('saveButton'));
      expect(saveButton, findsOneWidget);

      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // stays in editUsernamePage since username is empty
      expect(find.byType(EditUsernamePage), findsOneWidget);

      await tester.enterText(find.byKey(const Key('usernameTextField')), 'newUsername');

      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // leaves ProfilePage since now username is not empty
      expect(find.byType(ProfilePage), findsOneWidget);

      verifyRequest(
        processor,
        urlMatcher: equals('/rest/v1/profiles?id=eq.1'),
        methodMatcher: equals('PATCH'),
        bodyMatcher: equals({'username': 'newUsername'}),
      ).called(1);

      verifyRequest(
        processor,
        urlMatcher: startsWith('/rest/v1/profiles'),
        methodMatcher: equals('GET'),
      ).called(3);
    });

    testWidgets('Accessibility', (WidgetTester tester) async {
      await expectMeetsAccessibilityGuidelines(tester, EditUsernamePage(profile));
    });
  });
}
