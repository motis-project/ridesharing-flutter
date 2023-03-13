import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/account/pages/about_page.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../util/pump_material.dart';

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
        appName: 'Motis Ride',
        packageName: 'motis_mitfahr_app',
        version: '1.0.0',
        buildNumber: '1',
        buildSignature: 'buildSignature',
        installerStore: null);
  });

  testWidgets('About page', (WidgetTester tester) async {
    PackageInfo.setMockInitialValues(
        appName: 'Motis Ride',
        packageName: 'motis_mitfahr_app',
        version: '1.0.0',
        buildNumber: '1',
        buildSignature: 'buildSignature',
        installerStore: null);

    await pumpMaterial(tester, const AboutPage());
    await tester.pump();

    expect(find.byKey(const Key('aboutPageAppName')), findsOneWidget);
    expect(find.byKey(const Key('aboutPageVersion')), findsOneWidget);
    expect(find.byKey(const Key('aboutPageBuildNumber')), findsOneWidget);
    expect(find.byKey(const Key('aboutPageBuildSignature')), findsOneWidget);
  });

  testWidgets('Accessibility', (WidgetTester tester) async {
    await expectMeetsAccessibilityGuidelines(tester, const AboutPage());
  });
}
