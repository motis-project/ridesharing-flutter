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
  group('edit_full_name_page', () {
    testWidgets('surname TextField', (WidgetTester tester) async {
      //load page
      await pumpMaterial(tester, EditFullNamePage(profile));
      await tester.pump();

      //check if surname is displayed
      expect(find.text(profile.surname!), findsOneWidget);

      //check if surname text field is displayed
      final Finder surnameInput = find.byKey(const Key('surname'));
      expect(surnameInput, findsOneWidget);

      //check if surname TextField is editable
      await tester.tap(surnameInput);
      await tester.pump();
      await tester.enterText(surnameInput, 'newSurname');
      expect(find.text('newSurname'), findsOneWidget);
    });
    testWidgets('name TextField', (WidgetTester tester) async {
      //load page
      await pumpMaterial(tester, EditFullNamePage(profile));
      await tester.pump();

      //check if name is displayed
      expect(find.text(profile.name!), findsOneWidget);

      //check if name text field is displayed
      final Finder nameInput = find.byKey(const Key('name'));
      expect(nameInput, findsOneWidget);

      //check if name TextField is editable
      await tester.tap(nameInput);
      await tester.pump();
      await tester.enterText(nameInput, 'newName');
      expect(find.text('newName'), findsOneWidget);
    });
    testWidgets('surname clear Button', (WidgetTester tester) async {
      //load page
      await pumpMaterial(tester, EditFullNamePage(profile));
      await tester.pump();

      //check if surname is displayed
      expect(find.text(profile.surname!), findsOneWidget);

      //check if surname clear button is displayed
      final Finder clearButton = find.byKey(const Key('clearButton')).first;
      expect(clearButton, findsOneWidget);

      //check surname is being cleared
      await tester.tap(clearButton);
      await tester.pump();
      expect(find.text(profile.surname!), findsNothing);
    });
    testWidgets('name clear Button', (WidgetTester tester) async {
      //load page
      await pumpMaterial(tester, EditFullNamePage(profile));
      await tester.pump();

      //check if name is displayed
      expect(find.text(profile.name!), findsOneWidget);
      final Finder clearButton = find.byKey(const Key('clearButton')).last;

      //check if name clear button is displayed
      expect(clearButton, findsOneWidget);

      //check surname is being cleared
      await tester.tap(clearButton);
      await tester.pump();
      expect(find.text(profile.name!), findsNothing);
    });
    //same problem as in edit_username_page_test.dart
    testWidgets('save Button', (WidgetTester tester) async {
      //login
      SupabaseManager.supabaseClient.auth.signInWithPassword(
        email: email,
        password: authId,
      );

      //load ProfilePage
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();

      //tap edit button for fullName
      await tester
          .tap(find.descendant(of: find.byKey(const Key('fullName')), matching: find.byKey(const Key('editButton'))));
      await tester.pumpAndSettle();

      //check if EditFullNamePage is displayed
      expect(find.byType(EditFullNamePage), findsOneWidget);

      //check if saveButton is displayed
      expect(find.byKey(const Key('saveButton')), findsOneWidget);

      //tap saveButton
      await tester.tap(find.byKey(const Key('saveButton')));
      await tester.pumpAndSettle();

      //check if ProfilePage is displayed
      expect(find.byType(ProfilePage), findsOneWidget);
    });
  });
}
