import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/util/supabase_manager.dart';
import 'package:motis_mitfahr_app/welcome/pages/after_registration_page.dart';
import 'package:motis_mitfahr_app/welcome/pages/login_page.dart';
import 'package:motis_mitfahr_app/welcome/pages/welcome_page.dart';

import '../../util/pump_material.dart';

void main() {
  setUpAll(() async {
    supabaseManager.currentProfile = null;
  });

  group('WelcomePage', () {
    testWidgets('Shows the page', (WidgetTester tester) async {
      await pumpMaterial(tester, const AfterRegistrationPage());

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('Can go to Login', (WidgetTester tester) async {
      await pumpMaterial(tester, const WelcomePage());

      final NavigatorState navigator = tester.state(find.byType(Navigator));
      navigator.push(MaterialPageRoute<void>(builder: (BuildContext context) => const AfterRegistrationPage()));

      await tester.pumpAndSettle();

      final Finder loginButton = find.byKey(const Key('afterRegistrationLoginButton'));
      await tester.scrollUntilVisible(loginButton, 500);

      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
    });
  });
}
