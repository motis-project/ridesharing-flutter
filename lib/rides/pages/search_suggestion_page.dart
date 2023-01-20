import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:timelines/timelines.dart';

import '../../drives/models/drive.dart';
import '../../util/custom_timeline_theme.dart';
import '../../util/locale_manager.dart';
import '../../util/parse_helper.dart';
import '../../util/search/address_search_delegate.dart';
import '../../util/search/address_suggestion.dart';
import '../../util/supabase.dart';
import '../../util/trip/ride_card.dart';
import '../models/ride.dart';
import '../widgets/search_suggestion_filter.dart';

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

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  late DateTime _selectedDate;
  late int _dropdownValue;

  final List<int> list = List<int>.generate(10, (int index) => index + 1);

  final SearchSuggestionFilter _filter = SearchSuggestionFilter();

  List<Ride>? _rideSuggestions;

  @override
  void initState() {
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
    _filter.dispose();
    super.dispose();
  }

  void _showDatePicker() {
    final DateTime firstDate = DateTime.now();

    showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: firstDate,
      lastDate: firstDate.add(const Duration(days: 30)),
    ).then((DateTime? value) {
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
      builder: (BuildContext context, Widget? childWidget) {
        return MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: childWidget!);
      },
    ).then((TimeOfDay? value) {
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
  Future<void> loadRides() async {
    final List<Map<String, dynamic>> data = parseHelper.parseListOfMaps(
      await SupabaseManager.supabaseClient.from('drives').select('''
          *,
          driver:driver_id (
            *,
            profile_features (*),
            reviews_received: reviews!reviews_receiver_id_fkey(*)
          )
        ''').eq('start', _startController.text),
    );
    final List<Drive> drives = data.map((Map<String, dynamic> drive) => Drive.fromJson(drive)).toList();
    final List<Ride> rides = drives
        .map((Drive drive) => Ride.previewFromDrive(
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
            ),)
        .toList();
    setState(() {
      _rideSuggestions = rides;
    });
  }

  FixedTimeline buildSearchFieldViewer() {
    return FixedTimeline(theme: CustomTimelineTheme.of(context), children: <Widget>[
      TimelineTile(
        contents: Padding(
          padding: const EdgeInsets.all(4.0),
          child: buildLocationPicker(isStart: true),
        ),
        node: const TimelineNode(
          indicator: CustomOutlinedDotIndicator(),
          endConnector: CustomSolidLineConnector(),
        ),
      ),
      TimelineTile(
        contents: Padding(
          padding: const EdgeInsets.all(4.0),
          child: buildLocationPicker(isStart: false),
        ),
        node: const TimelineNode(
          indicator: CustomOutlinedDotIndicator(),
          startConnector: CustomSolidLineConnector(),
        ),
      ),
    ],);
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
            errorText: _dateTimeValidator(_timeController.text),
          ),
          readOnly: true,
          onTap: _showTimePicker,
          controller: _timeController,
          validator: _dateTimeValidator,
        ),
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

  Widget buildLocationPicker({required bool isStart}) {
    final TextEditingController controller = isStart ? _startController : _destinationController;

    return ElevatedButton(
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
    );
  }

  Widget buildSearchCardList() {
    if (_rideSuggestions == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final List<Ride> filteredSuggestions = _filter.apply(_rideSuggestions!, _selectedDate);
    Widget list;
    if (filteredSuggestions.isEmpty) {
      list = Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: <Widget>[
              Image.asset('assets/shrug.png'),
              Text(
                S.of(context).pageSearchSuggestionsEmpty,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              if (_rideSuggestions!.isNotEmpty)
                Semantics(
                  button: true,
                  tooltip: S.of(context).pageSearchSuggestionsTooltipFilter,
                  child: InkWell(
                    onTap: () => _filter.dialog(context, setState),
                    child: Text(
                      S.of(context).pageSearchSuggestionsRelaxRestrictions,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                )
              else
                Text(
                  S.of(context).pageSearchSuggestionsNoResults,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
            ],
          ),
        ),
      );
    } else {
      list = ListView.separated(
        itemBuilder: (BuildContext context, int index) {
          final Ride ride = filteredSuggestions[index];
          return RideCard(ride);
        },
        separatorBuilder: (BuildContext context, int index) {
          return const SizedBox(height: 10);
        },
        itemCount: filteredSuggestions.length,
      );
    }
    return Expanded(
      child: RefreshIndicator(onRefresh: loadRides, child: list),
    );
  }

  Widget buildDateSeatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        buildDatePicker(),
        buildTimePicker(),
        const SizedBox(width: 50),
        buildSeatsPicker(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).pageSearchSuggestionsTitle)),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            buildSearchFieldViewer(),
            const SizedBox(height: 10),
            buildDateSeatsRow(),
            const SizedBox(height: 5),
            _filter.buildIndicatorRow(context, setState),
            const Divider(thickness: 1),
            buildSearchCardList(),
          ],
        ),
      ),
    );
  }
}
