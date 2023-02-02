import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/account/pages/account_page.dart';
import 'package:motis_mitfahr_app/account/pages/help_page.dart';
import 'package:motis_mitfahr_app/drives/pages/drives_page.dart';
import 'package:motis_mitfahr_app/home_page.dart';
import 'package:motis_mitfahr_app/main_app.dart';
import 'package:motis_mitfahr_app/rides/pages/rides_page.dart';

import '../util/mocks/mock_server.dart';
import '../util/mocks/request_processor.dart';
import '../util/mocks/request_processor.mocks.dart';
import '../util/pump_material.dart';

void main() {
  final MockRequestProcessor processor = MockRequestProcessor();

  setUpAll(() async {
    MockServer.setProcessor(processor);
    whenRequest(processor).thenReturnJson('');
  });

  setUp(() {});

  group('Main app', () {
    testWidgets('It shows the home page as default', (tester) async {
      await pumpMaterial(tester, const MainApp());

      expect(find.byType(HomePage).hitTestable(), findsOneWidget);
    });

    testWidgets('Can navigate via the bottom bar', (tester) async {
      await pumpMaterial(tester, const MainApp());

      await tester.tap(find.byKey(const Key('drivesIcon')));
      await tester.pump();
      expect(find.byType(DrivesPage).hitTestable(), findsOneWidget);

      await tester.tap(find.byKey(const Key('ridesIcon')));
      await tester.pump();
      expect(find.byType(RidesPage).hitTestable(), findsOneWidget);

      await tester.tap(find.byKey(const Key('accountIcon')));
      await tester.pump();
      expect(find.byType(AccountPage).hitTestable(), findsOneWidget);

      await tester.tap(find.byKey(const Key('homeIcon')));
      await tester.pump();
      expect(find.byType(HomePage).hitTestable(), findsOneWidget);
    });

    testWidgets('Navigator saves state between the tabs', (tester) async {
      await pumpMaterial(tester, const MainApp());

      await tester.tap(find.byKey(const Key('accountIcon')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('accountHelp')));
      await tester.pump();

      expect(find.byType(HelpPage, skipOffstage: false), findsOneWidget);

      await tester.tap(find.byKey(const Key('homeIcon')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('accountIcon')));
      await tester.pump();

      expect(find.byType(HelpPage).hitTestable(), findsOneWidget);
    });

    testWidgets('Tapping on current tab goes to first page of tab', (tester) async {
      await pumpMaterial(tester, const MainApp());

      await tester.tap(find.byKey(const Key('accountIcon')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('accountHelp')));
      await tester.pump();

      expect(find.byType(HelpPage).hitTestable(), findsOneWidget);

      await tester.tap(find.byKey(const Key('accountIcon')));
      await tester.pump();

      expect(find.byType(AccountPage).hitTestable(), findsOneWidget);
    });

    testWidgets('The back button goes to Home when on other tab', (tester) async {
      await pumpMaterial(tester, const MainApp());

      await tester.tap(find.byKey(const Key('accountIcon')));
      await tester.pump();
      expect(find.byType(AccountPage).hitTestable(), findsOneWidget);

      // Use didPopRoute() to simulate the system back button. Check that
      // didPopRoute() indicates that the notification was handled.
      final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
      // ignore: avoid_dynamic_calls
      expect(await widgetsAppState.didPopRoute(), isTrue);

      await tester.pump();
      expect(find.byType(HomePage).hitTestable(), findsOneWidget);
    });
  });
}
