import 'package:flutter/material.dart';

class PasswordField extends StatelessWidget {
  final String labelText;
  final String hintText;
  final String? errorText;
  final String? helperText;
  final String? Function(String?)? validator;
  final TextEditingController? controller;

  const PasswordField(
      {key,
      required this.labelText,
      this.hintText = "",
      this.errorText,
      this.helperText,
      this.controller,
      this.validator})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
        decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: labelText,
            hintText: hintText,
            errorText: errorText,
            helperText: helperText),
        obscureText: true,
        enableSuggestions: false,
        autocorrect: false,
        keyboardType: TextInputType.visiblePassword,
        controller: controller,
        validator: validator);
  }
}
