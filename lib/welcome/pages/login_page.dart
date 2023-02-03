import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:progress_state_button/progress_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../util/buttons/loading_button.dart';
import '../../util/fields/email_field.dart';
import '../../util/fields/password_field.dart';
import '../../util/snackbar.dart';
import '../../util/supabase_manager.dart';
import 'forgot_password_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).pageLoginTitle),
      ),
      body: const Center(
        child: CustomScrollView(
          physics: ClampingScrollPhysics(),
          slivers: <Widget>[
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                child: LoginForm(),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => LoginFormState();
}

class LoginFormState extends State<LoginForm> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  ButtonState buttonState = ButtonState.idle;

  Future<void> onSubmit() async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      buttonState = ButtonState.loading;
    });

    try {
      await supabaseManager.supabaseClient.auth.signInWithPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      setState(() {
        buttonState = ButtonState.success;
      });
    } on AuthException catch (e) {
      await fail();

      if (!mounted) return;

      final String message = e.statusCode == '400'
          ? e.message.contains('credentials')
              ? S.of(context).pageLoginFailureCredentials
              : S.of(context).pageLoginFailureEmailNotConfirmed
          : S.of(context).failureSnackBar;

      showSnackBar(context, message);
    }
  }

  Future<void> fail() async {
    setState(() {
      buttonState = ButtonState.fail;
    });
    await Future<void>.delayed(const Duration(seconds: 2));
    setState(() {
      buttonState = ButtonState.idle;
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: buttonState == ButtonState.loading || buttonState == ButtonState.success,
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Expanded(child: Container()),
            EmailField(controller: emailController),
            const SizedBox(height: 15),
            PasswordField(controller: passwordController),
            TextButton(
              key: const Key('loginForgotPasswordButton'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => ForgotPasswordPage(initialEmail: emailController.text),
                  ),
                );
              },
              child: Text(S.of(context).pageLoginButtonForgotPassword),
            ),
            Hero(
              tag: 'LoginButton',
              transitionOnUserGestures: true,
              child: LoadingButton(onPressed: onSubmit, state: buttonState),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: TextButton(
                  key: const Key('loginNoAccountButton'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) => const RegisterPage(),
                      ),
                    );
                  },
                  child: Text(S.of(context).pageLoginNoAccount),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
