import 'package:flutter/material.dart';
import 'package:motis_mitfahr_app/util/search/address_search_delegate.dart';
import 'package:motis_mitfahr_app/util/search/address_suggestion.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AddressSearchField extends StatelessWidget {
  final AddressType addressType;
  final TextEditingController controller;
  final void Function(AddressSuggestion) onSelected;

  const AddressSearchField({
    super.key,
    required this.addressType,
    required this.controller,
    required this.onSelected,
  });

  factory AddressSearchField.start({
    required TextEditingController controller,
    required void Function(AddressSuggestion) onSelected,
  }) {
    return AddressSearchField(
      addressType: AddressType.start,
      controller: controller,
      onSelected: onSelected,
    );
  }

  factory AddressSearchField.destination({
    required TextEditingController controller,
    required void Function(AddressSuggestion) onSelected,
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
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: getLabelText(context),
          hintText: getHintText(context),
        ),
        readOnly: true,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return getValidatorEmptyText(context);
          }
          return null;
        },
        onTap: () async {
          final AddressSuggestion? addressSuggestion = await showSearch<AddressSuggestion?>(
            context: context,
            delegate: AddressSearchDelegate(),
            query: controller.text,
          );

          if (addressSuggestion != null) {
            controller.text = addressSuggestion.name;
            onSelected(addressSuggestion);
          }
        },
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

  String getValidatorEmptyText(BuildContext context) {
    switch (addressType) {
      case AddressType.start:
        return S.of(context).formAddressStartValidateEmpty;
      case AddressType.destination:
        return S.of(context).formAddressDestinationValidateEmpty;
    }
  }
}

enum AddressType { start, destination }
