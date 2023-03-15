import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:sliver_tools/sliver_tools.dart';

import '../../drives/models/drive.dart';
import '../../util/buttons/labeled_checkbox.dart';
import '../../util/empty_search_results.dart';
import '../../util/fields/increment_field.dart';
import '../../util/locale_manager.dart';
import '../../util/search/address_suggestion.dart';
import '../../util/search/start_destination_timeline.dart';
import '../../util/supabase_manager.dart';
import '../../util/trip/ride_card.dart';
import '../../util/trip/trip.dart';
import '../models/ride.dart';
import '../widgets/search_ride_filter.dart';

class SearchRidePage extends StatefulWidget {
  //This is needed in order to mock the time in tests
  final Clock clock;
  const SearchRidePage({super.key, this.clock = const Clock()});

  @override
  State<SearchRidePage> createState() => SearchRidePageState();
}

class SearchRidePageState extends State<SearchRidePage> {
  final TextEditingController startController = TextEditingController();
  AddressSuggestion? _startSuggestion;
  final TextEditingController destinationController = TextEditingController();
  AddressSuggestion? _destinationSuggestion;

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  late DateTime selectedDate;
  bool _wholeDay = true;
  int seats = 1;

  late final SearchRideFilter filter;

  List<Ride>? possibleRides;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.clock.now();
    filter = SearchRideFilter(wholeDay: _wholeDay);
    loadRides();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    startController.dispose();
    destinationController.dispose();
    super.dispose();
  }

  void _showDatePicker() {
    final DateTime firstDate = widget.clock.now();

    showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: firstDate,
      lastDate: firstDate.add(Trip.creationInterval),
    ).then((DateTime? value) {
      if (value != null) {
        setState(() {
          selectedDate = DateTime(value.year, value.month, value.day, selectedDate.hour, selectedDate.minute);
          _dateController.text = localeManager.formatDate(selectedDate);
        });
        if (_dateTimeValidator(_timeController.text) == null) loadRides();
      }
    });
  }

  void _showTimePicker() {
    showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: selectedDate.hour, minute: selectedDate.minute),
      builder: (BuildContext context, Widget? childWidget) {
        return MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: childWidget!);
      },
    ).then((TimeOfDay? value) {
      if (value != null) {
        setState(() {
          selectedDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, value.hour, value.minute);
          _timeController.text = localeManager.formatTime(selectedDate);
        });
        if (_dateTimeValidator(_timeController.text) == null) loadRides();
      }
    });
  }

  String? _dateTimeValidator(String? value) {
    if (value == null || value.isEmpty) {
      return S.of(context).formTimeValidateEmpty;
    }
    if (selectedDate.add(const Duration(minutes: 10)).isBefore(widget.clock.now())) {
      return S.of(context).formTimeValidateFuture;
    }
    return null;
  }

  Future<void> loadRides() async {
    if (_startSuggestion == null || _destinationSuggestion == null) return;
    setState(() => _loading = true);
    final List<Map<String, dynamic>> data = await supabaseManager.supabaseClient
        .from('drives')
        .select<List<Map<String, dynamic>>>('''
          *,
          driver:driver_id (
            *,
            profile_features (*),
            reviews_received: reviews!reviews_receiver_id_fkey(*)
          )
        ''')
        .eq('start', startController.text)
        .eq('status', DriveStatus.plannedOrFinished.index)
        .gt('start_time', DateTime.now());
    final List<Drive> drives = data.map((Map<String, dynamic> drive) => Drive.fromJson(drive)).toList();
    final List<Ride> rides = drives
        .map(
          (Drive drive) => Ride.previewFromDrive(
            drive,
            start: _startSuggestion!.name,
            startPosition: _startSuggestion!.position,
            end: _destinationSuggestion!.name,
            endPosition: _destinationSuggestion!.position,
            seats: seats,
            riderId: supabaseManager.currentProfile?.id ?? -1,
          ),
        )
        .toList();
    setState(() {
      possibleRides = rides;
      _loading = false;
    });
  }

  Widget buildSearchFieldViewer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: StartDestinationTimeline(
        startController: startController,
        destinationController: destinationController,
        onStartSelected: (AddressSuggestion suggestion) => setState(() {
          _startSuggestion = suggestion;
          loadRides();
        }),
        onDestinationSelected: (AddressSuggestion suggestion) => setState(() {
          _destinationSuggestion = suggestion;
          loadRides();
        }),
        onSwap: () => setState(() {
          final AddressSuggestion? oldStartSuggestion = _startSuggestion;
          _startSuggestion = _destinationSuggestion;
          _destinationSuggestion = oldStartSuggestion;
          loadRides();
        }),
      ),
    );
  }

  Widget buildDatePicker() {
    _dateController.text = localeManager.formatDate(selectedDate);

    return Semantics(
      button: true,
      child: TextFormField(
        key: const Key('searchRideDatePicker'),
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
    _timeController.text = localeManager.formatTime(selectedDate);

    return Semantics(
      button: true,
      child: TextFormField(
        key: const Key('searchRideTimePicker'),
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: S.of(context).formTime,
        ),
        validator: _dateTimeValidator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
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
              key: const Key('searchRideBeforeButton'),
              tooltip: S.of(context).before,
              onPressed: selectedDate.isSameDayAs(widget.clock.now())
                  ? null
                  : () => setState(() {
                        selectedDate = selectedDate.subtract(const Duration(days: 1));
                        loadRides();
                      }),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(child: buildDatePicker()),
            IconButton(
              key: const Key('searchRideAfterButton'),
              tooltip: S.of(context).after,
              onPressed: () => setState(() {
                selectedDate = selectedDate.add(const Duration(days: 1));
                loadRides();
              }),
              icon: const Icon(Icons.chevron_right),
            ),
          ] else ...<Widget>[
            Expanded(child: buildDatePicker()),
            const SizedBox(width: 10),
            Expanded(child: buildTimePicker()),
            const SizedBox(width: 10),
          ],
          LabeledCheckbox(
            key: const Key('searchRideWholeDayCheckbox'),
            label: S.of(context).pageSearchRideWholeDay,
            value: _wholeDay,
            onChanged: (bool? value) => setState(() {
              _wholeDay = value!;
              filter.wholeDay = _wholeDay;
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
              seats = value!;
              loadRides();
            });
          },
        ),
      ),
    );
  }

  Widget buildMainContentSliver() {
    if (possibleRides == null || _loading) {
      if (_startSuggestion == null || _destinationSuggestion == null) {
        return SliverToBoxAdapter(
          child: EmptySearchResults(
            key: const Key('searchRideNoInput'),
            asset: 'assets/pointing_up.png',
            title: S.of(context).pageSearchRideNoInput,
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

    final List<Ride> filterApplied = filter.apply(possibleRides!, selectedDate);
    final List<Ride> filteredSuggestions = applyTimeConstraints(filterApplied);

    if (filteredSuggestions.isEmpty) {
      return SliverToBoxAdapter(
        child: EmptySearchResults(
          asset: 'assets/shrug.png',
          title: S.of(context).pageSearchRideEmpty,
          subtitle: filterApplied.isNotEmpty
              ? Semantics(
                  button: true,
                  child: InkWell(
                    key: const Key('searchRideWrongTime'),
                    onTap: () => setState(
                      () {
                        selectedDate = filterApplied[0].startDateTime;
                        _dateController.text = localeManager.formatDate(selectedDate);
                        if (!_wholeDay) {
                          _timeController.text = localeManager.formatTime(selectedDate);
                        }
                      },
                    ),
                    child: Text(
                      S.of(context).pageSearchRideWrongTime,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : possibleRides!.isNotEmpty
                  ? Semantics(
                      button: true,
                      tooltip: S.of(context).pageSearchRideTooltipFilter,
                      child: InkWell(
                        key: const Key('searchRideRelaxRestrictions'),
                        onTap: () => filter.dialog(context, setState),
                        child: Text(
                          S.of(context).pageSearchRideRelaxRestrictions,
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : Text(
                      key: const Key('searchRideNoResults'),
                      S.of(context).pageSearchRideNoResults,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
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
              const SliverToBoxAdapter(child: SizedBox(height: 5)),
              SliverToBoxAdapter(child: buildSeats()),
              const SliverToBoxAdapter(child: SizedBox(height: 5)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: filter.buildIndicatorRow(context, setState),
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

  List<Ride> applyTimeConstraints(List<Ride> rides) {
    if (_wholeDay) {
      return rides.where((Ride ride) {
        return selectedDate.isSameDayAs(ride.startDateTime) || selectedDate.isSameDayAs(ride.endDateTime);
      }).toList();
    }
    return rides.where((Ride ride) {
      return selectedDate.difference(ride.startDateTime).inDays.abs() < 1 ||
          selectedDate.difference(ride.endDateTime).inDays.abs() < 1;
    }).toList();
  }
}

extension CustomDateTime on DateTime {
  bool isSameDayAs(DateTime other) {
    return day == other.day && month == other.month && year == other.year;
  }
}
