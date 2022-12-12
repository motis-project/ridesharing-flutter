import 'package:flutter/material.dart';
import 'package:flutter_app/util/search/address_search_delegate.dart';
import 'package:flutter_app/util/trip/search_card.dart';
import 'package:flutter_app/util/trip/trip_stream_builder.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timelines/timelines.dart';

import '../../util/custom_timeline_theme.dart';
import '../../util/search/address_search_field.dart';
import '../../util/search/address_suggestion.dart';
import '../../util/submit_button.dart';
import '../../util/supabase.dart';
import '../models/ride.dart';

class SearchDealPage extends StatefulWidget {
  const SearchDealPage(this.start, this.end, this.date, this.seats,
      {super.key});

  final String start;
  final String end;
  final int seats;
  final DateTime date;

  @override
  State<SearchDealPage> createState() =>
      _SearchDealPageState(start, end, date, seats);
}

class _SearchDealPageState extends State<SearchDealPage> {
  String start;
  String end;
  int seats;
  DateTime date;

  _SearchDealPageState(this.start, this.end, this.date, this.seats);

  final TextEditingController _startController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  final _dateController = TextEditingController();
  late final DateTime _firstDate;
  late DateTime _selectedDate;
  late int _dropdownValue;

  final List<int> list = List.generate(10, (index) => index + 1);

  late Stream<List<Ride>> ridesuggestions;

  @override
  initState() {
    super.initState();
    _firstDate = date;
    _selectedDate = date;
    _dateController.text = _formatDate(date);
    _dropdownValue = seats;
    _startController.text = start;
    _destinationController.text = end;
    ridesuggestions = supabaseClient
        .from('rides')
        .stream(primaryKey: ['id'])
        .order('start_time', ascending: false)
        .map((ride) => Ride.fromJsonList(ride));
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
      if (value != null) {
        _selectedDate = DateTime(value.year, value.month, value.day,
            _selectedDate.hour, _selectedDate.minute);
        _dateController.text = _formatDate(_selectedDate);
      }
      updatePage();
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

  //todo: get possible Rides from Algorithm
  void getRides(){

  }

  void updatePage(){
    getRides();
    setState(() {});
  }

  //todo: filter
  void filter(){
    updatePage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Ride'),
      ),
      body: Column(
        children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: FixedTimeline(
                theme: CustomTimelineTheme.of(context),
                children: [
                  TimelineTile(
                      contents: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              width: 200,
                              child: ElevatedButton(
                                onPressed: () async {
                                  final AddressSuggestion? startSuggestion =
                                    await showSearch<AddressSuggestion?>(
                                    context: context,
                                    delegate: AddressSearchDelegate(),
                                    query: _startController.text,
                                    );
                                   if (startSuggestion != null) {
                                      _startController.text = startSuggestion.name;
                                      updatePage();
                                   }
                                },
                                child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(_startController.text),
                                ),
                              ),
                            ),
                            const SizedBox(width: 50),
                            Expanded(
                              child: TextFormField(
                                readOnly: true,
                                onTap: _showDatePicker,
                                controller: _dateController,
                                validator: _dateValidator,
                              ),
                            ),
                          ],
                        ),
                      ),
                      node: const TimelineNode(
                        indicator: CustomOutlinedDotIndicator(),
                        endConnector: CustomSolidLineConnector(),
                      ),
                  ),
                  TimelineTile(
                    contents: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            width: 200,
                            child: ElevatedButton(
                              onPressed: () async {
                                final AddressSuggestion? destinationsuggestion =
                                await showSearch<AddressSuggestion?>(
                                  context: context,
                                  delegate: AddressSearchDelegate(),
                                  query: _destinationController.text,
                                );
                                if (destinationsuggestion != null) {
                                  _destinationController.text = destinationsuggestion.name;
                                  updatePage();
                                }
                              },
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(_destinationController.text),
                              ),
                            ),
                          ),
                          const SizedBox(width: 50),
                          Expanded(
                            child: SizedBox(
                              height: 40,
                              child: DropdownButtonFormField<int>(
                                value: _dropdownValue,
                                icon: const Icon(Icons.arrow_downward),
                                onChanged: (int? value) {
                                  _dropdownValue = value!;
                                  updatePage();
                                },
                                items: list.map<DropdownMenuItem<int>>((int value) {
                                  return DropdownMenuItem<int>(
                                    value: value,
                                    child: Text("Seats: ${value.toString()}"),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    node: const TimelineNode(
                      indicator: CustomOutlinedDotIndicator(),
                      startConnector: CustomSolidLineConnector(),
                    ),
                  )
                ]
              ),
            ),
          //todo filter der Suchergebnisse
          SizedBox(
            height: 20,
            child: ElevatedButton(
              onPressed: () => filter(),
              child: const Align(
                alignment: Alignment.center,
                child: Text('Filter'),
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: TripStreamBuilder(
                stream: ridesuggestions,
                emptyMessage: "no rides found",
                filterTrips: (trips) => trips.reversed.where((trip) => trip.startTime.isBefore(DateTime.now())).toList(),
                tripCard: (ride) => SearchCard(trip: ride),
            ),
          ),
        ],
      ),
    );
  }
}
