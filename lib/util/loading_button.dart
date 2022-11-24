import 'package:flutter/material.dart';
import 'package:flutter_app/util/own_theme_fields.dart';
import 'package:progress_state_button/iconed_button.dart';
import 'package:progress_state_button/progress_button.dart';

class LoadingButton extends StatefulWidget {
  final Function? onPressed;
  final ButtonState? state;
  final Icon? idleIcon;
  final String? idleText;
  final String? failText;
  final String? successText;
  const LoadingButton(
      {super.key,
      this.onPressed,
      this.state,
      this.idleIcon,
      this.idleText,
      this.failText,
      this.successText});

  @override
  State<LoadingButton> createState() => _LoadingButtonState();
}

class _LoadingButtonState extends State<LoadingButton> {
  @override
  Widget build(BuildContext context) {
    return ProgressButton.icon(
      iconedButtons: {
        ButtonState.idle: IconedButton(
          text: widget.idleText ?? "Submit",
          icon: widget.idleIcon ??
              Icon(
                Icons.send,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
          color: Theme.of(context).colorScheme.primary,
        ),
        ButtonState.loading:
            IconedButton(color: Theme.of(context).colorScheme.primary),
        ButtonState.fail: IconedButton(
          text: widget.failText ?? "Failed",
          icon: Icon(
            Icons.cancel,
            color: Theme.of(context).colorScheme.onError,
          ),
          color: Theme.of(context).colorScheme.error,
        ),
        ButtonState.success: IconedButton(
          text: widget.successText ?? "Success",
          icon: Icon(
            Icons.check_circle,
            color: Theme.of(context).own().onSuccess,
          ),
          color: Theme.of(context).own().success,
        )
      },
      onPressed: widget.onPressed,
      state: widget.state,
      textStyle: TextStyle(
        color: Theme.of(context).colorScheme.onPrimary,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
