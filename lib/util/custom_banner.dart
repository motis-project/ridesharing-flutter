import 'package:flutter/material.dart';

class CustomBanner extends StatelessWidget {
  final Color? color;
  final Color backgroundColor;
  final String text;

  const CustomBanner({super.key, this.color, required this.backgroundColor, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color ?? Theme.of(context).colorScheme.onSurface,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
