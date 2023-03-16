import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LabeledCheckbox extends StatelessWidget {
  const LabeledCheckbox({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      tooltip: S.of(context).toggle,
      child: InkWell(
        onTap: () {
          onChanged(!value);
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Checkbox(
              value: value,
              onChanged: null,
              fillColor: MaterialStateProperty.resolveWith(
                (Set<MaterialState> states) => states.contains(MaterialState.selected)
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).disabledColor,
              ),
            ),
            Text(label),
            const SizedBox(width: 10)
          ],
        ),
      ),
    );
  }
}
