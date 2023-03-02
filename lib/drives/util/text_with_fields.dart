import 'package:flutter/material.dart';

class TextWithFields extends StatelessWidget {
  final String text;
  final List<Widget> fields;
  final Widget? separator;

  static const String placeholder = 'XYZ';

  const TextWithFields(this.text, {super.key, required this.fields, this.separator});

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = <Widget>[];
    final List<String> parts = text.split(placeholder);
    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        children.add(Text(parts[i]));
      }

      if (i < fields.length) {
        children.add(fields[i]);
      }
    }
    if (separator != null) {
      for (int i = 1; i < children.length; i += 2) {
        children.insert(i, separator!);
      }
    }
    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }
}
