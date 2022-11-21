import 'package:flutter/material.dart';

class BigButton extends StatelessWidget {
  final String text;
  final Function()? onPressed;
  const BigButton({super.key, required this.text, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 53,
      child: MaterialButton(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        color: Theme.of(context).colorScheme.primary,
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
