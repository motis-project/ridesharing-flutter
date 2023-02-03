import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:sliver_tools/sliver_tools.dart';

import '../../drives/models/drive.dart';
import '../../util/buttons/labeled_checkbox.dart';
import '../../util/fields/increment_field.dart';
import '../../util/locale_manager.dart';
import '../../util/parse_helper.dart';
import '../../util/search/address_suggestion.dart';
import '../../util/search/start_destination_timeline.dart';
import '../../util/supabase_manager.dart';
import '../../util/trip/ride_card.dart';
import '../../util/trip/trip.dart';
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
  DateTime _selectedDate = DateTime.now();
  bool _wholeDay = true;
  int _seats = 1;

  late final SearchRideFilter _filter;

  List<Ride>? _rideSuggestions;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _filter = SearchRideFilter(wholeDay: _wholeDay);
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
    setState(() => _loading = true);
    final List<Map<String, dynamic>> data = parseHelper.parseListOfMaps(
      await supabaseManager.supabaseClient.from('drives').select('''
          *,
          driver:driver_id (
            *,
            profile_features (*),
            reviews_received: reviews!reviews_receiver_id_fkey(*)
          )
        ''').eq('start', _startController.text).eq('cancelled', false),
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
            _seats,
            supabaseManager.currentProfile?.id ?? -1,
            10.25,
          ),
        )
        .toList();
    setState(() {
      _rideSuggestions = rides;
      _loading = false;
    });
  }

  Widget buildSearchFieldViewer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: <Widget>[
          Expanded(
            child: StartDestinationTimeline(
              startController: _startController,
              destinationController: _destinationController,
              onStartSelected: (AddressSuggestion suggestion) => setState(() {
                _startSuggestion = suggestion;
                loadRides();
              }),
              onDestinationSelected: (AddressSuggestion suggestion) => setState(() {
                _destinationSuggestion = suggestion;
                loadRides();
              }),
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
          ),
        ],
      ),
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
      ),
    );
  }

  Widget buildDateRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          if (_wholeDay) ...<Widget>[
            IconButton(
              tooltip: S.of(context).before,
              onPressed: _selectedDate.isSameDayAs(DateTime.now())
                  ? null
                  : () => setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1))),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(child: buildDatePicker()),
            IconButton(
              tooltip: S.of(context).after,
              onPressed: () => setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1))),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
          if (!_wholeDay) ...<Widget>[
            Expanded(child: buildDatePicker()),
            const SizedBox(width: 10),
            Expanded(child: buildTimePicker()),
            const SizedBox(width: 10),
          ],
          LabeledCheckbox(
            label: S.of(context).pageSearchRideWholeDay,
            value: _wholeDay,
            onChanged: (bool? value) => setState(() {
              _wholeDay = value!;
              _filter.wholeDay = _wholeDay;
            }),
          ),
        ],
      ),
    );
  }

  Widget buildSeats() {
    return Center(
      child: SizedBox(
        width: 150,
        child: IncrementField(
          maxValue: Trip.maxSelectableSeats,
          icon: Icon(
            Icons.chair,
            color: Theme.of(context).colorScheme.primary,
            size: 32,
          ),
          onChanged: (int? value) {
            setState(() {
              _seats = value!;
              loadRides();
            });
          },
        ),
      ),
    );
  }

  Widget buildMainContentSliver() {
    if (_rideSuggestions == null || _loading) {
      if (_startSuggestion == null || _destinationSuggestion == null) {
        return SliverToBoxAdapter(
          child: Column(
            children: <Widget>[
              Image.asset('assets/pointing_up.png'),
              const SizedBox(height: 10),
              Text(
                S.of(context).pageSearchRideNoInput,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(top: 10),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    final List<Ride> filteredSuggestions = _filter.apply(_rideSuggestions!, _selectedDate);
    if (filteredSuggestions.isEmpty) {
      return SliverToBoxAdapter(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: <Widget>[
              Image.asset('assets/shrug.png'),
              const SizedBox(height: 10),
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
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            final Ride ride = filteredSuggestions[index];
            return RideCard(ride);
          },
          childCount: filteredSuggestions.length,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadRides,
          child: CustomScrollView(
            slivers: <Widget>[
              SliverAppBar(
                floating: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(S.of(context).pageSearchRideTitle),
                ),
              ),
              SliverPinnedHeader(
                child: ColoredBox(
                  color: Theme.of(context).canvasColor,
                  child: buildSearchFieldViewer(),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 10)),
              SliverToBoxAdapter(child: buildDateRow()),
              SliverToBoxAdapter(child: buildSeats()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _filter.buildIndicatorRow(context, setState),
                ),
              ),
              SliverPinnedHeader(
                child: ColoredBox(
                  color: Theme.of(context).canvasColor,
                  child: const Divider(thickness: 1),
                ),
              ),
              buildMainContentSliver(),
            ],
          ),
        ),
      ),
    );
  }
}
