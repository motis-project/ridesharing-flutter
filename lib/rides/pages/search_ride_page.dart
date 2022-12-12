import 'package:flutter/material.dart';
import 'package:flutter_app/rides/pages/search_deals_page.dart';
import 'package:flutter_app/util/search/address_search_field.dart';
import 'package:flutter_app/util/search/address_suggestion.dart';
import 'package:flutter_app/util/submit_button.dart';

class SearchRidePage extends StatefulWidget {
  const SearchRidePage({Key? key}) : super(key: key);

  @override
  State<SearchRidePage> createState() => _SearchRidePageState();
}


class _SearchRidePageState extends State<SearchRidePage> {

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  AddressSuggestion? _startSuggestion;
  AddressSuggestion? _destinationSuggestion;

  final _dateController = TextEditingController();
  late final DateTime _firstDate;
  late DateTime _selectedDate;
  late int _dropdownValue;

  final List<int> list = List.generate(10, (index) => index + 1);

  @override
  initState() {
    super.initState();
    _firstDate = DateTime.now();
    _selectedDate = DateTime.now();
    _dateController.text = _formatDate(_selectedDate);
    _dropdownValue = list.first;
  }

  @override
  void dispose() {
    _dateController.dispose();
    _startController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  void _showDatePicker() {
    showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: _firstDate,
      lastDate: _firstDate.add(const Duration(days: 30)),
    ).then((value) {
      setState(() {
        if (value != null) {
          _selectedDate = DateTime(value.year, value.month, value.day,
              _selectedDate.hour, _selectedDate.minute);
          _dateController.text = _formatDate(_selectedDate);
        }
      });
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  String? _dateValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a date';
    }
    if (_selectedDate.isBefore(_firstDate)) {
      return 'Please enter a valid date';
    }
    return null;
  }

  void _onSubmit() async {
    //todo: pressing search button
    if (_formKey.currentState!.validate()) {
        Navigator.of(context).push(
          MaterialPageRoute(
              builder: (context) => SearchDealPage(_startController.text, _destinationController.text, _selectedDate, _dropdownValue)),
        );
      }
    }

    @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        title: const Text('Search Ride'),
        ),
      body: Padding(
        padding: EdgeInsets.symmetric(),
        child: SingleChildScrollView(
            child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
              child: Column(
                children: [
                  AddressSearchField.start(
                    controller: _startController,
                    onSelected: (suggestion) => _startSuggestion = suggestion,
                  ),
                  const SizedBox(height: 15),
                  AddressSearchField.destination(
                    controller: _destinationController,
                    onSelected: (suggestion) => _destinationSuggestion = suggestion,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: "Date",
                            ),
                            readOnly: true,
                            onTap: _showDatePicker,
                            controller: _dateController,
                            validator: _dateValidator,
                          ),
                        ),
                        const SizedBox(width: 164),
                        Expanded(
                          child: SizedBox(
                            height: 60,
                            child: DropdownButtonFormField<int>(
                              value: _dropdownValue,
                              icon: const Icon(Icons.arrow_downward),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: "Seats",
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
                        ),
                      ],
                    ),
                  ),
                  //Search
                  SubmitButton(
                    text: "Search",
                    onPressed: _onSubmit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
