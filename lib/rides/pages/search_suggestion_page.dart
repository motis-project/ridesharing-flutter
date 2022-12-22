import 'package:flutter/material.dart';
import 'package:flutter_app/util/format_helper.dart';
import 'package:flutter_app/util/search/address_search_delegate.dart';
import 'package:flutter_app/util/trip/search_card.dart';
import 'package:timelines/timelines.dart';
import '../../drives/models/drive.dart';
import '../../util/custom_timeline_theme.dart';
import '../../util/search/address_suggestion.dart';
import '../../util/supabase.dart';
import '../models/ride.dart';

class SearchSuggestionPage extends StatefulWidget {
  const SearchSuggestionPage(this.start, this.end, this.date, this.seats, {super.key});

  final String start;
  final String end;
  final int seats;
  final DateTime date;

  @override
  State<SearchSuggestionPage> createState() => _SearchSuggestionPage();
}

class _SearchSuggestionPage extends State<SearchSuggestionPage> {
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  late final DateTime _firstDate;
  late DateTime _selectedDate;
  late int _dropdownValue;

  final List<int> list = List.generate(10, (index) => index + 1);

  List<Ride>? _rideSuggestions;

  @override
  initState() {
    super.initState();
    _firstDate = widget.date;
    _selectedDate = widget.date;
    _dateController.text = FormatHelper.formatDate(widget.date);
    _timeController.text = FormatHelper.formatTime(widget.date);
    _dropdownValue = widget.seats;
    _startController.text = widget.start;
    _destinationController.text = widget.end;
    loadRides();
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
        _dateController.text = FormatHelper.formatDate(_selectedDate);
      }
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
      if (value != null) {
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, value.hour, value.minute);
        _timeController.text = FormatHelper.formatTime(_selectedDate);
      }
    });
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
  void loadRides() async {
    List<dynamic> data = await supabaseClient
        .from('drives')
        .select('*, driver:driver_id (*)')
        .eq('start', _startController.text)
        .order('start_time', ascending: true);
    List<Drive> drives = data.map((drive) => Drive.fromJson(drive)).toList();
    List<Ride> rides = drives
        .map((drive) => Ride.previewFromDrive(
              drive,
              _startController.text,
              _destinationController.text,
              drive.startTime,
              drive.endTime,
              _dropdownValue,
              SupabaseManager.getCurrentProfile()?.id ?? -1,
              10.25,
            ))
        .toList();
    setState(() {
      _rideSuggestions = rides;
    });
  }

  //todo: filter
  void filter() {
    loadRides();
  }

  FixedTimeline buildSearchFieldViewer() {
    return FixedTimeline(theme: CustomTimelineTheme.of(context), children: [
      TimelineTile(
        contents: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              buildLocationPicker(_startController),
              const SizedBox(width: 20),
              SizedBox(
                width: 65,
                child: buildTimePicker(),
              ),
              const SizedBox(width: 5),
              SizedBox(
                width: 110,
                child: buildDatePicker(),
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
              buildLocationPicker(_destinationController),
              const SizedBox(width: 90),
              buildSeatsPicker(),
            ],
          ),
        ),
        node: const TimelineNode(
          indicator: CustomOutlinedDotIndicator(),
          startConnector: CustomSolidLineConnector(),
        ),
      ),
    ]);
  }

  Widget buildDatePicker() {
    return TextFormField(
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: "Date",
      ),
      readOnly: true,
      onTap: () {
        _showDatePicker;
        loadRides();
      },
      controller: _dateController,
    );
  }

  Widget buildTimePicker() {
    return TextFormField(
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: "Time",
      ),
      readOnly: true,
      onTap: () {
        _showTimePicker;
        loadRides();
      },
      controller: _timeController,
      validator: _timeValidator,
    );
  }

  Widget buildSeatsPicker() {
    return SizedBox(
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
          loadRides();
        },
        items: list.map<DropdownMenuItem<int>>((int value) {
          return DropdownMenuItem<int>(
            value: value,
            child: Text(value.toString()),
          );
        }).toList(),
      ),
    );
  }

  Widget buildLocationPicker(TextEditingController controller) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () async {
          final AddressSuggestion? suggestion = await showSearch<AddressSuggestion?>(
            context: context,
            delegate: AddressSearchDelegate(),
            query: controller.text,
          );
          if (suggestion != null) {
            controller.text = suggestion.name;
            loadRides();
          }
        },
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(controller.text),
        ),
      ),
    );
  }

  Widget buildSearchCardList() {
    return _rideSuggestions == null
        ? const Center(child: CircularProgressIndicator())
        : Expanded(
            child: ListView.separated(
              itemBuilder: (context, index) {
                final ride = _rideSuggestions![index];
                return SearchCard(ride);
              },
              separatorBuilder: (BuildContext context, int index) {
                return const SizedBox(height: 10);
              },
              itemCount: _rideSuggestions!.length,
            ),
          );
  }

  Widget buildFilterPicker() {
    return SizedBox(
      height: 20,
      child: ElevatedButton(
        onPressed: () => filter(),
        child: const Align(
          alignment: Alignment.center,
          child: Text('Filter'),
        ),
      ),
    );
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
            buildSearchFieldViewer(),
            const SizedBox(height: 5),
            buildFilterPicker(),
            const SizedBox(height: 5),
            buildSearchCardList(),
          ],
        ),
      ),
    );
  }
}