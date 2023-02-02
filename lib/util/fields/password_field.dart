import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PasswordField extends StatefulWidget {
  static const Key passwordFieldKey = Key('passwordField');
  static const Key passwordConfirmationFieldKey = Key('passwordConfirmationField');

  final TextEditingController controller;
  final TextEditingController? originalPasswordController;
  final bool validateSecurity;

  const PasswordField({
    super.key,
    required this.controller,
    this.originalPasswordController,
    this.validateSecurity = false,
  }) : assert(validateSecurity == false || originalPasswordController == null);

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: key,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: labelText,
        hintText: hintText,
        helperText: helperText,
        helperMaxLines: 2,
        suffixIcon: IconButton(
          icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        ),
      ),
      obscureText: _obscureText,
      enableSuggestions: false,
      autocorrect: false,
      keyboardType: TextInputType.visiblePassword,
      controller: widget.controller,
      onChanged: (_) => setState(() {}),
      validator: validator,
    );
  }

  bool get isConfirmation => widget.originalPasswordController != null;

  String get labelText => isConfirmation ? S.of(context).formPasswordConfirm : S.of(context).formPassword;
  String get hintText => isConfirmation
      ? S.of(context).formPasswordConfirmHint
      : widget.validateSecurity
          ? S.of(context).formPasswordChooseHint
          : S.of(context).formPasswordHint;

  Key get key =>
      widget.key ?? (isConfirmation ? PasswordField.passwordConfirmationFieldKey : PasswordField.passwordFieldKey);

  String? Function(String?) get validator => isConfirmation
      ? _validateConfirmation
      : widget.validateSecurity
          ? _validateSecurity
          : _validateOnlyEmpty;

  String? get helperText {
    if (!widget.validateSecurity) return null;

    final String text = widget.controller.text;
    if (text.isEmpty) return null;

    return _validateSecurity(text);
  }

  String? _validateConfirmation(String? value) {
    if (value == null || value.isEmpty) {
      return S.of(context).formPasswordConfirmValidateEmpty;
    } else if (value != widget.originalPasswordController?.text) {
      return S.of(context).formPasswordConfirmValidateMatch;
    }
    return null;
  }

  String? _validateOnlyEmpty(String? value) {
    if (value == null || value.isEmpty) {
      return S.of(context).formPasswordValidateEmpty;
    }
    return null;
  }

  String? _validateSecurity(String? value) {
    if (value == null || value.isEmpty) {
      return S.of(context).formPasswordValidateEmpty;
    } else if (value.length < 8) {
      return S.of(context).formPasswordValidateMinLength;
    } else if (RegExp('[0-9]').hasMatch(value) == false) {
      return S.of(context).formPasswordValidateNumber;
    } else if (RegExp('[A-Z]').hasMatch(value) == false) {
      return S.of(context).formPasswordValidateUppercase;
    } else if (RegExp('[a-z]').hasMatch(value) == false) {
      return S.of(context).formPasswordValidateLowercase;
    } else if (RegExp('[^A-z0-9]').hasMatch(value) == false) {
      return S.of(context).formPasswordValidateSpecial;
    }
    return null;
  }
}
