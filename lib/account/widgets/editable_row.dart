import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class EditableRow extends StatelessWidget {
  final String title;
  final Widget innerWidget;
  final bool isEditable;
  final VoidCallback onPressed;

  const EditableRow({
    super.key,
    required this.title,
    required this.innerWidget,
    required this.isEditable,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    Widget row = Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 6, 8),
      child: Row(
        children: <Widget>[
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (isEditable)
            const Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Icon(Icons.edit),
              ),
            ),
        ],
      ),
    );
    if (isEditable) {
      row = Semantics(
        tooltip: S.of(context).edit,
        child: InkWell(
          onTap: onPressed,
          key: const Key('editButton'),
          child: row,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        row,
        innerWidget,
      ],
    );
  }
}
