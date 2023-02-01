import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/account/pages/edit_account/edit_username_page.dart';
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
  group('edit_username_page', () {
    testWidgets('username TextField', (WidgetTester tester) async {
      await pumpMaterial(tester, EditUsernamePage(profile));
      await tester.pump();

      expect(find.text(profile.username), findsOneWidget);

      final Finder usernameInput = find.byKey(const Key('usernameTextField'));
      expect(usernameInput, findsOneWidget);

      await tester.tap(usernameInput);
      await tester.pumpAndSettle();
      await tester.enterText(usernameInput, 'newUsername');
      expect(find.text('newUsername'), findsOneWidget);
    });
    testWidgets('username clear Button', (WidgetTester tester) async {
      await pumpMaterial(tester, EditUsernamePage(profile));
      await tester.pump();

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

      await tester.tap(find.byKey(const Key('editUsername')));
      await tester.pumpAndSettle();
      expect(find.byType(EditUsernamePage), findsOneWidget);

      expect(find.byKey(const Key('saveButton')), findsOneWidget);

      await tester.tap(find.byKey(const Key('saveButton')));
      await tester.pumpAndSettle();

      expect(find.byType(ProfilePage), findsOneWidget);
    });
  });
}
