import 'package:flutter/material.dart';

class AddressSearchField extends StatefulWidget {
  final String labelText;
  final String hintText;
  final String validatorEmptyText;
  final TextEditingController controller;

  const AddressSearchField({
    required this.labelText,
    required this.hintText,
    required this.validatorEmptyText,
    required this.controller,
  });

  factory AddressSearchField.start({
    required TextEditingController controller,
  }) {
    return AddressSearchField(
      labelText: 'Start',
      hintText: 'Enter your starting Location',
      validatorEmptyText: 'Please enter a starting location',
      controller: controller,
    );
  }

  factory AddressSearchField.destination({
    required TextEditingController controller,
  }) {
    return AddressSearchField(
      labelText: 'Destination',
      hintText: 'Enter your destination',
      validatorEmptyText: 'Please enter a destination',
      controller: controller,
    );
  }

  @override
  AddressSearchFieldState createState() => AddressSearchFieldState();
}

class AddressSearchFieldState extends State<AddressSearchField> {
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: widget.labelText,
        hintText: widget.hintText,
      ),
      controller: widget.controller,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return widget.validatorEmptyText;
        }
        return null;
      },
    );
  }
}
