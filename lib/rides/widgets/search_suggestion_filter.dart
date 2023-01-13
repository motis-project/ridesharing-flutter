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
    List<Feature> shownFeatures = _isFeatureListExpanded ? Feature.values : _commonFeatures;
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
      builder: (BuildContext context) => StatefulBuilder(
        builder: (context, innerSetState) {
          return AlertDialog(
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
          );
        },
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
