import 'package:flutter/material.dart';
import 'package:flutter_app/rides/models/searchrequest.dart';
import 'package:flutter_app/rides/pages/search_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../util/submit_button.dart';

class SearchDealPage extends StatefulWidget {
  const SearchDealPage(this.request, {super.key});

  final SearchRequest request;

  @override
  State<SearchDealPage> createState() => _SearchDealPageState(this.request);
}

class _SearchDealPageState extends State<SearchDealPage> {
  SearchRequest request;
  _SearchDealPageState(this.request);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _startController = TextEditingController();
  final _destinationController = TextEditingController();

  final _dateController = TextEditingController();
  late final DateTime _firstDate;
  late DateTime _selectedDate;
  late int _dropdownValue;

  final List<int> list = List.generate(10, (index) => index + 1);

  @override
  initState() {
    super.initState();
    _startController.text = request.start;
    _destinationController.text = request.end;
    _firstDate = request.startTime;
    _selectedDate = request.startTime;
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
      SearchRequest newrequest = SearchRequest(
          start: _startController.text,
          startTime: _selectedDate,
          end: _destinationController.text,
          seats: _dropdownValue
      );
      Navigator.of(context).push(
        MaterialPageRoute(
            builder: (context) => SearchDealPage(newrequest)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Ride'),
      ),
      body: Column(
        children: [
          Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 5, 10, 0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              TextFormField(
                                style: const TextStyle(
                                  fontSize: 14.0,
                                ),
                                decoration: const InputDecoration(
                                  labelText: "Start",
                                  hintText: "Enter your starting Location",
                                ),
                                controller: _startController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a starting location';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 5,),
                              TextFormField(
                                style: const TextStyle(
                                  fontSize: 14.0,
                                ),
                                decoration: const InputDecoration(
                                  labelText: "Destination",
                                  hintText: "Enter your destination",
                                ),
                                controller: _destinationController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a destination';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 50),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(0, 0, 0, 60),
                            child: TextFormField(
                              style: const TextStyle(
                                fontSize: 14.0,
                              ),
                              decoration: const InputDecoration(
                                labelText: "Date",
                              ),
                              readOnly: true,
                              onTap: _showDatePicker,
                              controller: _dateController,
                              validator: _dateValidator,
                            ),
                          ),
                        ),
                      ],
                    ),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(500, 20),
                      maximumSize: const Size(500, 20),
                    ),
                    onPressed: null,
                    child:Text("Filter")
                     ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: 10,
                separatorBuilder: (context, index) {
                  return const SizedBox(height: 12);
                },
                itemBuilder: (context, index) {
                  return const SearchCard();
                },
              ),
          ),
        ],
      ),
    );
  }
}
