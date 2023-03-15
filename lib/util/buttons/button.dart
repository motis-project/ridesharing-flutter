import 'package:flutter/material.dart';

import 'display_color_kind.dart';

class Button extends StatelessWidget {
  final String text;
  final DisplayColorKind displayColorKind;
  final Color? backgroundColor;
  final Color? textColor;
  final VoidCallback? onPressed;
  final ButtonKind kind;

  const Button(
    this.text, {
    super.key,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.displayColorKind = DisplayColorKind.primary,
    this.kind = ButtonKind.big,
  });

  factory Button.error(String text, {VoidCallback? onPressed, Key? key}) {
    return Button(
      text,
      onPressed: onPressed,
      displayColorKind: DisplayColorKind.error,
      key: key,
    );
  }

  factory Button.disabled(String text, {Key? key}) {
    return Button(
      text,
      displayColorKind: DisplayColorKind.disabled,
      key: key,
    );
  }

  factory Button.submit(String text, {VoidCallback? onPressed, Key? key}) {
    return Button(
      text,
      onPressed: onPressed,
      kind: ButtonKind.submit,
      key: key,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: kind == ButtonKind.big ? double.infinity : 170,
      height: 53,
      child: MaterialButton(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        color: getBackgroundColor(context),
        disabledColor: onPressed == null ? getBackgroundColor(context) : null,
        onPressed: onPressed,
        child: Text(
          kind == ButtonKind.big ? text.toUpperCase() : text,
          style: TextStyle(
            color: getTextColor(context),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Color getBackgroundColor(BuildContext context) {
    return backgroundColor ?? displayColorKind.getBackgroundColor(context);
  }

  Color getTextColor(BuildContext context) {
    return textColor ?? displayColorKind.getColor(context);
  }
}

enum ButtonKind { big, submit }
