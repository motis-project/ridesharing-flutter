import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../drives/models/drive.dart';
import '../../util/fields/increment_field.dart';
import '../../util/locale_manager.dart';
import '../../util/parse_helper.dart';
import '../../util/search/address_suggestion.dart';
import '../../util/search/start_destination_timeline.dart';
import '../../util/supabase.dart';
import '../../util/trip/ride_card.dart';
import '../models/ride.dart';
import '../widgets/search_ride_filter.dart';

class SearchRidePage extends StatefulWidget {
  const SearchRidePage({super.key});

  @override
  State<SearchRidePage> createState() => _SearchRidePageState();
}

class _SearchRidePageState extends State<SearchRidePage> {
  final TextEditingController _startController = TextEditingController();
  AddressSuggestion? _startSuggestion;
  final TextEditingController _destinationController = TextEditingController();
  AddressSuggestion? _destinationSuggestion;

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  late DateTime _selectedDate;
  late bool _wholeDay;
  late int _dropdownValue;

  final SearchRideFilter _filter = SearchRideFilter();

  List<Ride>? _rideSuggestions;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _wholeDay = true;
    _dropdownValue = 1;
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
    if (_startSuggestion == null || _destinationSuggestion == null) return;
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
        .map(
          (Drive drive) => Ride.previewFromDrive(
            drive,
            _startSuggestion!.name,
            _startSuggestion!.position,
            drive.startTime,
            _destinationSuggestion!.name,
            _destinationSuggestion!.position,
            drive.endTime,
            _dropdownValue,
            SupabaseManager.getCurrentProfile()?.id ?? -1,
            10.25,
          ),
        )
        .toList();
    setState(() {
      _rideSuggestions = rides;
    });
  }

  Widget buildSearchFieldViewer() {
    return Row(
      children: <Widget>[
        Expanded(
          child: StartDestinationTimeline(
            startController: _startController,
            destinationController: _destinationController,
            onStartSelected: (AddressSuggestion suggestion) => setState(() => _startSuggestion = suggestion),
            onDestinationSelected: (AddressSuggestion suggestion) =>
                setState(() => _destinationSuggestion = suggestion),
          ),
        ),
        IconButton(
          onPressed: () => setState(() {
            final String oldStartText = _startController.text;
            _startController.text = _destinationController.text;
            _destinationController.text = oldStartText;
            final AddressSuggestion? oldStartSuggestion = _startSuggestion;
            _startSuggestion = _destinationSuggestion;
            _destinationSuggestion = oldStartSuggestion;
            loadRides();
          }),
          icon: const Icon(Icons.swap_vert),
        )
      ],
    );
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
                S.of(context).pageSearchRideEmpty,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              if (_rideSuggestions!.isNotEmpty)
                Semantics(
                  button: true,
                  tooltip: S.of(context).pageSearchRideTooltipFilter,
                  child: InkWell(
                    onTap: () => _filter.dialog(context, setState),
                    child: Text(
                      S.of(context).pageSearchRideRelaxRestrictions,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                Text(
                  S.of(context).pageSearchRideNoResults,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
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
        Expanded(child: buildDatePicker()),
        const SizedBox(width: 10),
        if (!_wholeDay) ...<Widget>[
          Expanded(child: buildTimePicker()),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Row(
            children: <Widget>[
              Checkbox(
                value: _wholeDay,
                onChanged: (bool? value) => setState(() => _wholeDay = value!),
              ),
              const Text('Whole day')
            ],
          ),
        ),
      ],
    );
  }

  Widget buildSeats() {
    return IncrementField(
      maxValue: 8,
      icon: Icon(
        Icons.chair,
        color: Theme.of(context).colorScheme.primary,
      ),
      onChanged: (int? value) {
        setState(() {
          _dropdownValue = value!;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'RideFAB',
      child: Scaffold(
        appBar: AppBar(title: Text(S.of(context).pageSearchRideTitle)),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: <Widget>[
              buildSearchFieldViewer(),
              const SizedBox(height: 10),
              buildDateSeatsRow(),
              const SizedBox(height: 5),
              buildSeats(),
              _filter.buildIndicatorRow(context, setState),
              const Divider(thickness: 1),
              buildSearchCardList(),
            ],
          ),
        ),
      ),
    );
  }
}
