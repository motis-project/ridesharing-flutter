import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/account/pages/edit_account/edit_birth_date_page.dart';
import 'package:motis_mitfahr_app/account/pages/profile_page.dart';
import 'package:motis_mitfahr_app/util/locale_manager.dart';
import 'package:motis_mitfahr_app/util/supabase.dart';

import '../util/factories/profile_factory.dart';
import '../util/mock_server.dart';
import '../util/pump_material.dart';
import '../util/request_processor.dart';
import '../util/request_processor.mocks.dart';

void main() {
  late Profile profile;
  final MockRequestProcessor processor = MockRequestProcessor();

  setUpAll(() async {
    MockServer.setProcessor(processor);
  });

  setUp(() {
    profile = ProfileFactory().generateFake(id: 1);
    SupabaseManager.setCurrentProfile(profile);
    whenRequest(processor, urlMatcher: equals('/rest/v1/profiles?id=eq.1')).thenReturn('');
  });
  group('edit_birth_date_page', () {
    testWidgets('birthDate TextField', (WidgetTester tester) async {
      await pumpMaterial(tester, EditBirthDatePage(profile));
      await tester.pump();
      expect(find.text(localeManager.formatDate(profile.birthDate!)), findsOneWidget);
      final Finder birthDateInput = find.byKey(const Key('birthDateInput'));
      expect(birthDateInput, findsOneWidget);
      await tester.tap(birthDateInput);
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
    });
    testWidgets('change birthDate', (WidgetTester tester) async {
      await pumpMaterial(tester, EditBirthDatePage(profile));
      await tester.pump();
      final Finder birthDateInput = find.text(localeManager.formatDate(profile.birthDate!));
      expect(birthDateInput, findsOneWidget);
      await tester.tap(find.byKey(const Key('birthDateInput')));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();
      await tester.tap(birthDateInput.last);
      final String date = localeManager.formatDate(profile.birthDate!.add(const Duration(days: 5)));
      await tester.enterText(birthDateInput.last, date);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text(date), findsOneWidget);
    });
    // same problem as in username_page_test.dart
    testWidgets('save Button', (WidgetTester tester) async {
      await pumpMaterial(tester, EditBirthDatePage(profile));
      await tester.pump();
      final saveButton = find.byKey(const Key('saveButton'));
      expect(saveButton, findsOneWidget);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();
      expect(find.byType(ProfilePage), findsOneWidget);
    });
    testWidgets('clear Button', (WidgetTester tester) async {
      await pumpMaterial(tester, EditBirthDatePage(profile));
      await tester.pump();
      expect(find.text(localeManager.formatDate(profile.birthDate!)), findsOneWidget);
      final Finder clearButton = find.byKey(const Key('clearButton'));
      expect(clearButton, findsOneWidget);
      await tester.tap(clearButton);
      await tester.pump();
      expect(find.text(localeManager.formatDate(profile.birthDate!)), findsNothing);
    });
  });
}
