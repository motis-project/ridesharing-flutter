import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/rides/pages/search_ride_page.dart';
import 'package:motis_mitfahr_app/util/supabase_manager.dart';
import 'package:motis_mitfahr_app/welcome/pages/login_page.dart';
import 'package:motis_mitfahr_app/welcome/pages/register_page.dart';
import 'package:motis_mitfahr_app/welcome/pages/welcome_page.dart';

import '../../util/pump_material.dart';

void main() {
  setUpAll(() async {
    supabaseManager.currentProfile = null;
  });

  group('WelcomePage', () {
    testWidgets('Shows welcome images in carousel', (WidgetTester tester) async {
      await pumpMaterial(tester, const WelcomePage());

      expect(find.byType(Image), findsNWidgets(1));

      expect(find.byKey(const Key('welcomeImage0')), findsOneWidget);
      expect(find.byKey(const Key('welcomeImage1')), findsNothing);
      expect(find.byKey(const Key('welcomeImage2')), findsNothing);

      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('welcomeImage0')), findsNothing);
      expect(find.byKey(const Key('welcomeImage1')), findsOneWidget);
      expect(find.byKey(const Key('welcomeImage2')), findsNothing);

      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('welcomeImage0')), findsNothing);
      expect(find.byKey(const Key('welcomeImage1')), findsNothing);
      expect(find.byKey(const Key('welcomeImage2')), findsOneWidget);
    });

    testWidgets('Does not show carousel if page is not high enough', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(300, 350);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await pumpMaterial(tester, const WelcomePage());

      expect(find.byType(Image), findsNothing);
    });

    testWidgets('Can go to Login', (WidgetTester tester) async {
      await pumpMaterial(tester, const WelcomePage());

      await tester.tap(find.byKey(const Key('LoginButton')));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('Can go to Register', (WidgetTester tester) async {
      await pumpMaterial(tester, const WelcomePage());

      await tester.tap(find.byKey(const Key('RegisterButton')));
      await tester.pumpAndSettle();

      expect(find.byType(RegisterPage), findsOneWidget);
    });

    testWidgets('Can go to Anonymous Search', (WidgetTester tester) async {
      await pumpMaterial(tester, const WelcomePage());

      await tester.tap(find.byKey(const Key('AnonymousSearchButton')));
      await tester.pumpAndSettle();

      expect(find.byType(SearchRidePage), findsOneWidget);
    });
  });
}
