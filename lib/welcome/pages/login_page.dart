import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:progress_state_button/progress_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../util/buttons/loading_button.dart';
import '../../util/fields/email_field.dart';
import '../../util/fields/password_field.dart';
import '../../util/supabase.dart';
import 'forgot_password_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
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
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  ButtonState _state = ButtonState.idle;

  Future<void> onSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _state = ButtonState.loading;
      });
      try {
        await SupabaseManager.supabaseClient.auth.signInWithPassword(
          email: emailController.text,
          password: passwordController.text,
        );
        setState(() {
          _state = ButtonState.success;
        });
      } on AuthException catch (e) {
        fail();
        // looks weird but needed later for i18n
        String text = e.statusCode == '400'
            ? e.message.contains('credentials')
                ? S.of(context).pageLoginFailureCredentials
                : S.of(context).pageLoginFailureEmailNotConfirmed
            : S.of(context).failureSnackBar;

        SemanticsService.announce(text, TextDirection.ltr);

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(text),
        ));
      }
    } else {
      fail();
    }
  }

  Future<void> fail() async {
    setState(() {
      _state = ButtonState.fail;
    });
    await Future<void>.delayed(const Duration(seconds: 2));
    setState(() {
      _state = ButtonState.idle;
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
      absorbing: _state == ButtonState.loading || _state == ButtonState.success,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Expanded(child: Container()),
            EmailField(controller: emailController),
            const SizedBox(height: 15),
            PasswordField(
              labelText: S.of(context).formPassword,
              hintText: S.of(context).formPasswordHint,
              controller: passwordController,
              validator: (String? value) {
                if (value == null || value.isEmpty) {
                  return S.of(context).formPasswordValidateEmpty;
                }
                return null;
              },
            ),
            TextButton(
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
              child: LoadingButton(onPressed: onSubmit, state: _state),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: TextButton(
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
