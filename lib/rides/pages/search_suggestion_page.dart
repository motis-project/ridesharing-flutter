import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/account/models/profile_feature.dart';
import 'package:motis_mitfahr_app/util/locale_manager.dart';
import 'package:motis_mitfahr_app/util/profiles/reviews/custom_rating_bar.dart';
import 'package:motis_mitfahr_app/util/profiles/reviews/custom_rating_bar_size.dart';
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

  //Filter
  static const List<Feature> _commonFeatures = [
    Feature.noSmoking,
    Feature.noVaping,
    Feature.petsAllowed,
    Feature.childrenAllowed,
    Feature.talkative,
    Feature.relaxedDrivingStyle,
  ];

  bool _isRatingExpanded = false;
  bool _isFeatureListExpanded = false;

  late int _minRating;
  late int _minComfortRating;
  late int _minSafetyRating;
  late int _minReliabilityRating;
  late int _minHospitalityRating;
  late List<Feature> _selectedFeatures;
  late SearchSuggestionSorting _sorting;
  final _maxDeviationController = TextEditingController();

  void setDefaultFilterValues() {
    _minRating = 1;
    _minComfortRating = 1;
    _minSafetyRating = 1;
    _minReliabilityRating = 1;
    _minHospitalityRating = 1;
    _selectedFeatures = [];
    _maxDeviationController.text = "12";
    _sorting = SearchSuggestionSorting.relevance;
  }

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
    setDefaultFilterValues();
    loadRides();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _startController.dispose();
    _destinationController.dispose();
    _maxDeviationController.dispose();
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
  Future<void> loadRides() async {
    List<dynamic> data = await SupabaseManager.supabaseClient.from('drives').select('''
          *,
          driver:driver_id (
            *,
            profile_features (*),
            reviews_received: reviews!reviews_receiver_id_fkey(*)
          )
        ''').eq('start', _startController.text);
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

  FixedTimeline buildSearchFieldViewer() {
    return FixedTimeline(theme: CustomTimelineTheme.of(context), children: [
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
    ]);
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

  Widget buildLocationPicker({bool isStart = true}) {
    TextEditingController controller = isStart ? _startController : _destinationController;

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
    List<Ride> filteredSuggestions = _applyFilters(_rideSuggestions!);
    Widget list;
    if (filteredSuggestions.isEmpty) {
      list = Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              Image.asset('assets/shrug.png'),
              Text(
                S.of(context).pageSearchSuggestionsEmpty,
                style: Theme.of(context).textTheme.displaySmall,
              ),
            ],
          ),
        ),
      );
    } else {
      list = ListView.separated(
        itemBuilder: (context, index) {
          final ride = filteredSuggestions[index];
          return SearchCard(ride);
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
      children: [
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
      appBar: AppBar(
        title: Text(S.of(context).pageSearchSuggestionsTitle),
        actions: [buildFilterPicker()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            buildSearchFieldViewer(),
            const SizedBox(height: 10),
            buildDateSeatsRow(),
            const Divider(thickness: 1),
            buildSearchCardList(),
          ],
        ),
      ),
    );
  }

  Widget buildFilterPicker() {
    return IconButton(
      onPressed: _showFilterDialog,
      icon: const Icon(Icons.tune),
      tooltip: S.of(context).pageSearchSuggestionsTooltipFilter,
    );
  }

  Widget filterCategory(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content,
      ],
    );
  }

  Widget _buildRatingFilter(void Function(void Function()) innerSetState) {
    return filterCategory(
      S.of(context).pageSearchSuggestionsFilterMinimumRating,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomRatingBar(
            size: CustomRatingBarSize.large,
            rating: _minRating,
            onRatingUpdate: (newRating) => innerSetState(
              () => _minRating = newRating.toInt(),
            ),
          ),
          if (_isRatingExpanded) ...[
            Text(S.of(context).reviewCategoryComfort),
            CustomRatingBar(
              size: CustomRatingBarSize.medium,
              rating: _minComfortRating,
              onRatingUpdate: (newRating) => innerSetState(
                () => _minComfortRating = newRating.toInt(),
              ),
            ),
            Text(S.of(context).reviewCategorySafety),
            CustomRatingBar(
              size: CustomRatingBarSize.medium,
              rating: _minSafetyRating,
              onRatingUpdate: (newRating) => innerSetState(
                () => _minSafetyRating = newRating.toInt(),
              ),
            ),
            Text(S.of(context).reviewCategoryReliability),
            CustomRatingBar(
              size: CustomRatingBarSize.medium,
              rating: _minReliabilityRating,
              onRatingUpdate: (newRating) => innerSetState(
                () => _minReliabilityRating = newRating.toInt(),
              ),
            ),
            Text(S.of(context).reviewCategoryHospitality),
            CustomRatingBar(
              size: CustomRatingBarSize.medium,
              rating: _minHospitalityRating,
              onRatingUpdate: (newRating) => innerSetState(
                () => _minHospitalityRating = newRating.toInt(),
              ),
            ),
          ],
          TextButton(
            onPressed: () => innerSetState(() => _isRatingExpanded = !_isRatingExpanded),
            child: Text(_isRatingExpanded ? S.of(context).retract : S.of(context).expand),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesFilter(void Function(void Function()) innerSetState) {
    List<Feature> shownFeatures = _isFeatureListExpanded ? Feature.values : _commonFeatures;
    return filterCategory(
      S.of(context).pageSearchSuggestionsFilterFeatures,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            runSpacing: -10,
            children: List.generate(
              shownFeatures.length,
              (index) {
                Feature feature = shownFeatures[index];
                bool featureSelected = _selectedFeatures.contains(feature);
                return FilterChip(
                  avatar: feature.getIcon(context),
                  label: Text(feature.getDescription(context)),
                  selected: _selectedFeatures.contains(feature),
                  tooltip: featureSelected
                      ? S.of(context).pageSearchSuggestionsFilterFeaturesDeselectTooltip
                      : S.of(context).pageSearchSuggestionsFilterFeaturesSelectTooltip,
                  onSelected: (selected) {
                    if (featureSelected) {
                      innerSetState(() => _selectedFeatures.remove(feature));
                    } else {
                      Feature? mutuallyExclusiveFeature = _selectedFeatures
                          .firstWhereOrNull((selectedFeature) => selectedFeature.isMutuallyExclusive(feature));
                      if (mutuallyExclusiveFeature != null) {
                        String description = mutuallyExclusiveFeature.getDescription(context);
                        String text = S.of(context).pageProfileEditProfileFeaturesMutuallyExclusive(description);
                        SemanticsService.announce(text, TextDirection.ltr);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(text)),
                        );
                        return;
                      }
                      innerSetState(() => _selectedFeatures.add(feature));
                    }
                  },
                );
              },
            ),
          ),
          TextButton(
            onPressed: () => innerSetState(() => _isFeatureListExpanded = !_isFeatureListExpanded),
            child: Text(_isFeatureListExpanded ? S.of(context).retract : S.of(context).expand),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviationFilter() {
    return filterCategory(
      S.of(context).pageSearchSuggestionsFilterDeviation,
      Row(
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: TextField(
              controller: _maxDeviationController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ),
          Text(S.of(context).pageSearchSuggestionsFilterDeviationHours),
        ],
      ),
    );
  }

  Widget _buildSortingFilter(void Function(void Function()) innerSetState) {
    return filterCategory(
      S.of(context).pageSearchSuggestionsFilterSorting,
      DropdownButton(
        value: _sorting,
        items: SearchSuggestionSorting.values
            .map(
              (sorting) => DropdownMenuItem(
                value: sorting,
                child: Text(sorting.getDescription(context)),
              ),
            )
            .toList(),
        onChanged: (SearchSuggestionSorting? value) => innerSetState(
          () => _sorting = value!,
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (context, innerSetState) {
          return AlertDialog(
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildRatingFilter(innerSetState),
                  _buildFeaturesFilter(innerSetState),
                  _buildDeviationFilter(),
                  _buildSortingFilter(innerSetState),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text(S.of(context).pageSearchSuggestionsFilterResetToDefault),
                onPressed: () => innerSetState(() => setDefaultFilterValues()),
              ),
              TextButton(
                child: Text(S.of(context).okay),
                onPressed: () {
                  setState(() {});
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      ),
    );
  }

  List<Ride> _applyFilters(List<Ride> rideSuggestions) {
    return rideSuggestions
        .where(
          (Ride ride) {
            Profile driver = ride.drive!.driver!;
            bool ratingSatisfied = driver.getAggregateReview().rating >= _minRating &&
                driver.getAggregateReview().comfortRating >= _minComfortRating &&
                driver.getAggregateReview().safetyRating >= _minSafetyRating &&
                driver.getAggregateReview().reliabilityRating >= _minReliabilityRating &&
                driver.getAggregateReview().hospitalityRating >= _minHospitalityRating;
            bool featuresSatisfied = Set.of(driver.profileFeatures!).containsAll(_selectedFeatures);
            bool maxDeviationSatisfied =
                _selectedDate.difference(ride.startTime) < Duration(hours: int.parse(_maxDeviationController.text));
            return ratingSatisfied && featuresSatisfied && maxDeviationSatisfied;
          },
        )
        .sorted(_sorting.sortFunction(_selectedDate))
        .toList();
  }
}

enum SearchSuggestionSorting { relevance, time, price }

extension SearchSuggestionSortingExtension on SearchSuggestionSorting {
  String getDescription(BuildContext context) {
    switch (this) {
      case SearchSuggestionSorting.relevance:
        return S.of(context).pageSearchSuggestionsSortingRelevance;
      case SearchSuggestionSorting.time:
        return S.of(context).pageSearchSuggestionsSortingTime;
      case SearchSuggestionSorting.price:
        return S.of(context).pageSearchSuggestionsSortingPrice;
    }
  }

  int Function(Ride, Ride) sortFunction(DateTime date) {
    timeFunc(Ride ride1, Ride ride2) => date.difference(ride1.startTime).compareTo(date.difference(ride2.startTime));
    priceFunc(Ride ride1, Ride ride2) => ride1.price!.compareTo(ride2.price!);
    switch (this) {
      case SearchSuggestionSorting.relevance:
        return (ride1, ride2) => timeFunc(ride1, ride2) + priceFunc(ride1, ride2);
      case SearchSuggestionSorting.time:
        return timeFunc;
      case SearchSuggestionSorting.price:
        return priceFunc;
    }
  }
}
