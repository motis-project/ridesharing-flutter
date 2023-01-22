import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../account/models/profile.dart';
import '../../account/models/profile_feature.dart';
import '../../account/models/review.dart';
import '../../util/profiles/reviews/custom_rating_bar.dart';
import '../../util/profiles/reviews/custom_rating_bar_size.dart';
import '../models/ride.dart';

class SearchRideFilter {
  static const List<Feature> _commonFeatures = <Feature>[
    Feature.noSmoking,
    Feature.noVaping,
    Feature.petsAllowed,
    Feature.childrenAllowed,
    Feature.talkative,
    Feature.relaxedDrivingStyle,
  ];
  static const int _defaultRating = 1;
  static const List<Feature> _defaultFeatures = <Feature>[];
  static const SearchRideSorting _defaultSorting = SearchRideSorting.relevance;

  bool _isRatingExpanded = false;
  bool _isFeatureListExpanded = false;
  late List<Feature> _retractedAdditionalFeatures;

  late int _minRating;
  late int _minComfortRating;
  late int _minSafetyRating;
  late int _minReliabilityRating;
  late int _minHospitalityRating;
  late List<Feature> _selectedFeatures;
  late SearchRideSorting _sorting;

  bool _wholeDay;

  void setDefaultFilterValues() {
    _retractedAdditionalFeatures = <Feature>[..._commonFeatures];

    _minRating = _defaultRating;
    _minComfortRating = _defaultRating;
    _minSafetyRating = _defaultRating;
    _minReliabilityRating = _defaultRating;
    _minHospitalityRating = _defaultRating;
    _selectedFeatures = <Feature>[..._defaultFeatures];
    _sorting = _defaultSorting;
  }

  SearchRideFilter({required bool wholeDay}) : _wholeDay = wholeDay {
    setDefaultFilterValues();
  }

  bool get wholeDay => _wholeDay;

  set wholeDay(bool wholeDay) {
    _wholeDay = wholeDay;
    if (_wholeDay && _sorting == SearchRideSorting.timeProximity) {
      _sorting = SearchRideFilter._defaultSorting;
    }
  }

