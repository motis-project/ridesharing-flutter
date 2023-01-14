import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/account/models/profile_feature.dart';
import 'package:motis_mitfahr_app/rides/models/ride.dart';
import 'package:motis_mitfahr_app/util/profiles/reviews/custom_rating_bar.dart';
import 'package:motis_mitfahr_app/util/profiles/reviews/custom_rating_bar_size.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SearchSuggestionFilter {
  static const List<Feature> _commonFeatures = [
    Feature.noSmoking,
    Feature.noVaping,
    Feature.petsAllowed,
    Feature.childrenAllowed,
    Feature.talkative,
    Feature.relaxedDrivingStyle,
  ];
  static const int _defaultRating = 1;
  static const List<Feature> _defaultFeatures = [];
  static const SearchSuggestionSorting _defaultSorting = SearchSuggestionSorting.relevance;
  static const String _defaultDeviation = "12";

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
    _minRating = _defaultRating;
    _minComfortRating = _defaultRating;
    _minSafetyRating = _defaultRating;
    _minReliabilityRating = _defaultRating;
    _minHospitalityRating = _defaultRating;
    _selectedFeatures = [..._defaultFeatures];
    _maxDeviationController.text = _defaultDeviation;
    _sorting = _defaultSorting;
  }

  SearchSuggestionFilter() {
    setDefaultFilterValues();
  }

  Widget _filterCategory(BuildContext context, String title, Widget content) {
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

  Widget _buildRatingFilter(BuildContext context, void Function(void Function()) innerSetState) {
    return _filterCategory(
      context,
      S.of(context).searchSuggestionsFilterMinimumRating,
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

  Widget _buildFeaturesFilter(BuildContext context, void Function(void Function()) innerSetState) {
    List<Feature> shownFeatures =
        _isFeatureListExpanded ? Feature.values : {..._commonFeatures, ..._selectedFeatures}.toList();
    return _filterCategory(
      context,
      S.of(context).searchSuggestionsFilterFeatures,
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
                      ? S.of(context).searchSuggestionsFilterFeaturesDeselectTooltip
                      : S.of(context).searchSuggestionsFilterFeaturesSelectTooltip,
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

  Widget _buildDeviationFilter(BuildContext context) {
    return _filterCategory(
      context,
      S.of(context).searchSuggestionsFilterDeviation,
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
          Text(S.of(context).searchSuggestionsFilterDeviationHours),
        ],
      ),
    );
  }

  Widget _buildSortingFilter(BuildContext context, void Function(void Function()) innerSetState) {
    return _filterCategory(
      context,
      S.of(context).searchSuggestionsFilterSorting,
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

  void dialog(BuildContext context, void Function(void Function()) setState) {
    showDialog(
      context: context,
      builder: (BuildContext context) => ScaffoldMessenger(
        child: StatefulBuilder(
          builder: (context, innerSetState) {
            return Scaffold(
              backgroundColor: Colors.transparent,
              body: AlertDialog(
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildRatingFilter(context, innerSetState),
                      _buildFeaturesFilter(context, innerSetState),
                      _buildDeviationFilter(
                        context,
                      ),
                      _buildSortingFilter(context, innerSetState),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text(S.of(context).searchSuggestionsFilterResetToDefault),
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
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSmallRatingIndicator(int rating, {Icon? icon}) {
    return Row(children: [
      if (icon != null) ...[icon, const SizedBox(width: 3)],
      Text(rating.toString()),
      const Icon(
        Icons.star,
        color: Colors.amber,
      )
    ]);
  }

  Widget getRow(BuildContext context, void Function(void Function()) setState) {
    bool isRatingDefault = _minRating == _defaultRating &&
        _minComfortRating == _defaultRating &&
        _minSafetyRating == _defaultRating &&
        _minReliabilityRating == _defaultRating &&
        _minHospitalityRating == _defaultRating;
    bool isFeaturesDefault = _selectedFeatures == _defaultFeatures;
    bool isDeviationDefault = _maxDeviationController.text == _defaultDeviation;

    List<Widget> widgets = [];
    if (!isRatingDefault) {
      List<Widget> ratingWidgets = [];
      if (_minRating != _defaultRating) {
        ratingWidgets.add(_buildSmallRatingIndicator(_minRating));
        if (_minComfortRating != _defaultRating ||
            _minSafetyRating != _defaultRating ||
            _minReliabilityRating != _defaultRating ||
            _minHospitalityRating != _defaultRating) {
          ratingWidgets.add(const SizedBox(width: 6));
        }
      }
      if (_minComfortRating != _defaultRating) {
        ratingWidgets.add(
          _buildSmallRatingIndicator(
            _minComfortRating,
            icon: Icon(
              Icons.chair,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        );
      }
      if (_minSafetyRating != _defaultRating) {
        ratingWidgets.add(
          _buildSmallRatingIndicator(
            _minSafetyRating,
            icon: Icon(
              Icons.health_and_safety,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        );
      }
      if (_minReliabilityRating != _defaultRating) {
        ratingWidgets.add(
          _buildSmallRatingIndicator(
            _minReliabilityRating,
            icon: Icon(
              Icons.timer,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        );
      }
      if (_minHospitalityRating != _defaultRating) {
        ratingWidgets.add(
          _buildSmallRatingIndicator(
            _minHospitalityRating,
            icon: Icon(
              Icons.favorite,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        );
      }
      int numDividers = ratingWidgets.length - 1;
      for (int i = 0; i < numDividers; i++) {
        ratingWidgets.insert(i * 2 + 1, const SizedBox(width: 5));
      }
      Widget ratingsRow = Row(children: ratingWidgets);
      widgets.add(ratingsRow);
    }
    if (!isFeaturesDefault) {
      Widget featuresRow = Row(children: _selectedFeatures.map((feature) => feature.getIcon(context)).toList());
      widgets.add(featuresRow);
    }
    if (!isDeviationDefault) {
      Widget deviationWidget = Row(
        children: [const Icon(Icons.schedule), const SizedBox(width: 6), Text("± ${_maxDeviationController.text}")],
      );
      widgets.add(deviationWidget);
    }
    Widget sortingWidget = Row(
      children: [const Icon(Icons.sort), Text(_sorting.getDescription(context))],
    );
    widgets.add(sortingWidget);
    int numDividers = widgets.length - 1;
    for (int i = 0; i < numDividers; i++) {
      widgets.insert(i * 2 + 1, const VerticalDivider(indent: 5, endIndent: 5));
    }
    return IntrinsicHeight(
      child: Row(
        children: [
          IconButton(
            onPressed: () => dialog(context, setState),
            icon: const Icon(Icons.tune),
            tooltip: S.of(context).pageSearchSuggestionsTooltipFilter,
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: widgets,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Ride> apply(List<Ride> rideSuggestions, DateTime date) {
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
                date.difference(ride.startTime) < Duration(hours: int.parse(_maxDeviationController.text));
            return ratingSatisfied && featuresSatisfied && maxDeviationSatisfied;
          },
        )
        .sorted(_sorting.sortFunction(date))
        .toList();
  }

  void dispose() {
    _maxDeviationController.dispose();
  }
}

enum SearchSuggestionSorting { relevance, time, price }

extension SearchSuggestionSortingExtension on SearchSuggestionSorting {
  String getDescription(BuildContext context) {
    switch (this) {
      case SearchSuggestionSorting.relevance:
        return S.of(context).searchSuggestionsSortingRelevance;
      case SearchSuggestionSorting.time:
        return S.of(context).searchSuggestionsSortingTime;
      case SearchSuggestionSorting.price:
        return S.of(context).searchSuggestionsSortingPrice;
    }
  }

  int Function(Ride, Ride) sortFunction(DateTime date) {
    timeFunc(Ride ride1, Ride ride2) => (date.difference(ride1.startTime) - date.difference(ride2.startTime)).inMinutes;
    priceFunc(Ride ride1, Ride ride2) => ((ride1.price! - ride2.price!) * 100).toInt();
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
