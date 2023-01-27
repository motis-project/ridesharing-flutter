import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:progress_state_button/progress_button.dart';

import '../../util/buttons/loading_button.dart';
import '../../util/fields/email_field.dart';
import '../../util/supabase.dart';

class ForgotPasswordPage extends StatefulWidget {
  final String? initialEmail;
  const ForgotPasswordPage({super.key, this.initialEmail = ''});

  @override
  State<ForgotPasswordPage> createState() => ForgotPasswordPageState();
}

class ForgotPasswordPageState extends State<ForgotPasswordPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).pageForgotPasswordTitle),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            child: ForgotPasswordForm(
              initialEmail: widget.initialEmail,
            ),
          ),
        ),
      ),
    );
  }
}

class ForgotPasswordForm extends StatefulWidget {
  final String? initialEmail;
  const ForgotPasswordForm({super.key, this.initialEmail = ''});

  @override
  State<ForgotPasswordForm> createState() => ForgotPasswordFormState();
}

class ForgotPasswordFormState extends State<ForgotPasswordForm> {
  ButtonState buttonState = ButtonState.idle;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late final TextEditingController emailController;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController(text: widget.initialEmail);
  }

  Future<void> onSubmit() async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      buttonState = ButtonState.loading;
    });

    await SupabaseManager.supabaseClient.auth.resetPasswordForEmail(
      emailController.text,
      redirectTo: kIsWeb ? null : 'io.supabase.flutter://reset-callback/',
    );

    await Future<void>.delayed(const Duration(milliseconds: 500));
    setState(() {
      buttonState = ButtonState.success;
    });
    await Future<void>.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    emailController.dispose();
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
            EmailField(
              key: const Key('forgotPasswordEmailField'),
              controller: emailController,
            ),
            const SizedBox(height: 15),
            LoadingButton(
              onPressed: onSubmit,
              state: buttonState,
              idleText: S.of(context).pageForgotPasswordButtonSend,
              successText: S.of(context).pageForgotPasswordButtonSent,
            )
          ],
        ),
      ),
    );
  }
}
