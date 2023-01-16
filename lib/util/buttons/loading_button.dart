import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:progress_state_button/iconed_button.dart';
import 'package:progress_state_button/progress_button.dart';

import '../own_theme_fields.dart';

class LoadingButton extends StatefulWidget {
  final Function? onPressed;
  final ButtonState? state;
  final Icon? idleIcon;
  final String? idleText;
  final String? failText;
  final String? successText;
  const LoadingButton(
      {super.key, this.onPressed, this.state, this.idleIcon, this.idleText, this.failText, this.successText});

  @override
  State<LoadingButton> createState() => _LoadingButtonState();
}

class _LoadingButtonState extends State<LoadingButton> {
  @override
  Widget build(BuildContext context) {
    return ProgressButton.icon(
      iconedButtons: {
        ButtonState.idle: IconedButton(
          text: widget.idleText ?? S.of(context).formSubmit,
          icon: widget.idleIcon ??
              Icon(
                Icons.send,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
          color: Theme.of(context).colorScheme.primary,
        ),
        ButtonState.loading: IconedButton(color: Theme.of(context).colorScheme.primary),
        ButtonState.fail: IconedButton(
          text: widget.failText ?? S.of(context).formSubmitFail,
          icon: Icon(
            Icons.cancel,
            color: Theme.of(context).colorScheme.onError,
          ),
          color: Theme.of(context).colorScheme.error,
        ),
        ButtonState.success: IconedButton(
          text: widget.successText ?? S.of(context).formSubmitSuccess,
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
        color: getTextColor(context),
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Color getTextColor(BuildContext context) {
    switch (widget.state) {
      case ButtonState.fail:
        return Theme.of(context).colorScheme.onError;
      case ButtonState.success:
        return Theme.of(context).own().onSuccess;
      default:
        return Theme.of(context).colorScheme.onPrimary;
    }
  }
}
