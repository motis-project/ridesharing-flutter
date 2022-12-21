import 'package:flutter/material.dart';
import 'package:motis_mitfahr_app/util/own_theme_fields.dart';
import 'package:progress_state_button/iconed_button.dart';
import 'package:progress_state_button/progress_button.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
        color: widget.state == ButtonState.fail
            ? Theme.of(context).colorScheme.onError
            : widget.state == ButtonState.success
                ? Theme.of(context).own().onSuccess
                : Theme.of(context).colorScheme.onPrimary,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
