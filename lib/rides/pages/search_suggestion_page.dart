import 'package:flutter/material.dart';
import 'package:motis_mitfahr_app/util/locale_manager.dart';
import 'package:motis_mitfahr_app/util/search/address_search_delegate.dart';
import 'package:motis_mitfahr_app/util/trip/search_card.dart';
import 'package:timelines/timelines.dart';
import '../../drives/models/drive.dart';
import '../../util/custom_timeline_theme.dart';
import '../../util/search/address_suggestion.dart';
import '../../util/supabase.dart';
import '../models/ride.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SearchSuggestionPage extends StatefulWidget {
  const SearchSuggestionPage(this.startSuggestion, this.endSuggestion, this.date, this.seats, {super.key});

  final AddressSuggestion startSuggestion;
  final AddressSuggestion endSuggestion;
  final int seats;
  final DateTime date;

  @override
  State<SearchSuggestionPage> createState() => _SearchSuggestionPage();
}

class _SearchSuggestionPage extends State<SearchSuggestionPage> {
  final TextEditingController _startController = TextEditingController();
  late AddressSuggestion _startSuggestion;
  final TextEditingController _destinationController = TextEditingController();
  late AddressSuggestion _destinationSuggestion;

  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  late DateTime _selectedDate;
  late int _dropdownValue;

  final List<int> list = List.generate(10, (index) => index + 1);

  List<Ride>? _rideSuggestions;

  @override
  initState() {
    super.initState();
    _selectedDate = widget.date;
    _dropdownValue = widget.seats;
    _startSuggestion = widget.startSuggestion;
    _startController.text = widget.startSuggestion.name;
    _destinationSuggestion = widget.endSuggestion;
    _destinationController.text = widget.endSuggestion.name;
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
    DateTime firstDate = DateTime.now();

    showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: firstDate,
      lastDate: firstDate.add(const Duration(days: 30)),
    ).then((value) {
      if (value != null) {
        setState(() {
          _selectedDate = DateTime(value.year, value.month, value.day, _selectedDate.hour, _selectedDate.minute);
          _dateController.text = localeManager.formatDate(_selectedDate);
        });
        if (_dateTimeValidator(_timeController.text) == null) loadRides();
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
        setState(() {
          _selectedDate =
              DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, value.hour, value.minute);
          _timeController.text = localeManager.formatTime(_selectedDate);
        });
        if (_dateTimeValidator(_timeController.text) == null) loadRides();
      }
    });
  }

  String? _dateTimeValidator(String? value) {
    if (value == null || value.isEmpty) {
      return S.of(context).formTimeValidateEmpty;
    }
    if (_selectedDate.add(const Duration(minutes: 10)).isBefore(DateTime.now())) {
      return S.of(context).formTimeValidateFuture;
    }
    return null;
  }

  //todo: get possible Rides from Algorithm
  void loadRides() async {
    List<dynamic> data = await SupabaseManager.supabaseClient
        .from('drives')
        .select('*, driver:driver_id (*)')
        .eq('start', _startController.text)
        .order('start_time', ascending: true);
    List<Drive> drives = data.map((drive) => Drive.fromJson(drive)).toList();
    List<Ride> rides = drives
        .map((drive) => Ride.previewFromDrive(
              drive,
              _startSuggestion.name,
              _startSuggestion.position,
              drive.startTime,
              _destinationSuggestion.name,
              _destinationSuggestion.position,
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
              buildLocationPicker(isStart: true),
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
              buildLocationPicker(isStart: false),
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
    _dateController.text = localeManager.formatDate(_selectedDate);

    return Semantics(
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
    );
  }

  Widget buildTimePicker() {
    _timeController.text = localeManager.formatTime(_selectedDate);

    return Semantics(
      button: true,
      child: TextFormField(
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: S.of(context).formTime,
          errorText: _dateTimeValidator(_timeController.text),
        ),
        readOnly: true,
        onTap: _showTimePicker,
        controller: _timeController,
        validator: _dateTimeValidator,
      ),
    );
  }

  Widget buildSeatsPicker() {
    return SizedBox(
      height: 60,
      width: 110,
      child: DropdownButtonFormField<int>(
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: S.of(context).seats,
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

  Widget buildLocationPicker({bool isStart = true}) {
    TextEditingController controller = isStart ? _startController : _destinationController;

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
            if (isStart) {
              _startSuggestion = suggestion;
            } else {
              _destinationSuggestion = suggestion;
            }
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
        child: Align(
          alignment: Alignment.center,
          child: Text(S.of(context).pageSearchSuggestionsButtonFilter),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).pageSearchSuggestionsTitle),
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
