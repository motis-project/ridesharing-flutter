import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/account/pages/edit_account/edit_birth_date_page.dart';
import 'package:motis_mitfahr_app/account/pages/profile_page.dart';
import 'package:motis_mitfahr_app/util/locale_manager.dart';
import 'package:motis_mitfahr_app/util/supabase_manager.dart';
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

    whenRequest(processor, urlMatcher: startsWith('/rest/v1/profile')).thenReturnJson(profile.toJsonForApi());
  });
  group('edit_birth_date_page', () {
    testWidgets('birthDate TextField', (WidgetTester tester) async {
      await pumpMaterial(tester, EditBirthDatePage(profile));

      final Finder birthDateFinder = find.text(localeManager.formatDate(profile.birthDate!));
      expect(birthDateFinder, findsOneWidget);

      final Finder birthDateInputFinder = find.byKey(const Key('birthDateInput'));
      expect(birthDateInputFinder, findsOneWidget);
    });

    testWidgets('change birthDate', (WidgetTester tester) async {
      await pumpMaterial(tester, EditBirthDatePage(profile));

      final Finder birthDateFinder = find.text(localeManager.formatDate(profile.birthDate!));
      final Finder birthDateInputFinder = find.byKey(const Key('birthDateInput'));

      await tester.tap(birthDateInputFinder);
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);

      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      await tester.tap(birthDateFinder.last);
      final String date = localeManager.formatDate(profile.birthDate!.add(const Duration(days: 5)));

      await tester.enterText(birthDateFinder.last, date);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text(date), findsOneWidget);
    });

    testWidgets('clear Button', (WidgetTester tester) async {
      await pumpMaterial(tester, EditBirthDatePage(profile));

      final Finder birthDateFinder = find.text(localeManager.formatDate(profile.birthDate!));

      expect(birthDateFinder, findsOneWidget);

      final Finder clearButton = find.byKey(const Key('clearButton'));
      expect(clearButton, findsOneWidget);

      await tester.tap(clearButton);
      await tester.pump();
      expect(birthDateFinder, findsNothing);
    });

    testWidgets('save Button', (WidgetTester tester) async {
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();
      expect(find.text(profile.age.toString()), findsOneWidget);

      await tester.tap(
          find.descendant(of: find.byKey(const Key('age')), matching: find.byKey(const Key('editableRowIconButton'))));
      await tester.pumpAndSettle();
      expect(find.byType(EditBirthDatePage), findsOneWidget);

      final Finder clearButton = find.byKey(const Key('clearButton'));
      await tester.tap(clearButton);
      await tester.pump();

      final Finder saveButtonFinder = find.byKey(const Key('saveButton'));
      expect(saveButtonFinder, findsOneWidget);
      await tester.tap(saveButtonFinder);
      await tester.pumpAndSettle();

      expect(find.byType(ProfilePage), findsOneWidget);

      verifyRequest(
        processor,
        urlMatcher: equals('/rest/v1/profiles?id=eq.1'),
        methodMatcher: equals('PATCH'),
        bodyMatcher: equals({'birth_date': null}),
      ).called(1);

      verifyRequest(
        processor,
        urlMatcher: startsWith('/rest/v1/profiles'),
        methodMatcher: equals('GET'),
      ).called(3);
    });
  });
}
