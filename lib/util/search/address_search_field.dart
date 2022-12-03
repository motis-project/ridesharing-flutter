import 'package:flutter/material.dart';
import 'package:flutter_app/util/search/address_search_delegate.dart';
import 'package:flutter_app/util/search/address_suggestion.dart';

class AddressSearchField extends StatelessWidget {
  final String labelText;
  final String hintText;
  final String validatorEmptyText;
  final TextEditingController controller;
  final void Function(AddressSuggestion) onSelected;

  const AddressSearchField({
    super.key,
    required this.labelText,
    required this.hintText,
    required this.validatorEmptyText,
    required this.controller,
    required this.onSelected,
  });

  factory AddressSearchField.start({
    required TextEditingController controller,
    required void Function(AddressSuggestion) onSelected,
  }) {
    return AddressSearchField(
      labelText: 'Start',
      hintText: 'Enter your starting Location',
      validatorEmptyText: 'Please enter a starting location',
      controller: controller,
      onSelected: onSelected,
    );
  }

  factory AddressSearchField.destination({
    required TextEditingController controller,
    required void Function(AddressSuggestion) onSelected,
  }) {
    return AddressSearchField(
      labelText: 'Destination',
      hintText: 'Enter your destination',
      validatorEmptyText: 'Please enter a destination',
      controller: controller,
      onSelected: onSelected,
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return validatorEmptyText;
        }
        return null;
      },
      onTap: () async {
        final AddressSuggestion? addressSuggestion =
            await showSearch<AddressSuggestion?>(
          context: context,
          delegate: AddressSearchDelegate(),
          query: controller.text,
        );

        if (addressSuggestion != null) {
          controller.text = addressSuggestion.name;
          onSelected(addressSuggestion);
        }
      },
    );
  }
}
