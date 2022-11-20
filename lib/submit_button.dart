import 'package:flutter/material.dart';

class SubmitButton extends StatelessWidget {
  final String text;
  final Function()? onPressed;

  const SubmitButton({super.key, required this.text, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: submitButtonHeight,
      child: MaterialButton(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(submitButtonBorderRadius)),
        color: Theme.of(context).colorScheme.primary,
        onPressed: onPressed,
        child: Text(
          text.toUpperCase(),
          style: submitButtonTextStyle(context),
        ),
      ),
    );
  }
}

TextStyle submitButtonTextStyle(BuildContext context) =>
    TextStyle(fontSize: 20, color: Theme.of(context).colorScheme.onPrimary);

double submitButtonHeight = 53;
double submitButtonBorderRadius = 16;
