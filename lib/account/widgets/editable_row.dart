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
    Widget titleWidget = Text(
      title,
      style: Theme.of(context).textTheme.titleLarge,
    );
    if (isEditable) {
      titleWidget = Semantics(
        label: S.of(context).edit,
        child: InkWell(
          onTap: onPressed,
          key: const Key('editableRowTitleButton'),
          child: Container(alignment: Alignment.center, height: 48, child: titleWidget),
        ),
      );
    }
    final Widget row = Row(
      children: <Widget>[
        titleWidget,
        if (isEditable)
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: S.of(context).edit,
                icon: const Icon(Icons.edit),
                key: const Key('editableRowIconButton'),
                onPressed: onPressed,
              ),
            ),
          ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        row,
        innerWidget,
      ],
    );
  }
}
