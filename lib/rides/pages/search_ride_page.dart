import 'package:flutter/material.dart';
import 'package:motis_mitfahr_app/rides/pages/search_suggestion_page.dart';
import 'package:motis_mitfahr_app/util/locale_manager.dart';
import 'package:motis_mitfahr_app/util/search/address_search_field.dart';
import 'package:motis_mitfahr_app/util/submit_button.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SearchRidePage extends StatefulWidget {
  const SearchRidePage({super.key});

  @override
  State<SearchRidePage> createState() => _SearchRidePageState();
}

class _SearchRidePageState extends State<SearchRidePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).pageSearchRideTitle),
      ),
      body: const Padding(
        padding: EdgeInsets.symmetric(),
        child: SingleChildScrollView(child: SearchRideForm()),
      ),
    );
  }
}

class SearchRideForm extends StatefulWidget {
  const SearchRideForm({super.key});

  @override
  State<SearchRideForm> createState() => _SearchRideFormState();
}

class _SearchRideFormState extends State<SearchRideForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  late DateTime _selectedDate;
  late int _dropdownValue;

  final List<int> list = List.generate(10, (index) => index + 1);

  @override
  initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _dropdownValue = list.first;
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _startController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  void _showTimePicker() {
    showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _selectedDate.hour, minute: _selectedDate.minute),
      builder: (context, childWidget) {
        return MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: childWidget!);
      },
    ).then((value) {
      setState(() {
        if (value != null) {
          _selectedDate =
              DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, value.hour, value.minute);
          _timeController.text = localeManager.formatTime(_selectedDate);
        }
      });
    });
  }

  void _showDatePicker() {
    DateTime firstDate = DateTime.now();

    showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: firstDate,
      lastDate: firstDate.add(const Duration(days: 30)),
    ).then((value) {
      setState(() {
        if (value != null) {
          _selectedDate = DateTime(value.year, value.month, value.day, _selectedDate.hour, _selectedDate.minute);
          _dateController.text = localeManager.formatDate(_selectedDate);
        }
      });
    });
  }

  String? _timeValidator(String? value) {
    if (value == null || value.isEmpty) {
      return S.of(context).formTimeValidateEmpty;
    }
    if (_selectedDate.isBefore(DateTime.now())) {
      return S.of(context).formTimeValidateFuture;
    }
    return null;
  }

  void _onSubmit() async {
    //todo: pressing search button
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
            builder: (context) => SearchSuggestionPage(
                _startController.text, _destinationController.text, _selectedDate, _dropdownValue)),
      );
    }
  }

  Widget buildDatePicker() {
    _dateController.text = localeManager.formatDate(_selectedDate);

    return Expanded(
      child: Semantics(
        button: true,
        child: TextFormField(
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: S.of(context).formDate,
          ),
          readOnly: true,
          onTap: _showDatePicker,
          controller: _dateController,
        ),
      ),
    );
  }

  Widget buildTimePicker() {
    _timeController.text = localeManager.formatTime(_selectedDate);

    return Expanded(
      child: Semantics(
        button: true,
        child: TextFormField(
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: S.of(context).formTime,
          ),
          readOnly: true,
          onTap: _showTimePicker,
          controller: _timeController,
          validator: _timeValidator,
        ),
      ),
    );
  }

  Widget buildSeatsPicker() {
    return Expanded(
      child: SizedBox(
        //todo: add same height as time&date.
        height: 60,
        child: DropdownButtonFormField<int>(
          value: _dropdownValue,
          icon: const Icon(Icons.arrow_downward),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: S.of(context).seats,
          ),
          onChanged: (int? value) {
            setState(() {
              _dropdownValue = value!;
            });
          },
          items: list.map<DropdownMenuItem<int>>((int value) {
            return DropdownMenuItem<int>(
              value: value,
              child: Text(value.toString()),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
        child: Column(
          children: [
            AddressSearchField.start(
              controller: _startController,
              onSelected: (suggestion) {},
            ),
            const SizedBox(height: 15),
            AddressSearchField.destination(
              controller: _destinationController,
              onSelected: (suggestion) {},
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  buildDatePicker(),
                  buildTimePicker(),
                  const SizedBox(width: 50),
                  buildSeatsPicker(),
                ],
              ),
            ),
            Hero(
              tag: "SearchButton",
              child: SubmitButton(
                text: S.of(context).pageSearchRideButtonSearch,
                onPressed: _onSubmit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
