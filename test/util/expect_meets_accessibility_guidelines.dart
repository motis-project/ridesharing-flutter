import 'package:flutter_test/flutter_test.dart';

Future<void> checkMeetsAccessibility(WidgetTester tester) async {
  final SemanticsHandle handle = tester.ensureSemantics();
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
  handle.dispose();
}
