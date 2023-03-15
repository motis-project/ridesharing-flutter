import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ExpandableSection extends StatefulWidget {
  final bool isExpanded;
  final bool isExpandable;
  final Widget child;
  final String title;
  final void Function(bool expanded)? expansionCallback;
  const ExpandableSection({
    super.key,
    required this.child,
    required this.title,
    this.isExpanded = true,
    this.isExpandable = true,
    this.expansionCallback,
  });

  @override
  State<ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<ExpandableSection> {
  late bool _isExpanded;

  @override
  void initState() {
    _isExpanded = widget.isExpanded;
    super.initState();
  }

  @override
  void didUpdateWidget(ExpandableSection oldWidget) {
    if (oldWidget.isExpanded != widget.isExpanded) {
      setState(() => _isExpanded = widget.isExpanded);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final Widget header = Row(
      mainAxisAlignment: widget.isExpandable ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
      children: <Widget>[
        Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
        if (widget.isExpandable)
          ElevatedButton.icon(
            onPressed: () => setState(() {
              _isExpanded = !_isExpanded;
              widget.expansionCallback?.call(_isExpanded);
            }),
            icon: _isExpanded ? const Icon(Icons.expand_less) : const Icon(Icons.expand_more),
            label: Text(_isExpanded ? S.of(context).retract : S.of(context).expand),
          ),
      ],
    );
    if (!_isExpanded) {
      return header;
    }
    return Column(
      children: <Widget>[
        header,
        const SizedBox(height: 10),
        widget.child,
      ],
    );
  }
}
