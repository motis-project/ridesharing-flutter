import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:progress_state_button/progress_button.dart';
import 'package:motis_mitfahr_app/util/supabase.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../util/buttons/loading_button.dart';
import '../../util/fields/email_field.dart';

class ForgotPasswordPage extends StatefulWidget {
  final String? initialEmail;
  const ForgotPasswordPage({super.key, this.initialEmail = ""});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
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
  const ForgotPasswordForm({super.key, this.initialEmail = ""});

  @override
  State<ForgotPasswordForm> createState() => _ForgotPasswordFormState();
}

class _ForgotPasswordFormState extends State<ForgotPasswordForm> {
  ButtonState _state = ButtonState.idle;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController emailController;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController(text: widget.initialEmail);
  }

  void onSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _state = ButtonState.loading;
      });

      SupabaseManager.supabaseClient.auth.resetPasswordForEmail(
        emailController.text,
        redirectTo: kIsWeb ? null : 'io.supabase.flutter://reset-callback/',
      );

      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _state = ButtonState.success;
      });
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.of(context).pop();
      }
    } else {
      fail();
    }
  }

  void fail() async {
    setState(() {
      _state = ButtonState.fail;
    });
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _state = ButtonState.idle;
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: _state == ButtonState.loading || _state == ButtonState.success,
      child: Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            EmailField(
              controller: emailController,
            ),
            const SizedBox(height: 15),
            LoadingButton(
              onPressed: onSubmit,
              state: _state,
              idleText: S.of(context).pageForgotPasswordButtonSend,
              successText: S.of(context).pageForgotPasswordButtonSent,
            )
          ],
        ),
      ),
    );
  }
}
