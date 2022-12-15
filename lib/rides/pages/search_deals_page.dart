import 'package:flutter/material.dart';
import 'package:flutter_app/util/search/address_search_delegate.dart';
import 'package:flutter_app/util/trip/search_card.dart';
import 'package:intl/intl.dart';
import 'package:timelines/timelines.dart';

import '../../drives/models/drive.dart';
import '../../util/custom_timeline_theme.dart';
import '../../util/search/address_suggestion.dart';
import '../../util/supabase.dart';
import '../models/ride.dart';

class SearchDealPage extends StatefulWidget {
  const SearchDealPage(this.start, this.end, this.date, this.seats, {super.key});

  final String start;
  final String end;
  final int seats;
  final DateTime date;

  @override
  State<SearchDealPage> createState() => _SearchDealPageState();
}

class _SearchDealPageState extends State<SearchDealPage> {
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  late final DateTime _firstDate;
  late DateTime _selectedDate;
  late int _dropdownValue;

  final List<int> list = List.generate(10, (index) => index + 1);

  List<Ride>? ridesuggestion;

  late final int? riderID;

  @override
  initState() {
    int riderId = SupabaseManager.getCurrentProfile()?.id ?? -1;
    super.initState();
    _firstDate = widget.date;
    _selectedDate = widget.date;
    _dateController.text = _formatDate(widget.date);
    _timeController.text = _formatTime(widget.date);
    _dropdownValue = widget.seats;
    _startController.text = widget.start;
    _destinationController.text = widget.end;
    getRides();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
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
        _selectedDate = DateTime(value.year, value.month, value.day, _selectedDate.hour, _selectedDate.minute);
        _dateController.text = _formatDate(_selectedDate);
      }
      getRides();
    });
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
          _timeController.text = _formatTime(_selectedDate);
        }
      });
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  String _formatTime(DateTime time) {
    return DateFormat.Hm().format(time);
  }

  String? _timeValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a time';
    }
    if (_selectedDate.isBefore(_firstDate)) {
      return 'Please enter a valid time';
    }
    return null;
  }

  //todo: get possible Rides from Algorithm
  void getRides() async {
    List<Ride> initializes = await supabaseClient
        .from('drives')
        .select('*, driver:driver_id (*)')
        .eq('start', _startController.text)
        .order('start_time', ascending: true)
    List<<Map<String,dynamic>>> data = await supabaseClient
        .from('drives')
        .select('*, driver:driver_id (*)')
        .eq('start', _startController.text)
        .order('start_time', ascending: true);
  List<Drive> drives = data.map((drive) => Drive.fromJsonList(drive));
  List<Ride> rides =  drives.map((e) => e.toRide(
                  _startController.text,
                  _destinationController.text,
                  e.startTime,
                  e.endTime,
                  _dropdownValue,
                  -1,
                  10.25,
                ))
            .toList());
            .map((e) => e.toRide(
                  _startController.text,
                  _destinationController.text,
                  e.startTime,
                  e.endTime,
                  _dropdownValue,
                  riderID!,
                  10.25,
                ))
            .toList());
    setState(() {
      ridesuggestion = initializes;
    });
  }

  //todo: filter
  void filter() {
    getRides();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Ride'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            FixedTimeline(theme: CustomTimelineTheme.of(context), children: [
              TimelineTile(
                contents: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final AddressSuggestion? startSuggestion = await showSearch<AddressSuggestion?>(
                              context: context,
                              delegate: AddressSearchDelegate(),
                              query: _startController.text,
                            );
                            if (startSuggestion != null) {
                              _startController.text = startSuggestion.name;
                              getRides();
                            }
                          },
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(_startController.text),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      SizedBox(
                        width: 65,
                        child: TextFormField(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: "Time",
                          ),
                          readOnly: true,
                          onTap: _showTimePicker,
                          controller: _timeController,
                          validator: _timeValidator,
                        ),
                      ),
                      const SizedBox(width: 5),
                      SizedBox(
                        width: 110,
                        child: TextFormField(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: "Date",
                          ),
                          readOnly: true,
                          onTap: _showDatePicker,
                          controller: _dateController,
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
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final AddressSuggestion? destinationsuggestion = await showSearch<AddressSuggestion?>(
                              context: context,
                              delegate: AddressSearchDelegate(),
                              query: _destinationController.text,
                            );
                            if (destinationsuggestion != null) {
                              _destinationController.text = destinationsuggestion.name;
                              getRides();
                            }
                          },
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(_destinationController.text),
                          ),
                        ),
                      ),
                      const SizedBox(width: 90),
                      SizedBox(
                        height: 60,
                        width: 110,
                        child: DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: "Seats",
                          ),
                          value: _dropdownValue,
                          onChanged: (int? value) {
                            _dropdownValue = value!;
                            getRides();
                          },
                          items: list.map<DropdownMenuItem<int>>((int value) {
                            return DropdownMenuItem<int>(
                              value: value,
                              child: Text(value.toString()),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                node: const TimelineNode(
                  indicator: CustomOutlinedDotIndicator(),
                  startConnector: CustomSolidLineConnector(),
                ),
              ),
            ]),
            const SizedBox(height: 5),
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
            const SizedBox(height: 5),
            ridesuggestion == null
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
                    child: ListView.separated(
                      itemBuilder: (context, index) {
                        final ride = ridesuggestion![index];
                        return SearchCard(ride);
                      },
                      separatorBuilder: (BuildContext context, int index) {
                        return const SizedBox(height: 10);
                      },
                      itemCount: ridesuggestion!.length,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
