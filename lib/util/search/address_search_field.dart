import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'address_search_delegate.dart';
import 'address_suggestion.dart';

class AddressSearchField extends StatelessWidget {
  final AddressType addressType;
  final TextEditingController controller;
  final void Function(AddressSuggestion)? onSelected;

  const AddressSearchField({
    super.key,
    required this.addressType,
    required this.controller,
    this.onSelected,
  });

  factory AddressSearchField.start({
    required TextEditingController controller,
    void Function(AddressSuggestion)? onSelected,
  }) {
    return AddressSearchField(
      addressType: AddressType.start,
      controller: controller,
      onSelected: onSelected,
    );
  }

  factory AddressSearchField.destination({
    required TextEditingController controller,
    void Function(AddressSuggestion)? onSelected,
  }) {
    return AddressSearchField(
      addressType: AddressType.destination,
      controller: controller,
      onSelected: onSelected,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: getLabelText(context),
      tooltip: getHintText(context),
      excludeSemantics: true,
      child: ElevatedButton(
        onPressed: () async {
          final AddressSuggestion? addressSuggestion = await showSearch<AddressSuggestion?>(
            context: context,
            delegate: AddressSearchDelegate(),
            query: controller.text,
          );

          if (addressSuggestion != null) {
            controller.text = addressSuggestion.name;
            if (onSelected != null) onSelected!(addressSuggestion);
          }
        },
        child: Align(
          alignment: Alignment.centerLeft,
          child: controller.text != ""
              ? Text(controller.text)
              : Text(
                  getLabelText(context),
                  style: Theme.of(context).textTheme.bodyText1?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                      ),
                ),
        ),
      ),
    );
  }

  String getLabelText(BuildContext context) {
    switch (addressType) {
      case AddressType.start:
        return S.of(context).formAddressStart;
      case AddressType.destination:
        return S.of(context).formAddressDestination;
    }
  }

  String getHintText(BuildContext context) {
    switch (addressType) {
      case AddressType.start:
        return S.of(context).formAddressStartHint;
      case AddressType.destination:
        return S.of(context).formAddressDestinationHint;
    }
  }
}

enum AddressType { start, destination }
