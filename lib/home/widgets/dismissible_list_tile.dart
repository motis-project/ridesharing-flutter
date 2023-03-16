import 'package:flutter/material.dart';

import '../../util/own_theme_fields.dart';

class DismissibleListTile extends StatelessWidget {
  final void Function(DismissDirection)? onDismissed;
  final String semanticsLabel;

  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;

  final VoidCallback? onTap;
  const DismissibleListTile({
    required super.key,
    this.onDismissed,
    required this.semanticsLabel,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: key!,
      onDismissed: onDismissed,
      background: Card(color: Theme.of(context).own().success),
      child: Card(
        child: Semantics(
          label: semanticsLabel,
          child: InkWell(
            child: ListTile(
              leading: leading,
              title: title,
              subtitle: subtitle,
              trailing: trailing,
              onTap: onTap,
            ),
          ),
        ),
      ),
    );
  }
}
