import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/account/pages/edit_account/edit_birth_date_page.dart';
import 'package:motis_mitfahr_app/account/pages/profile_page.dart';
import 'package:motis_mitfahr_app/util/locale_manager.dart';
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
  group('edit_birth_date_page', () {
    testWidgets('birthDate TextField', (WidgetTester tester) async {
      //load page
      await pumpMaterial(tester, EditBirthDatePage(profile));
      await tester.pump();

      //check if birthDate is displayed
      expect(find.text(localeManager.formatDate(profile.birthDate!)), findsOneWidget);

      //check if birthDate TextField is displayed
      final Finder birthDateInput = find.byKey(const Key('birthDateInput'));
      expect(birthDateInput, findsOneWidget);

      //check if birthDate TextField is editable
      await tester.tap(birthDateInput);
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
    });
    testWidgets('change birthDate', (WidgetTester tester) async {
      //load page
      await pumpMaterial(tester, EditBirthDatePage(profile));
      await tester.pump();

      //check if birthDate is displayed
      final Finder birthDateInput = find.text(localeManager.formatDate(profile.birthDate!));
      expect(birthDateInput, findsOneWidget);

      //tap birthDate TextField
      await tester.tap(find.byKey(const Key('birthDateInput')));
      await tester.pumpAndSettle();

      //tap in DatePickerDialog to custom input
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      //enter new birthDate
      await tester.tap(birthDateInput.last);
      final String date = localeManager.formatDate(profile.birthDate!.add(const Duration(days: 5)));

      //leave DatePickerDialog
      await tester.enterText(birthDateInput.last, date);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      //check if new birthDate is displayed
      expect(find.text(date), findsOneWidget);
    });
    testWidgets('clear Button', (WidgetTester tester) async {
      //load page
      await pumpMaterial(tester, EditBirthDatePage(profile));
      await tester.pump();

      //check if birthDate is displayed
      expect(find.text(localeManager.formatDate(profile.birthDate!)), findsOneWidget);

      //check if clear Button is displayed
      final Finder clearButton = find.byKey(const Key('clearButton'));
      expect(clearButton, findsOneWidget);

      //check if birthDate is cleared
      await tester.tap(clearButton);
      await tester.pump();
      expect(find.text(localeManager.formatDate(profile.birthDate!)), findsNothing);
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

      //check if EditBirthDatePage is displayed
      await tester
          .tap(find.descendant(of: find.byKey(const Key('age')), matching: find.byKey(const Key('editButton'))));
      await tester.pumpAndSettle();
      expect(find.byType(EditBirthDatePage), findsOneWidget);

      //check if save Button is displayed
      expect(find.byKey(const Key('saveButton')), findsOneWidget);

      //tap save Button
      await tester.tap(find.byKey(const Key('saveButton')));
      await tester.pumpAndSettle();

      //check if ProfilePage is displayed
      expect(find.byType(ProfilePage), findsOneWidget);
    });
  });
}
