import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

extension EmailValidator on String {
  bool isValidEmail() {
    return RegExp(
            r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$')
        .hasMatch(this);
  }
}

class EmailField extends StatelessWidget {
  final TextEditingController? controller;

  const EmailField({key, this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: S.of(context).formEmail,
        hintText: S.of(context).formEmailHint,
      ),
      keyboardType: TextInputType.emailAddress,
      controller: controller,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return S.of(context).formEmailValidateEmpty;
        } else if (!value.isValidEmail()) {
          return S.of(context).formEmailValidateInvalid;
        }
        return null;
      },
    );
  }
}
