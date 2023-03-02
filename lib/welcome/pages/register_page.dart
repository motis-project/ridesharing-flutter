import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:progress_state_button/progress_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../account/models/profile.dart';
import '../../util/buttons/loading_button.dart';
import '../../util/fields/email_field.dart';
import '../../util/fields/password_field.dart';
import '../../util/snackbar.dart';
import '../../util/supabase_manager.dart';
import 'after_registration_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).pageRegisterTitle),
      ),
      body: const Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            child: RegisterForm(),
          ),
        ),
      ),
    );
  }
}

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => RegisterFormState();
}

class RegisterFormState extends State<RegisterForm> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordConfirmationController = TextEditingController();
  ButtonState buttonState = ButtonState.idle;

  Future<void> onSubmit() async {
    if (!formKey.currentState!.validate()) return;

    late final AuthResponse res;
    try {
      setState(() {
        buttonState = ButtonState.loading;
      });
      res = await supabaseManager.supabaseClient.auth.signUp(
        password: passwordController.text,
        email: emailController.text,
        emailRedirectTo: 'io.supabase.flutter://login-callback/',
        data: <String, dynamic>{
          'username': usernameController.text,
        },
      );
    } on AuthException {
      return fail();
    }

    if (res.user == null) {
      return fail();
    }

    await Future<void>.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (BuildContext context) => const AfterRegistrationPage()),
      );
    }
  }

  Future<void> fail() async {
    showSnackBar(context, S.of(context).failureSnackBar);

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
    usernameController.dispose();
    passwordController.dispose();
    passwordConfirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: buttonState == ButtonState.loading || buttonState == ButtonState.success,
      child: Form(
        key: formKey,
        child: Column(
          children: <Widget>[
            EmailField(controller: emailController),
            const SizedBox(height: 15),
            TextFormField(
              maxLength: Profile.maxUsernameLength,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: S.of(context).pageRegisterUsername,
                hintText: S.of(context).pageRegisterUsernameHint,
              ),
              key: const Key('registerUsernameField'),
              controller: usernameController,
              validator: (String? value) {
                if (value == null || value.isEmpty) {
                  return S.of(context).pageRegisterUsernameValidateEmpty;
                }
                return null;
              },
            ),
            const SizedBox(height: 15),
            PasswordField(
              controller: passwordController,
              validateSecurity: true,
            ),
            const SizedBox(height: 15),
            PasswordField(
              controller: passwordConfirmationController,
              originalPasswordController: passwordController,
            ),
            const SizedBox(height: 15),
            Hero(
              tag: 'RegisterButton',
              transitionOnUserGestures: true,
              child: LoadingButton(
                idleText: S.of(context).pageRegisterButtonCreate,
                successText: S.of(context).pageRegisterButtonCreated,
                onPressed: onSubmit,
                state: buttonState,
              ),
            )
          ],
        ),
      ),
    );
  }
}
