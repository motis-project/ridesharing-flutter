// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:motis_mitfahr_app/main_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Shows homepage', skip: true, (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MainApp());

    // Verify that homepage is shown.
    expect(find.text('Home'), findsAtLeastNWidgets(2));
  });
}
