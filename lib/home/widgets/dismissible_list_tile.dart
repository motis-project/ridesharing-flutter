import 'package:flutter/material.dart';

import '../../util/own_theme_fields.dart';

class DismissibleListTile extends StatelessWidget {
  final Key dismissibleKey;

  final void Function(DismissDirection)? onDismissed;
  final String semanticsLabel;

  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;

  final VoidCallback? onTap;
  const DismissibleListTile({
    super.key,
    required this.dismissibleKey,
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
      key: dismissibleKey,
      onDismissed: onDismissed,
      background: buildBackground(context: context),
      secondaryBackground: buildBackground(context: context, secondary: true),
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

  Widget buildBackground({required BuildContext context, bool secondary = false}) {
    final Icon icon = Icon(Icons.check, size: 32, color: Theme.of(context).own().onSuccess);
    return Card(
      color: Theme.of(context).own().success,
      child: ListTile(
        subtitle: Container(),
        leading: secondary ? null : icon,
        trailing: secondary ? icon : null,
      ),
    );
  }
}
