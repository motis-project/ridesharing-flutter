import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/account/pages/edit_account/edit_full_name_page.dart';
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
      final Finder clearButton = find.byKey(const Key('clearButton'));
      expect(clearButton, findsNWidgets(2));
      await tester.tap(clearButton.first);
      await tester.pump();
      expect(find.text(profile.surname!), findsNothing);
    });
    testWidgets('name clear Button', (WidgetTester tester) async {
      await pumpMaterial(tester, EditFullNamePage(profile));
      await tester.pump();
      expect(find.text(profile.name!), findsOneWidget);
      final Finder clearButton = find.byKey(const Key('clearButton'));
      expect(clearButton, findsNWidgets(2));
      await tester.tap(clearButton.last);
      await tester.pump();
      expect(find.text(profile.name!), findsNothing);
    });
    //same problem as in edit_username_page_test.dart
    testWidgets('save Button', (WidgetTester tester) async {});
  });
}
