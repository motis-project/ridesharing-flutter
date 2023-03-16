import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/util/fields/email_field.dart';

import '../../test_util/pump_material.dart';

void main() {
  group('EmailField', () {
    final Finder emailFieldFinder = find.descendant(
      of: find.byType(EmailField),
      matching: find.byType(TextFormField),
    );

    testWidgets('Validates the email', (WidgetTester tester) async {
      final GlobalKey<FormState> formKey = GlobalKey<FormState>();
      final TextEditingController controller = TextEditingController();

      await pumpForm(tester, EmailField(controller: controller), formKey: formKey);

      final FormFieldState emailField = tester.state(emailFieldFinder);

      // Not validated yet, so no error
      expect(emailField.hasError, isFalse);

      formKey.currentState!.validate();
      await tester.pumpAndSettle();
      // Empty, so error
      expect(emailField.hasError, isTrue);

      await tester.enterText(emailFieldFinder, '123noemail');
      formKey.currentState!.validate();
      await tester.pumpAndSettle();
      // Not real email, so error
      expect(emailField.hasError, isTrue);

      await tester.enterText(emailFieldFinder, 'motismitfahrapp@gmail.com');
      formKey.currentState!.validate();
      await tester.pumpAndSettle();
      // Real email, so no error
      expect(emailField.hasError, isFalse);
    });
  });

  group('String.isValidEmail', () {
    test('Returns true for valid email', () {
      expect('motismitfahrapp@gmail.com'.isValidEmail(), isTrue);
      expect('motis-mitfahr_app@gmx.net'.isValidEmail(), isTrue);
      expect('motis123mitfahr456app@custom789domain.de'.isValidEmail(), isTrue);
      expect('motis@mitfahrapp.tv'.isValidEmail(), isTrue);
    });

    test('Returns false for invalid email', () {
      expect('123noemail'.isValidEmail(), isFalse);
      expect('plainwrongemail'.isValidEmail(), isFalse);
      expect('two@at@signs'.isValidEmail(), isFalse);
      expect('twodots..in@row.com'.isValidEmail(), isFalse);
      expect('wrong@1234'.isValidEmail(), isFalse);
      expect(r'#@%^%#$@#$@#.com'.isValidEmail(), isFalse);
    });
  });
}
