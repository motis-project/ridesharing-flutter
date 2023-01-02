import 'package:flutter/material.dart';

class IconWidget extends StatelessWidget {
  final Widget icon;
  final int count;
  const IconWidget({super.key, required this.icon, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: count <= 2
          ? List.generate(count, (index) => icon)
          : [
              icon,
              const SizedBox(width: 2),
              Text("x$count"),
            ],
    );
  }
}
