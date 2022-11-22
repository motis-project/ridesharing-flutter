import 'package:flutter/material.dart';

class SubmitButton extends StatelessWidget {
  final String text;
  final Function()? onPressed;
  final double borderRadius = 16;

  const SubmitButton({super.key, required this.text, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
                color: Colors.blue.withOpacity(0.1),
                blurRadius: 1,
                offset: const Offset(0, -5))
          ],
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: const LinearGradient(
              colors: [Colors.orange, Colors.cyan],
              begin: FractionalOffset(0.1, 0.1),
              end: FractionalOffset(0.9, 0.9))),
      child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius))),
          onPressed: onPressed,
          child: Text(
            text.toUpperCase(),
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          )),
    );
  }
}
