import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/account/pages/edit_account/edit_birth_date_page.dart';
import 'package:motis_mitfahr_app/account/pages/edit_account/edit_description_page.dart';
import 'package:motis_mitfahr_app/account/pages/edit_account/edit_full_name_page.dart';
import 'package:motis_mitfahr_app/account/pages/edit_account/edit_gender_page.dart';
import 'package:motis_mitfahr_app/account/pages/edit_account/edit_username_page.dart';
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
    testWidgets('show birthDate TextField', (WidgetTester tester) async {
      await pumpMaterial(tester, EditBirthDatePage(profile));
      await tester.pump();
      expect(find.text(localeManager.formatDate(profile.birthDate!)), findsOneWidget);
      final Finder birthDateInput = find.byKey(const Key('birthDateInput'));
      expect(birthDateInput, findsOneWidget);
      await tester.tap(birthDateInput);
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
    });
    testWidgets('show save Button', (WidgetTester tester) async {
      //await pumpMaterial(tester, EditBirthDatePage(profile));
      //await tester.pump();
      //final saveButton = find.byKey(const Key('saveButton'));
      //expect(saveButton, findsOneWidget);
      //await tester.tap(saveButton);
      //await tester.pump();
      //expect(find.byType(ProfilePage).hitTestable(), findsOneWidget);
    });
    testWidgets('show clear Button', (WidgetTester tester) async {
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
  group('edit_description_page', () {
    testWidgets('show description TextField', (WidgetTester tester) async {
      await pumpMaterial(tester, EditDescriptionPage(profile));
      await tester.pump();
      expect(find.text(profile.description!), findsOneWidget);
      final Finder descriptionInput = find.byKey(const Key('description'));
      expect(descriptionInput, findsOneWidget);
      await tester.tap(descriptionInput);
      await tester.pumpAndSettle();
      await tester.enterText(descriptionInput, 'newDescription');
      expect(find.text('newDescription'), findsOneWidget);
    });
    testWidgets('show description clear Button', (WidgetTester tester) async {
      await pumpMaterial(tester, EditDescriptionPage(profile));
      await tester.pump();
      expect(find.text(profile.description!), findsOneWidget);
      final Finder clearButton = find.byKey(const Key('clearButton'));
      expect(clearButton, findsOneWidget);
      await tester.tap(clearButton);
      await tester.pump();
      expect(find.text(profile.description!), findsNothing);
    });
    testWidgets('show save Button', (WidgetTester tester) async {});
  });
  group('edit_full_name_page', () {
    testWidgets('show Surname TextField', (WidgetTester tester) async {
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
    testWidgets('show name TextField', (WidgetTester tester) async {
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
    testWidgets('show name clear Button', (WidgetTester tester) async {
      await pumpMaterial(tester, EditFullNamePage(profile));
      await tester.pump();
      expect(find.text(profile.name!), findsOneWidget);
      final Finder clearButton = find.byKey(const Key('clearButton'));
      expect(clearButton, findsNWidgets(2));
      await tester.tap(clearButton.last);
      await tester.pump();
      expect(find.text(profile.name!), findsNothing);
    });
    testWidgets('show save Button', (WidgetTester tester) async {});
  });
  group('edit_gender_page', () {
    testWidgets('show gender genderRadioListTile', (WidgetTester tester) async {
      await pumpMaterial(tester, EditGenderPage(profile));
      await tester.pump();
      final maleGenderFinder = find.byKey(const Key('0genderRadioListTile'));
      expect(maleGenderFinder, findsOneWidget);
      final femaleGenderFinder = find.byKey(const Key('1genderRadioListTile'));
      expect(femaleGenderFinder, findsOneWidget);
      final diverseGenderFinder = find.byKey(const Key('2genderRadioListTile'));
      expect(diverseGenderFinder, findsOneWidget);
      final preferNotToSayGenderFinder = find.byKey(const Key('preferNotToSayGenderRadioListTile'));
      expect(preferNotToSayGenderFinder, findsOneWidget);
      // don't know to interact with RadioListTiles in tests
    });
    testWidgets('show save Button', (WidgetTester tester) async {});
  });
  group('edit_profile_features_page', () {});
  group('edit_username_page', () {
    testWidgets('show username TextField', (WidgetTester tester) async {
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
    testWidgets('show username clear Button', (WidgetTester tester) async {
      await pumpMaterial(tester, EditUsernamePage(profile));
      await tester.pump();
      expect(find.text(profile.username), findsOneWidget);
      final Finder clearButton = find.byKey(const Key('clearButton'));
      expect(clearButton, findsOneWidget);
      await tester.tap(clearButton);
      await tester.pump();
      expect(find.text(profile.username), findsNothing);
    });
    testWidgets('show save Button', (WidgetTester tester) async {});
  });
}
