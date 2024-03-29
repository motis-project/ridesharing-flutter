import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:motis_mitfahr_app/managers/supabase_manager.dart';
import 'package:motis_mitfahr_app/util/buttons/loading_button.dart';
import 'package:motis_mitfahr_app/util/fields/email_field.dart';
import 'package:motis_mitfahr_app/welcome/pages/forgot_password_page.dart';
import 'package:progress_state_button/progress_button.dart';

import '../../test_util/mocks/mock_server.dart';
import '../../test_util/mocks/navigator_observer.mocks.dart';
import '../../test_util/mocks/request_processor.dart';
import '../../test_util/mocks/request_processor.mocks.dart';
import '../../test_util/pump_material.dart';

void main() {
  final MockRequestProcessor processor = MockRequestProcessor();
  final MockNavigatorObserver navigatorObserver = MockNavigatorObserver();
  const String email = 'motismitfahrapp@gmail.com';

  setUpAll(() async {
    MockServer.setProcessor(processor);
    supabaseManager.currentProfile = null;
  });

  group('ForgotPasswordPage', () {
    final Finder emailFieldFinder = find.descendant(of: find.byType(EmailField), matching: find.byType(TextFormField));
    final Finder forgotPasswordButtonFinder = find.byType(LoadingButton);

    testWidgets('Shows the email form', (WidgetTester tester) async {
      await pumpMaterial(tester, const ForgotPasswordPage());

      final Finder forgotPasswordFormFinder = find.byType(ForgotPasswordForm);
      final ForgotPasswordFormState formState = tester.state(forgotPasswordFormFinder);

      expect(formState.buttonState, ButtonState.idle);
      expect(find.byType(ForgotPasswordForm), findsOneWidget);
      expect(find.byType(EmailField), findsOneWidget);
    });

    testWidgets('Can handle initial email', (WidgetTester tester) async {
      await pumpMaterial(tester, const ForgotPasswordPage(initialEmail: email));

      final TextFormField emailField = tester.widget(emailFieldFinder);
      expect(emailField.controller!.text, email);
    });

    group('submitting the form', () {
      testWidgets('Fails if form is not filled validly', (WidgetTester tester) async {
        await pumpMaterial(
          tester,
          const ForgotPasswordPage(initialEmail: '123noemail'),
          navigatorObserver: navigatorObserver,
        );

        await tester.tap(forgotPasswordButtonFinder);
        await tester.pump();

        final FormFieldState emailField = tester.state(emailFieldFinder);
        expect(emailField.hasError, isTrue);

        verifyNever(navigatorObserver.didPop(any, any));
      });

      testWidgets('Shows success if form is valid (even if no such account)', (WidgetTester tester) async {
        await pumpMaterial(
          tester,
          const ForgotPasswordPage(initialEmail: email),
          navigatorObserver: navigatorObserver,
        );

        whenRequest(
          processor,
          urlMatcher: startsWith('/auth/v1/recover'),
          bodyMatcher: containsPair('email', email),
          methodMatcher: equals('POST'),
        ).thenReturnJson('');

        await tester.tap(forgotPasswordButtonFinder);
        await tester.pump();

        final ForgotPasswordFormState forgotPasswordFormState = tester.state(find.byType(ForgotPasswordForm));
        expect(forgotPasswordFormState.buttonState, ButtonState.loading);

        await tester.pump(const Duration(milliseconds: 600));

        expect(forgotPasswordFormState.buttonState, ButtonState.success);

        await tester.pump(const Duration(seconds: 2));

        verify(navigatorObserver.didPop(any, any)).called(1);
      });
    });

    testWidgets('Accessibility', (WidgetTester tester) async {
      await expectMeetsAccessibilityGuidelines(tester, const ForgotPasswordPage());
    });
  });
}
