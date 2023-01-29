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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (isEditable)
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: S.of(context).edit,
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      print('Test');
                      onPressed();
                    },
                    key: const Key('editButton'),
                  ),
                ),
              ),
          ],
        ),
        innerWidget,
      ],
    );
  }
}