  Widget _filterCategory(BuildContext context, String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
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
      S.of(context).searchRideFilterMinimumRating,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CustomRatingBar(
            size: CustomRatingBarSize.large,
            rating: _minRating,
            onRatingUpdate: (double newRating) => innerSetState(
              () => _minRating = newRating.toInt(),
            ),
          ),
          if (_isRatingExpanded) ...<Widget>[
            Text(S.of(context).reviewCategoryComfort),
            CustomRatingBar(
              size: CustomRatingBarSize.medium,
              rating: _minComfortRating,
              onRatingUpdate: (double newRating) => innerSetState(
                () => _minComfortRating = newRating.toInt(),
              ),
            ),
            Text(S.of(context).reviewCategorySafety),
            CustomRatingBar(
              size: CustomRatingBarSize.medium,
              rating: _minSafetyRating,
              onRatingUpdate: (double newRating) => innerSetState(
                () => _minSafetyRating = newRating.toInt(),
              ),
            ),
            Text(S.of(context).reviewCategoryReliability),
            CustomRatingBar(
              size: CustomRatingBarSize.medium,
              rating: _minReliabilityRating,
              onRatingUpdate: (double newRating) => innerSetState(
                () => _minReliabilityRating = newRating.toInt(),
              ),
            ),
            Text(S.of(context).reviewCategoryHospitality),
            CustomRatingBar(
              size: CustomRatingBarSize.medium,
              rating: _minHospitalityRating,
              onRatingUpdate: (double newRating) => innerSetState(
                () => _minHospitalityRating = newRating.toInt(),
              ),
            ),
          ],
          TextButton(
            onPressed: () => innerSetState(() => _isRatingExpanded = !_isRatingExpanded),
            child: Row(
              children: <Widget>[
                Text(_isRatingExpanded ? S.of(context).retract : S.of(context).expand),
                Icon(_isRatingExpanded ? Icons.expand_less : Icons.expand_more)
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesFilter(BuildContext context, void Function(void Function()) innerSetState) {
    List<Feature> shownFeatures;
    if (_isFeatureListExpanded) {
      shownFeatures = <Feature>{..._selectedFeatures, ...Feature.values}.toList();
    } else {
      shownFeatures = <Feature>{..._selectedFeatures, ..._retractedAdditionalFeatures}.toList();
    }
    return _filterCategory(
      context,
      S.of(context).searchRideFilterFeatures,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            runSpacing: -10,
            spacing: 2,
            children: List<Widget>.generate(
              shownFeatures.length,
              (int index) {
                final Feature feature = shownFeatures[index];
                final bool featureSelected = _selectedFeatures.contains(feature);
                return FilterChip(
                  avatar: feature.getIcon(context),
                  label: Text(feature.getDescription(context)),
                  selected: _selectedFeatures.contains(feature),
                  tooltip: featureSelected
                      ? S.of(context).searchRideFilterFeaturesDeselectTooltip
                      : S.of(context).searchRideFilterFeaturesSelectTooltip,
                  onSelected: (bool selected) {
                    if (featureSelected) {
                      innerSetState(() {
                        _selectedFeatures.remove(feature);
                        if (!_isFeatureListExpanded) _retractedAdditionalFeatures.insert(0, feature);
                      });
                    } else {
                      final Feature? mutuallyExclusiveFeature = _selectedFeatures
                          .firstWhereOrNull((Feature selectedFeature) => selectedFeature.isMutuallyExclusive(feature));
                      if (mutuallyExclusiveFeature != null) {
                        final String description = mutuallyExclusiveFeature.getDescription(context);
                        final String text = S.of(context).pageProfileEditProfileFeaturesMutuallyExclusive(description);
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
            onPressed: () => innerSetState(() {
              _isFeatureListExpanded = !_isFeatureListExpanded;
              if (_selectedFeatures.isNotEmpty) {
                _retractedAdditionalFeatures = <Feature>[];
              } else {
                _retractedAdditionalFeatures = <Feature>[..._commonFeatures];
              }
            }),
            child: Row(
              children: <Widget>[
                Text(_isFeatureListExpanded ? S.of(context).retract : S.of(context).expand),
                Icon(_isFeatureListExpanded ? Icons.expand_less : Icons.expand_more)
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortingFilter(BuildContext context, void Function(void Function()) innerSetState) {
    return _filterCategory(
      context,
      S.of(context).searchRideFilterSorting,
      DropdownButton<SearchRideSorting>(
        value: _sorting,
        items: SearchRideSorting.values.map((SearchRideSorting sorting) {
          final bool enabled = !(_wholeDay && sorting == SearchRideSorting.timeProximity);
          return DropdownMenuItem<SearchRideSorting>(
            enabled: enabled,
            value: sorting,
            child: Text(
              sorting.getDescription(context),
              style: enabled ? null : TextStyle(color: Theme.of(context).disabledColor),
            ),
          );
        }).toList(),
        onChanged: (SearchRideSorting? value) => innerSetState(
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
          builder: (BuildContext context, void Function(void Function()) innerSetState) {
            return Scaffold(
              backgroundColor: Colors.transparent,
              body: AlertDialog(
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _buildRatingFilter(context, innerSetState),
                      _buildFeaturesFilter(context, innerSetState),
                      _buildSortingFilter(context, innerSetState),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text(S.of(context).searchRideFilterResetToDefault),
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
    return Row(
      children: <Widget>[
        if (icon != null) ...<Widget>[icon, const SizedBox(width: 3)],
        Text(rating.toString()),
        const Icon(
          Icons.star,
          color: Colors.amber,
        )
      ],
    );
  }

  Widget buildIndicatorRow(BuildContext context, void Function(void Function()) setState) {
    final bool isRatingDefault = _minRating == _defaultRating &&
        _minComfortRating == _defaultRating &&
        _minSafetyRating == _defaultRating &&
        _minReliabilityRating == _defaultRating &&
        _minHospitalityRating == _defaultRating;
    final bool isFeaturesDefault = _selectedFeatures.equals(_defaultFeatures);

    final List<Widget> widgets = <Widget>[];
    if (!isRatingDefault) {
      final List<Widget> ratingWidgets = <Widget>[];
      if (_minRating != _defaultRating) {
        ratingWidgets.add(_buildSmallRatingIndicator(_minRating));
        if (_minComfortRating != _defaultRating ||
            _minSafetyRating != _defaultRating ||
            _minReliabilityRating != _defaultRating ||
            _minHospitalityRating != _defaultRating) {
          ratingWidgets.add(const SizedBox(width: 4));
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
      final int numDividers = ratingWidgets.length - 1;
      for (int i = 0; i < numDividers; i++) {
        ratingWidgets.insert(i * 2 + 1, const SizedBox(width: 10));
      }
      final Widget ratingsRow = Row(children: ratingWidgets);
      widgets.add(ratingsRow);
    }
    if (!isFeaturesDefault) {
      final Widget featuresRow =
          Row(children: _selectedFeatures.map((Feature feature) => feature.getIcon(context)).toList());
      widgets.add(featuresRow);
    }
    final Widget sortingWidget = Row(
      children: <Widget>[const Icon(Icons.sort), Text(_sorting.getDescription(context))],
    );
    widgets.add(sortingWidget);
    final int numDividers = widgets.length - 1;
    for (int i = 0; i < numDividers; i++) {
      widgets.insert(i * 2 + 1, const VerticalDivider(thickness: 2));
    }
    return IntrinsicHeight(
      child: Semantics(
        button: true,
        tooltip: S.of(context).pageSearchRideTooltipFilter,
        child: InkWell(
          onTap: () => dialog(context, setState),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Row(
              children: <Widget>[
                const Icon(Icons.tune),
                const SizedBox(width: 6),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: widgets,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Ride> apply(List<Ride> rideSuggestions, DateTime date) {
    return rideSuggestions
        .where(
          (Ride ride) {
            final Profile driver = ride.drive!.driver!;
            final AggregateReview driverReview = AggregateReview.fromReviews(driver.reviewsReceived!);
            final bool ratingSatisfied = (!driverReview.isRatingSet || driverReview.rating >= _minRating) &&
                (!driverReview.isComfortSet || driverReview.comfortRating >= _minComfortRating) &&
                (!driverReview.isSafetySet || driverReview.safetyRating >= _minSafetyRating) &&
                (!driverReview.isReliabilitySet || driverReview.reliabilityRating >= _minReliabilityRating) &&
                (!driverReview.isHospitalitySet || driverReview.hospitalityRating >= _minHospitalityRating);
            final bool featuresSatisfied = Set<Feature>.of(driver.features!).containsAll(_selectedFeatures);
            final bool wholeDaySatisfied =
                !_wholeDay || date.isSameDayAs(ride.startTime) || date.isSameDayAs(ride.endTime);
            return ratingSatisfied && featuresSatisfied && wholeDaySatisfied;
          },
        )
        .sorted(_sorting.sortFunction(date))
        .toList();
  }
}

enum SearchRideSorting {
  relevance,
  travelDuration,
  price,
  timeProximity,
}

extension SearchRideSortingExtension on SearchRideSorting {
  String getDescription(BuildContext context) {
    switch (this) {
      case SearchRideSorting.relevance:
        return S.of(context).searchRideSortingRelevance;
      case SearchRideSorting.travelDuration:
        return S.of(context).searchRideSortingTravelDuration;
      case SearchRideSorting.price:
        return S.of(context).searchRideSortingPrice;
      case SearchRideSorting.timeProximity:
        return S.of(context).searchRideSortingTimeProximity;
    }
  }

  int Function(Ride, Ride) sortFunction(DateTime date) {
    int travelDurationFunc(Ride ride1, Ride ride2) => (ride1.duration - ride2.duration).inMinutes;
    int priceFunc(Ride ride1, Ride ride2) => ((ride1.price! - ride2.price!) * 100).toInt();
    int timeProximityFunc(Ride ride1, Ride ride2) =>
        (date.difference(ride1.startTime).abs() - date.difference(ride2.startTime).abs()).inMinutes;
    switch (this) {
      case SearchRideSorting.relevance:
        return (Ride ride1, Ride ride2) =>
            travelDurationFunc(ride1, ride2) + priceFunc(ride1, ride2) + timeProximityFunc(ride1, ride2);
      case SearchRideSorting.travelDuration:
        return travelDurationFunc;
      case SearchRideSorting.price:
        return priceFunc;
      case SearchRideSorting.timeProximity:
        return timeProximityFunc;
    }
  }
}

extension CustomDateTime on DateTime {
  bool isSameDayAs(DateTime other) {
    return day == other.day && month == other.month && year == other.year;
  }
}
