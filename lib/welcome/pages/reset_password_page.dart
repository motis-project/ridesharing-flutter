import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:progress_state_button/progress_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../util/buttons/loading_button.dart';
import '../../util/fields/password_field.dart';
import '../../util/supabase_manager.dart';

class ResetPasswordPage extends StatefulWidget {
  final Function() onPasswordReset;

  const ResetPasswordPage({super.key, required this.onPasswordReset});

  @override
  State<ResetPasswordPage> createState() => ResetPasswordPageState();
}

class ResetPasswordPageState extends State<ResetPasswordPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).pageResetPasswordTitle),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            child: ResetPasswordForm(onPasswordReset: widget.onPasswordReset),
          ),
        ),
      ),
    );
  }
}

class ResetPasswordForm extends StatefulWidget {
  final Function() onPasswordReset;

  const ResetPasswordForm({super.key, required this.onPasswordReset});

  @override
  State<ResetPasswordForm> createState() => ResetPasswordFormState();
}

class ResetPasswordFormState extends State<ResetPasswordForm> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordConfirmationController = TextEditingController();
  ButtonState buttonState = ButtonState.idle;

  Future<void> onSubmit() async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      buttonState = ButtonState.loading;
    });

    final UserAttributes newAttributes = UserAttributes(password: passwordController.text);
    await supabaseManager.supabaseClient.auth.updateUser(newAttributes);

    // Will redirect to login screen if successful
    widget.onPasswordReset();
  }

  @override
  void dispose() {
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
            LoadingButton(
              idleText: S.of(context).pageResetPasswordButtonReset,
              onPressed: onSubmit,
              state: buttonState,
            )
          ],
        ),
      ),
    );
  }
}
