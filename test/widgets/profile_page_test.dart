import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/account/pages/profile_page.dart';

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
    profile = ProfileFactory().generateFake();
    whenRequest(processor).thenReturnJson(profile.toJsonForApi());
  });

  group('ProfilePage', () {
    group('constructors', () {
      testWidgets('Works with id parameter', (WidgetTester tester) async {
        await pumpMaterial(tester, ProfilePage(profile.id!));
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Wait for the profile to be fully loaded
        await tester.pump();
      });

      testWidgets('Works with object parameter', (WidgetTester tester) async {
        await pumpMaterial(tester, ProfilePage.fromProfile(profile));
        //set current user
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        //expect(find.byType(TextButton), findsOneWidget);
        // Wait for the profile to be fully loaded
        await tester.pump();

        expect(find.text(profile.username), findsNWidgets(2));
      });
    });

    testWidgets('Show Full Name', (WidgetTester tester) async {
      await pumpMaterial(tester, ProfilePage.fromProfile(profile));
      await tester.pump();
      final fullName = find.text(profile.fullName);
      await tester.scrollUntilVisible(fullName, 100);
      expect(fullName, findsAtLeastNWidgets(1));
    });
  });
}
