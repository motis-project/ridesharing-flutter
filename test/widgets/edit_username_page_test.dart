import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/account/pages/edit_account/edit_username_page.dart';
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
    whenRequest(processor).thenReturnJson(profile.toJsonForApi());
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
    // how to set auth.currentUser
    testWidgets('save Button', (WidgetTester tester) async {
      print(profile);
      await pumpMaterial(tester, EditUsernamePage(profile));
      await tester.pump();
      expect(find.byKey(const Key('saveButton')), findsOneWidget);
      await tester.tap(find.byKey(const Key('saveButton')));
      await tester.pumpAndSettle();
      //supabaseClient.auth.currentUser! is null
      //expect(find.byType(StatefulWidget), findsOneWidget);
    });
  });
}
