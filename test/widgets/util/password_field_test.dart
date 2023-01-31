import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/util/fields/password_field.dart';

import '../../util/pump_material.dart';

void main() {
  group('PasswordField', () {
    final Finder passwordFieldFinder = find.descendant(
      of: find.byType(PasswordField),
      matching: find.byType(TextFormField),
    );

    const String invalidPassword = 'abcdefg';
    const String validPassword = 'abc&EFG0';

    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    late TextEditingController controller;

    setUp(() {
      controller = TextEditingController();
    });

    testWidgets('Validates the password (only empty by default)', (WidgetTester tester) async {
      await pumpForm(tester, PasswordField(controller: controller), formKey: formKey);

      final FormFieldState passwordField = tester.state(passwordFieldFinder);

      // Not validated yet, so no error
      expect(passwordField.hasError, isFalse);

      formKey.currentState!.validate();
      await tester.pumpAndSettle();
      // Empty, so error
      expect(passwordField.hasError, isTrue);

      await tester.enterText(passwordFieldFinder, 'abcdefg');
      formKey.currentState!.validate();
      await tester.pumpAndSettle();
      // Not empty, so no error
      expect(passwordField.hasError, isFalse);
    });

    testWidgets('Validates the password strictly if wanted', (WidgetTester tester) async {
      await pumpForm(tester, PasswordField(controller: controller, validateStrictly: true), formKey: formKey);

      final FormFieldState passwordField = tester.state(passwordFieldFinder);

      // Not validated yet, so no error
      expect(passwordField.hasError, isFalse);

      formKey.currentState!.validate();
      await tester.pumpAndSettle();
      // Empty, so error
      expect(passwordField.hasError, isTrue);

      await tester.enterText(passwordFieldFinder, 'abcdefg');
      formKey.currentState!.validate();
      await tester.pumpAndSettle();
      // Too short, so error
      expect(passwordField.hasError, isTrue);

      await tester.enterText(passwordFieldFinder, 'abcdefgh');
      formKey.currentState!.validate();
      await tester.pumpAndSettle();
      // No number, so error
      expect(passwordField.hasError, isTrue);

      await tester.enterText(passwordFieldFinder, 'abcdefg0');
      formKey.currentState!.validate();
      await tester.pumpAndSettle();
      // No capital letters, so error
      expect(passwordField.hasError, isTrue);

      await tester.enterText(passwordFieldFinder, 'ABCDEFG0');
      formKey.currentState!.validate();
      await tester.pumpAndSettle();
      // No lower letters, so error
      expect(passwordField.hasError, isTrue);

      await tester.enterText(passwordFieldFinder, 'abcdEFG0');
      formKey.currentState!.validate();
      await tester.pumpAndSettle();
      // No special, so error
      expect(passwordField.hasError, isTrue);

      await tester.enterText(passwordFieldFinder, validPassword);
      formKey.currentState!.validate();
      await tester.pumpAndSettle();
      expect(passwordField.hasError, isFalse);
    });

    testWidgets('Validates the password as confirmation', (WidgetTester tester) async {
      final TextEditingController originalController = TextEditingController(text: invalidPassword);

      await pumpForm(
        tester,
        PasswordField(controller: controller, originalPasswordController: originalController),
        formKey: formKey,
      );

      final FormFieldState passwordField = tester.state(passwordFieldFinder);

      // Not validated yet, so no error
      expect(passwordField.hasError, isFalse);

      formKey.currentState!.validate();
      await tester.pumpAndSettle();
      // Empty, so error
      expect(passwordField.hasError, isTrue);

      await tester.enterText(passwordFieldFinder, validPassword);
      formKey.currentState!.validate();
      await tester.pumpAndSettle();
      // Not the same, so error
      expect(passwordField.hasError, isTrue);

      await tester.enterText(passwordFieldFinder, invalidPassword);
      formKey.currentState!.validate();
      await tester.pumpAndSettle();
      // The same, so no error
      expect(passwordField.hasError, isFalse);
    });

    testWidgets('Can toggle visibility of entered text', (WidgetTester tester) async {
      await pumpForm(tester, PasswordField(controller: controller), formKey: formKey);

      final Finder innerTextFieldFinder = find.descendant(
        of: passwordFieldFinder,
        matching: find.byType(TextField),
      );

      TextField innerTextField = tester.widget(innerTextFieldFinder);
      expect(innerTextField.obscureText, isTrue);

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();
      innerTextField = tester.widget(innerTextFieldFinder);
      expect(innerTextField.obscureText, isFalse);

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();
      innerTextField = tester.widget(innerTextFieldFinder);
      expect(innerTextField.obscureText, isTrue);
    });

    testWidgets('It is impossible to have confirmation AND strict validation', (WidgetTester tester) async {
      expect(() async {
        await pumpForm(
          tester,
          PasswordField(
            controller: controller,
            originalPasswordController: TextEditingController(),
            validateStrictly: true,
          ),
          formKey: formKey,
        );
      }, throwsAssertionError);
    });
  });
}
