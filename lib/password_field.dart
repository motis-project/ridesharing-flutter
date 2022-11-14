import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';

class PasswordField extends StatelessWidget {
  final String labelText;
  final String hintText;

  const PasswordField({key, required this.labelText, this.hintText = ""})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
        decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: labelText,
            hintText: hintText),
        obscureText: true,
        enableSuggestions: false,
        autocorrect: false);
  }
}
