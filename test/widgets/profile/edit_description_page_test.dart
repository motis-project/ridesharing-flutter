import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/account/pages/edit_account/edit_description_page.dart';
import 'package:motis_mitfahr_app/util/supabase.dart';

import '../../util/factories/profile_factory.dart';
import '../../util/mocks/mock_server.dart';
import '../../util/mocks/request_processor.dart';
import '../../util/mocks/request_processor.mocks.dart';
import '../../util/pump_material.dart';

void main() {
  late Profile profile;
  final MockRequestProcessor processor = MockRequestProcessor();

  setUpAll(() async {
    MockServer.setProcessor(processor);
  });

  setUp(() {
    profile = ProfileFactory().generateFake(id: 1);
    SupabaseManager.setCurrentProfile(profile);
    whenRequest(processor, urlMatcher: equals('/rest/v1/profiles?id=eq.1')).thenReturnJson('');
  });
  group('edit_description_page', () {
    testWidgets('description TextField', (WidgetTester tester) async {
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
    testWidgets('description clear Button', (WidgetTester tester) async {
      await pumpMaterial(tester, EditDescriptionPage(profile));
      await tester.pump();
      expect(find.text(profile.description!), findsOneWidget);
      final Finder clearButton = find.byKey(const Key('clearButton'));
      expect(clearButton, findsOneWidget);
      await tester.tap(clearButton);
      await tester.pump();
      expect(find.text(profile.description!), findsNothing);
    });
    // same problem as in edit_username_page_test.dart
    testWidgets('save Button', (WidgetTester tester) async {});
  });
}
