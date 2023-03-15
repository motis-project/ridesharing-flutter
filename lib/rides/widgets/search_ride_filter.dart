import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../account/models/profile.dart';
import '../../account/models/profile_feature.dart';
import '../../account/models/review.dart';
import '../../util/profiles/reviews/custom_rating_bar.dart';
import '../../util/profiles/reviews/custom_rating_bar_size.dart';
import '../../util/snackbar.dart';
import '../models/ride.dart';

class SearchRideFilter {
  static const List<Feature> commonFeatures = <Feature>[
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
  late SearchRideSorting sorting;

  bool _wholeDay;

  void setDefaultFilterValues() {
    _retractedAdditionalFeatures = <Feature>[...commonFeatures];

    _minRating = _defaultRating;
    _minComfortRating = _defaultRating;
    _minSafetyRating = _defaultRating;
    _minReliabilityRating = _defaultRating;
    _minHospitalityRating = _defaultRating;
    _selectedFeatures = <Feature>[..._defaultFeatures];
    sorting = _defaultSorting;
  }

  SearchRideFilter({required bool wholeDay}) : _wholeDay = wholeDay {
    setDefaultFilterValues();
  }

  bool get wholeDay => _wholeDay;

  set wholeDay(bool wholeDay) {
    _wholeDay = wholeDay;
    if (_wholeDay && sorting == SearchRideSorting.timeProximity) {
      sorting = SearchRideFilter._defaultSorting;
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
            key: const Key('searchRideRatingBar'),
            size: CustomRatingBarSize.large,
            rating: _minRating,
            onRatingUpdate: (double newRating) => innerSetState(
              () => _minRating = newRating.toInt(),
            ),
          ),
          if (_isRatingExpanded) ...<Widget>[
            Text(S.of(context).reviewCategoryComfort),
            CustomRatingBar(
              key: const Key('searchRideComfortRatingBar'),
              rating: _minComfortRating,
              onRatingUpdate: (double newRating) => innerSetState(
                () => _minComfortRating = newRating.toInt(),
              ),
            ),
            Text(S.of(context).reviewCategorySafety),
            CustomRatingBar(
              key: const Key('searchRideSafetyRatingBar'),
              rating: _minSafetyRating,
              onRatingUpdate: (double newRating) => innerSetState(
                () => _minSafetyRating = newRating.toInt(),
              ),
            ),
            Text(S.of(context).reviewCategoryReliability),
            CustomRatingBar(
              key: const Key('searchRideReliabilityRatingBar'),
              rating: _minReliabilityRating,
              onRatingUpdate: (double newRating) => innerSetState(
                () => _minReliabilityRating = newRating.toInt(),
              ),
            ),
            Text(S.of(context).reviewCategoryHospitality),
            CustomRatingBar(
              key: const Key('searchRideHospitalityRatingBar'),
              rating: _minHospitalityRating,
              onRatingUpdate: (double newRating) => innerSetState(
                () => _minHospitalityRating = newRating.toInt(),
              ),
            ),
          ],
          TextButton(
            key: const Key('searchRideRatingExpandButton'),
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
                  key: Key('searchRideFeatureChip${feature.name}'),
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
                        return showSnackBar(
                          key: const Key('searchRideFeatureMutuallyExclusiveSnackBar'),
                          context,
                          S.of(context).pageProfileEditProfileFeaturesMutuallyExclusive(description),
                        );
                      }
                      innerSetState(() => _selectedFeatures.add(feature));
                    }
                  },
                );
              },
            ),
          ),
          TextButton(
            key: const Key('searchRideFeaturesExpandButton'),
            onPressed: () => innerSetState(() {
              _isFeatureListExpanded = !_isFeatureListExpanded;
              if (_selectedFeatures.isNotEmpty) {
                _retractedAdditionalFeatures = <Feature>[];
              } else {
                _retractedAdditionalFeatures = <Feature>[...commonFeatures];
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

  Widget _buildSortingFilter(BuildContext context, void Function(void Function()) setState) {
    return RepaintBoundary(
      child: DropdownButton<SearchRideSorting>(
        key: const Key('searchRideSortingDropdownButton'),
        icon: const Icon(Icons.sort),
        value: sorting,
        items: SearchRideSorting.values.map((SearchRideSorting rideSorting) {
          final bool enabled = !(_wholeDay && rideSorting == SearchRideSorting.timeProximity);
          return DropdownMenuItem<SearchRideSorting>(
            key: Key('searchRideSortingDropdownItem${rideSorting.name}'),
            enabled: enabled,
            value: rideSorting,
            child: Text(
              rideSorting.getDescription(context),
              style: enabled ? null : TextStyle(color: Theme.of(context).disabledColor),
            ),
          );
        }).toList(),
        onChanged: (SearchRideSorting? value) => setState(
          () => sorting = value!,
        ),
        underline: const SizedBox(),
      ),
    );
  }

  void dialog(BuildContext context, void Function(void Function()) setState) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => ScaffoldMessenger(
        child: StatefulBuilder(
          builder: (BuildContext context, void Function(void Function()) innerSetState) {
            return Scaffold(
              backgroundColor: Colors.transparent,
              body: AlertDialog(
                key: const Key('searchRideFilterDialog'),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _buildRatingFilter(context, innerSetState),
                      _buildFeaturesFilter(context, innerSetState),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    key: const Key('searchRideFilterResetToDefaultButton'),
                    child: Text(S.of(context).searchRideFilterResetToDefault),
                    onPressed: () => innerSetState(() => setDefaultFilterValues()),
                  ),
                  TextButton(
                    key: const Key('searchRideFilterOkayButton'),
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
        ratingWidgets.insert(i * 2 + 1, SizedBox(key: Key('ratingSizedBox$i'), width: 10));
      }
      if (_minRating != _defaultRating && numDividers > 0) {
        ratingWidgets.insert(1, const SizedBox(width: 4));
      }
      final Widget ratingsRow = Row(children: ratingWidgets);
      widgets.add(ratingsRow);
    }
    if (!isFeaturesDefault) {
      final Widget featuresRow =
          Row(children: _selectedFeatures.map((Feature feature) => feature.getIcon(context)).toList());
      widgets.add(featuresRow);
    }
    final int numDividers = widgets.length - 1;
    for (int i = 0; i < numDividers; i++) {
      widgets.insert(i * 2 + 1, const VerticalDivider(thickness: 2));
    }
    return IntrinsicHeight(
      child: Row(
        children: <Widget>[
          Expanded(
            child: Semantics(
              button: true,
              tooltip: S.of(context).pageSearchRideTooltipFilter,
              child: SizedBox(
                height: double.infinity,
                child: InkWell(
                  key: const Key('searchRideFilterButton'),
                  onTap: () => dialog(context, setState),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.tune),
                        const SizedBox(width: 6),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: widgets,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          _buildSortingFilter(context, setState)
        ],
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
            return ratingSatisfied && featuresSatisfied;
          },
        )
        .sorted(sorting.sortFunction(date, wholeDay: wholeDay))
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

  int Function(Ride, Ride) sortFunction(DateTime date, {bool wholeDay = false}) {
    int travelDurationFunc(Ride ride1, Ride ride2) => (ride1.duration - ride2.duration).inMinutes;
    int priceFunc(Ride ride1, Ride ride2) => ((ride1.price! - ride2.price!) * 100).toInt();
    int timeProximityFunc(Ride ride1, Ride ride2) =>
        (date.difference(ride1.startDateTime).abs() - date.difference(ride2.startDateTime).abs()).inMinutes;
    switch (this) {
      case SearchRideSorting.relevance:
        return (Ride ride1, Ride ride2) =>
            travelDurationFunc(ride1, ride2) +
            priceFunc(ride1, ride2) +
            (wholeDay ? 0 : timeProximityFunc(ride1, ride2));
      case SearchRideSorting.travelDuration:
        return travelDurationFunc;
      case SearchRideSorting.price:
        return priceFunc;
      case SearchRideSorting.timeProximity:
        return timeProximityFunc;
    }
  }
}
