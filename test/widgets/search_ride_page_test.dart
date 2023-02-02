import 'package:collection/collection.dart';
import 'package:faker/faker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/account/models/profile_feature.dart';
import 'package:motis_mitfahr_app/drives/models/drive.dart';
import 'package:motis_mitfahr_app/rides/models/ride.dart';
import 'package:motis_mitfahr_app/rides/pages/search_ride_page.dart';
import 'package:motis_mitfahr_app/rides/widgets/search_ride_filter.dart';
import 'package:motis_mitfahr_app/util/search/position.dart';
import 'package:motis_mitfahr_app/util/search/start_destination_timeline.dart';
import 'package:motis_mitfahr_app/util/trip/ride_card.dart';

import '../util/factories/address_suggestion_factory.dart';
import '../util/factories/drive_factory.dart';
import '../util/factories/model_factory.dart';
import '../util/factories/profile_factory.dart';
import '../util/factories/profile_feature_factory.dart';
import '../util/factories/review_factory.dart';
import '../util/mocks/mock_server.dart';
import '../util/mocks/request_processor.dart';
import '../util/mocks/request_processor.mocks.dart';
import '../util/pump_material.dart';

void main() {
  final MockRequestProcessor processor = MockRequestProcessor();

  final Finder pageFinder = find.byType(SearchRidePage);

  setUpAll(() {
    MockServer.setProcessor(processor);
  });

  setUp(() {
    reset(processor);
  });

  Future<void> enterStartAndDestination(WidgetTester tester, String? start, String? destination) async {
    final SearchRidePageState pageState = tester.state(pageFinder);
    final StartDestinationTimeline timeline =
        find.byType(StartDestinationTimeline).evaluate().first.widget as StartDestinationTimeline;

    if (start != null) {
      pageState.startController.text = start;
      timeline.onStartSelected(AddressSuggestionFactory().generateFake(name: start));
    }
    if (destination != null) {
      pageState.destinationController.text = destination;
      timeline.onDestinationSelected(AddressSuggestionFactory().generateFake(name: destination));
    }
    await tester.pump();
  }

  Future<void> enterDate(WidgetTester tester, DateTime dateTime) async {
    await tester.tap(find.byKey(const Key('searchRideDatePicker')));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pump();
    await tester.enterText(find.byType(InputDatePickerFormField), '${dateTime.month}/${dateTime.day}/${dateTime.year}');
    await tester.tap(find.text('OK'));
    await tester.pump();
  }

  Future<void> enterTime(WidgetTester tester, DateTime dateTime) async {
    await tester.tap(find.byKey(const Key('searchRideTimePicker')));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.keyboard));
    await tester.pump();
    final Finder timePicker = find.descendant(of: find.byType(TimePickerDialog), matching: find.byType(TextFormField));
    await tester.enterText(timePicker.first, dateTime.hour.toString());
    await tester.enterText(timePicker.last, dateTime.minute.toString());
    await tester.tap(find.text('OK'));
    await tester.pump();
  }

  Future<void> enterDateAndTime(WidgetTester tester, DateTime dateTime) async {
    await tester.tap(find.byKey(const Key('searchRideWholeDayCheckbox')));
    await tester.pump();
    await enterDate(tester, dateTime);
    await enterTime(tester, dateTime);
  }

  Future<void> enterSeats(WidgetTester tester, int seats) async {
    for (int i = 1; i < seats; i++) {
      await tester.tap(find.byKey(const Key('increment')));
      await tester.pump();
    }
  }

  Future<void> enterFilter(WidgetTester tester,
      {List<Feature>? features,
      int? rating,
      int? comfortRating,
      int? safetyRating,
      int? reliabilityRating,
      int? hospitalityRating}) async {
    await tester.tap(find.byKey(const Key('searchRideFilterButton')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('searchRideFilterResetToDefaultButton')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('searchRideRatingExpandButton')));
    await tester.pump();
    final Finder starFinder = find.byIcon(Icons.star);
    if (rating != null) {
      await tester
          .tap(find.descendant(of: find.byKey(const Key('searchRideRatingBar')), matching: starFinder).at(rating - 1));
    }
    if (comfortRating != null) {
      await tester.tap(find
          .descendant(of: find.byKey(const Key('searchRideComfortRatingBar')), matching: starFinder)
          .at(comfortRating - 1));
    }
    if (safetyRating != null) {
      await tester.tap(find
          .descendant(of: find.byKey(const Key('searchRideSafetyRatingBar')), matching: starFinder)
          .at(safetyRating - 1));
    }
    if (reliabilityRating != null) {
      await tester.tap(find
          .descendant(of: find.byKey(const Key('searchRideReliabilityRatingBar')), matching: starFinder)
          .at(reliabilityRating - 1));
    }
    if (hospitalityRating != null) {
      await tester.tap(find
          .descendant(of: find.byKey(const Key('searchRideHospitalityRatingBar')), matching: starFinder)
          .at(hospitalityRating - 1));
    }
    await tester.tap(find.byKey(const Key('searchRideRatingExpandButton')));
    await tester.pump();
    if (features != null) {
      await tester.tap(find.byKey(const Key('searchRideFeaturesExpandButton')));
      await tester.pump();
      final Finder scrollable = find.descendant(of: find.byType(Dialog), matching: find.byType(Scrollable));
      for (final Feature feature in features) {
        await tester.scrollUntilVisible(
          find.byKey(Key('searchRideFeatureChip${feature.name}')),
          100,
          scrollable: scrollable,
        );
        await tester.tap(find.byKey(Key('searchRideFeatureChip${feature.name}')));
      }
      await tester.tap(find.byKey(const Key('searchRideFeaturesExpandButton')));
      await tester.pump();
    }
    await tester.tap(find.byKey(const Key('searchRideFilterOkayButton')));
    await tester.pump();
  }

  Future<void> enterSorting(WidgetTester tester, SearchRideSorting sorting) async {
    await tester.tap(find.byKey(const Key('searchRideSortingDropdownButton')));
    await tester.pump();
    //Last because of https://stackoverflow.com/a/71305769/13763039
    await tester.tap(find.byKey(Key('searchRideSortingDropdownItem${sorting.name}')).last);
    await tester.pump();
  }

  group('SearchRidePage', () {
    group('Input', () {
      testWidgets('Enter start and destination', (WidgetTester tester) async {
        final String start = faker.address.city();
        final String destination = faker.address.city();

        whenRequest(processor).thenReturnJson([]);

        await pumpMaterial(tester, const SearchRidePage());
        await tester.pump();

        final SearchRidePageState pageState = tester.state(pageFinder);

        await enterStartAndDestination(tester, start, destination);

        expect(pageState.startController.text, start);
        expect(pageState.destinationController.text, destination);
      });

      group('Swap start and destination', () {
        testWidgets('Start and destination empty', (WidgetTester tester) async {
          await pumpMaterial(tester, const SearchRidePage());
          await tester.pump();

          final SearchRidePageState pageState = tester.state(pageFinder);

          await tester.tap(find.byKey(const Key('swapButton')));
          await tester.pump();

          expect(pageState.startController.text, '');
          expect(pageState.destinationController.text, '');
        });

        testWidgets('Start present', (WidgetTester tester) async {
          await pumpMaterial(tester, const SearchRidePage());
          await tester.pump();

          final SearchRidePageState pageState = tester.state(pageFinder);

          final String formerStart = faker.address.city();
          await enterStartAndDestination(tester, formerStart, null);
          await tester.tap(find.byKey(const Key('swapButton')));
          await tester.pump();

          expect(pageState.startController.text, '');
          expect(pageState.destinationController.text, formerStart);
        });

        testWidgets('Destination present', (WidgetTester tester) async {
          await pumpMaterial(tester, const SearchRidePage());
          await tester.pump();

          final SearchRidePageState pageState = tester.state(pageFinder);

          final String formerDestination = faker.address.city();
          await enterStartAndDestination(tester, null, formerDestination);
          await tester.tap(find.byKey(const Key('swapButton')));
          await tester.pump();

          expect(pageState.startController.text, formerDestination);
          expect(pageState.destinationController.text, '');
        });

        testWidgets('Start and destination present', (WidgetTester tester) async {
          await pumpMaterial(tester, const SearchRidePage());
          await tester.pump();

          whenRequest(processor).thenReturnJson([]);

          final SearchRidePageState pageState = tester.state(pageFinder);

          final String formerStart = faker.address.city();
          final String formerDestination = faker.address.city();
          await enterStartAndDestination(tester, formerStart, formerDestination);
          await tester.tap(find.byKey(const Key('swapButton')));
          await tester.pump();

          expect(pageState.startController.text, formerDestination);
          expect(pageState.destinationController.text, formerStart);
        });
      });

      group('Enter date', () {
        group('Whole day', () {
          testWidgets('Via arrows', (WidgetTester tester) async {
            final int dayDifference = faker.randomGenerator.integer(4);
            final DateTime dateTime = DateTime.now().add(Duration(days: dayDifference));

            await pumpMaterial(tester, const SearchRidePage());
            await tester.pump();

            final SearchRidePageState pageState = tester.state(pageFinder);

            for (int i = 0; i < dayDifference + 1; i++) {
              await tester.tap(find.byKey(const Key('searchRideAfterButton')));
              await tester.pump();
            }
            await tester.tap(find.byKey(const Key('searchRideBeforeButton')));
            await tester.pump();

            expect(pageState.selectedDate.year, dateTime.year);
            expect(pageState.selectedDate.month, dateTime.month);
            expect(pageState.selectedDate.day, dateTime.day);
          });

          testWidgets('Via DatePicker', (WidgetTester tester) async {
            final int dayDifference = faker.randomGenerator.integer(4);
            final DateTime dateTime = DateTime.now().add(Duration(days: dayDifference));

            await pumpMaterial(tester, const SearchRidePage());
            await tester.pump();

            final SearchRidePageState pageState = tester.state(pageFinder);

            await enterDate(tester, dateTime);

            expect(pageState.selectedDate.year, dateTime.year);
            expect(pageState.selectedDate.month, dateTime.month);
            expect(pageState.selectedDate.day, dateTime.day);
          });
        });

        group('Not whole day', () {
          testWidgets('Possible time', (WidgetTester tester) async {
            final DateTime dateTime = DateTime.now().add(Duration(
              days: random.integer(4),
              hours: random.integer(23),
              minutes: random.integer(59),
            ));

            await pumpMaterial(tester, const SearchRidePage());
            await tester.pump();

            final SearchRidePageState pageState = tester.state(pageFinder);

            await enterDateAndTime(tester, dateTime);

            expect(pageState.selectedDate.year, dateTime.year);
            expect(pageState.selectedDate.month, dateTime.month);
            expect(pageState.selectedDate.day, dateTime.day);
            expect(pageState.selectedDate.hour, dateTime.hour);
            expect(pageState.selectedDate.minute, dateTime.minute);
          });

          testWidgets('Impossible time', (WidgetTester tester) async {
            final DateTime dateTime = DateTime.now().subtract(const Duration(minutes: 11));
            if (dateTime.day != DateTime.now().day) {
              // Code is untestable from 00:00 to 00:11
              return;
            }

            await pumpMaterial(tester, const SearchRidePage());
            await tester.pump();

            await enterDateAndTime(tester, dateTime);

            final FormFieldState timeField = tester.state(find.byKey(const Key('searchRideTimePicker')));
            await tester.pump();

            expect(timeField.hasError, isTrue);
          });
        });
      });

      testWidgets('Enter seats', (WidgetTester tester) async {
        final int seats = faker.randomGenerator.integer(4) + 1;

        await pumpMaterial(tester, const SearchRidePage());
        await tester.pump();

        final SearchRidePageState pageState = tester.state(pageFinder);

        await enterSeats(tester, seats);

        expect(pageState.seats, seats);
      });
    });

    group('Search', () {
      testWidgets('Start and destination empty', (WidgetTester tester) async {
        await pumpMaterial(tester, const SearchRidePage());

        await tester.pump();

        expect(find.byType(RideCard, skipOffstage: false), findsNothing);
        expect(find.byKey(const Key('searchRideNoInput')), findsOneWidget);
      });

      testWidgets('Start empty', (WidgetTester tester) async {
        await pumpMaterial(tester, const SearchRidePage());

        final String destination = faker.address.city();
        await enterStartAndDestination(tester, null, destination);

        expect(find.byType(RideCard, skipOffstage: false), findsNothing);
        expect(find.byKey(const Key('searchRideNoInput')), findsOneWidget);
      });

      testWidgets('Destination empty', (WidgetTester tester) async {
        await pumpMaterial(tester, const SearchRidePage());

        final String start = faker.address.city();
        await enterStartAndDestination(tester, start, null);

        expect(find.byType(RideCard, skipOffstage: false), findsNothing);
        expect(find.byKey(const Key('searchRideNoInput')), findsOneWidget);
      });

      testWidgets('Normal input', (WidgetTester tester) async {
        final DateTime now = DateTime.now();
        final DateTime startTime = DateTime(now.year, now.month, now.day + 1);

        final List<Map<String, dynamic>> drives = [
          DriveFactory().generateFake(startTime: startTime).toJsonForApi(),
          DriveFactory().generateFake(startTime: startTime.add(const Duration(hours: 1))).toJsonForApi(),
          DriveFactory().generateFake(startTime: startTime.add(const Duration(days: 1))).toJsonForApi(),
        ];

        whenRequest(processor).thenReturnJson(drives);
        whenRequest(processor, urlMatcher: matches(RegExp('/rest/v1/drives.*id=eq.')))
            .thenReturnJson(DriveFactory().generateFake().toJsonForApi());

        await pumpMaterial(tester, const SearchRidePage());

        final String start = faker.address.city();
        await enterStartAndDestination(tester, start, faker.address.city());
        await enterDateAndTime(tester, startTime);

        verifyRequest(
          processor,
          urlMatcher: matches(RegExp('/rest/v1/drives.*start=eq\\.${RegExp.escape(Uri.encodeQueryComponent(start))}')),
        );

        expect(find.byType(RideCard, skipOffstage: false), findsNWidgets(2));

        await tester.tap(find.byKey(const Key('searchRideWholeDayCheckbox')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('searchRideAfterButton')));
        await tester.pump();

        expect(find.byType(RideCard, skipOffstage: false), findsOneWidget);

        await tester.tap(find.byKey(const Key('searchRideAfterButton')));
        await tester.pump();

        expect(find.byType(RideCard, skipOffstage: false), findsNothing);
      });

      testWidgets('No results', (WidgetTester tester) async {
        final List<Map<String, dynamic>> drives = [];

        whenRequest(processor).thenReturnJson(drives);

        await pumpMaterial(tester, const SearchRidePage());

        await enterStartAndDestination(tester, faker.address.city(), faker.address.city());

        expect(find.byType(RideCard, skipOffstage: false), findsNothing);
        expect(find.byKey(const Key('searchRideNoResults')), findsOneWidget);
      });

      testWidgets('Too restrictive filters', (WidgetTester tester) async {
        await tester.runAsync(() async {
          final DateTime startTime = DateTime.now();

          final Profile driver = ProfileFactory().generateFake(profileFeatures: []);
          final List<Map<String, dynamic>> drives = [
            DriveFactory().generateFake(driver: NullableParameter(driver), startTime: startTime).toJsonForApi(),
          ];

          whenRequest(processor).thenReturnJson(drives);
          whenRequest(processor, urlMatcher: matches(RegExp('/rest/v1/drives.*id=eq.')))
              .thenReturnJson(DriveFactory().generateFake().toJsonForApi());

          await pumpMaterial(tester, const SearchRidePage());

          await enterStartAndDestination(tester, faker.address.city(), faker.address.city());
          await enterFilter(tester, features: [Feature.values[random.integer(Feature.values.length)]]);

          expect(find.byType(RideCard, skipOffstage: false), findsNothing);

          await tester.tap(find.byKey(const Key('searchRideRelaxRestrictions')));
          await tester.pump();

          expect(find.byKey(const Key('searchRideFilterDialog')), findsOneWidget);
        });
      });

      testWidgets('Results at wrong times', (WidgetTester tester) async {
        final DateTime searchTime = DateTime.now();
        final DateTime rightTime = searchTime.add(const Duration(days: 2));
        final DateTime farAwayTime = searchTime.add(const Duration(days: 4));

        final List<Map<String, dynamic>> drives = [
          DriveFactory()
              .generateFake(startPosition: Position(0, 0), endPosition: Position(0, 0), startTime: farAwayTime)
              .toJsonForApi(),
          DriveFactory()
              .generateFake(startPosition: Position(0, 0), endPosition: Position(0, 0), startTime: rightTime)
              .toJsonForApi(),
        ];

        whenRequest(processor).thenReturnJson(drives);
        whenRequest(processor, urlMatcher: matches(RegExp('/rest/v1/drives.*id=eq.')))
            .thenReturnJson(DriveFactory().generateFake().toJsonForApi());

        await pumpMaterial(tester, const SearchRidePage());

        await enterStartAndDestination(tester, faker.address.city(), faker.address.city());
        await enterDateAndTime(tester, searchTime);

        expect(find.byType(RideCard, skipOffstage: false), findsNothing);

        expect(find.byKey(const Key('searchRideWrongTime')), findsOneWidget);

        await tester.tap(find.byKey(const Key('searchRideWrongTime')));
        await tester.pump();

        final SearchRidePageState pageState = tester.state(pageFinder);

        expect(pageState.selectedDate, rightTime);
        expect(find.byType(RideCard, skipOffstage: false), findsOneWidget);
      });
    });

    group('Filter', () {
      testWidgets('IndicatorRow', (WidgetTester tester) async {
        await pumpMaterial(tester, const SearchRidePage());

        final Finder indicatorRow = find.byKey(const Key('searchRideFilterButton'));

        expect(indicatorRow, findsOneWidget);

        await enterFilter(tester, rating: 3);
        expect(find.descendant(of: indicatorRow, matching: find.byIcon(Icons.star)), findsOneWidget);

        await enterFilter(tester, rating: 3, comfortRating: 3, hospitalityRating: 3);
        expect(find.descendant(of: indicatorRow, matching: find.byIcon(Icons.star)), findsNWidgets(3));
        expect(find.descendant(of: indicatorRow, matching: find.byIcon(Icons.chair)), findsOneWidget);
        expect(find.descendant(of: indicatorRow, matching: find.byIcon(Icons.favorite)), findsOneWidget);
        for (int i = 0; i < 2; i++) {
          expect(find.descendant(of: indicatorRow, matching: find.byKey(Key('ratingSizedBox$i'))), findsOneWidget);
        }
        expect(find.descendant(of: indicatorRow, matching: find.byKey(const Key('ratingSizedBox2'))), findsNothing);

        await enterFilter(tester, features: [Feature.accessible, Feature.childrenAllowed]);
        expect(find.descendant(of: indicatorRow, matching: find.byIcon(Icons.accessibility)), findsOneWidget);
        expect(find.descendant(of: indicatorRow, matching: find.byIcon(Icons.child_care)), findsOneWidget);

        await enterFilter(tester, hospitalityRating: 3, features: [Feature.accessible]);
        expect(find.descendant(of: indicatorRow, matching: find.byType(VerticalDivider)), findsOneWidget);
      });

      group('Features selection', () {
        void expectFeaturesVisible(WidgetTester tester, List<Feature> features) {
          expect(find.byType(FilterChip), findsNWidgets(features.length));
          for (final Feature feature in features) {
            expect(find.byKey(Key('searchRideFeatureChip${feature.name}')), findsOneWidget);
          }
        }

        testWidgets('Not expanded', (WidgetTester tester) async {
          await pumpMaterial(tester, const SearchRidePage());

          await tester.tap(find.byKey(const Key('searchRideFilterButton')));
          await tester.pump();

          expectFeaturesVisible(tester, SearchRideFilter.commonFeatures);

          await tester.tap(find.byKey(Key('searchRideFeatureChip${SearchRideFilter.commonFeatures[0].name}')));
          await tester.pump();

          expectFeaturesVisible(tester, SearchRideFilter.commonFeatures);
        });

        testWidgets('Expanded', (WidgetTester tester) async {
          await pumpMaterial(tester, const SearchRidePage());

          await tester.tap(find.byKey(const Key('searchRideFilterButton')));
          await tester.pump();

          await tester.tap(find.byKey(const Key('searchRideFeaturesExpandButton')));
          await tester.pump();

          expectFeaturesVisible(tester, Feature.values);

          await tester.tap(find.byKey(Key('searchRideFeatureChip${Feature.values[0].name}')));
          await tester.pump();

          expectFeaturesVisible(tester, Feature.values);
        });

        testWidgets('Expand, select a feature, retract, and deselect it', (WidgetTester tester) async {
          await pumpMaterial(tester, const SearchRidePage());

          await tester.tap(find.byKey(const Key('searchRideFilterButton')));
          await tester.pump();

          await tester.tap(find.byKey(const Key('searchRideFeaturesExpandButton')));
          await tester.pump();

          await tester.tap(find.byKey(Key('searchRideFeatureChip${Feature.values[0].name}')));
          await tester.pump();

          await tester.tap(find.byKey(const Key('searchRideFeaturesExpandButton')));
          await tester.pump();

          expectFeaturesVisible(tester, [Feature.values[0]]);

          await tester.tap(find.byKey(Key('searchRideFeatureChip${Feature.values[0].name}')));
          await tester.pump();

          expectFeaturesVisible(tester, [Feature.values[0]]);
        });

        testWidgets('Mutually exclusive', (WidgetTester tester) async {
          final List<Feature> shuffledFeatures = [...Feature.values]..shuffle();
          final Feature mutuallyExclusive1 = shuffledFeatures.firstWhere((Feature feature) =>
              Feature.values.firstWhereOrNull((Feature other) => feature.isMutuallyExclusive(other)) != null);
          final Feature mutuallyExclusive2 =
              shuffledFeatures.firstWhere((Feature feature) => feature.isMutuallyExclusive(mutuallyExclusive1));

          await pumpMaterial(tester, const SearchRidePage());

          await tester.tap(find.byKey(const Key('searchRideFilterButton')));
          await tester.pump();

          await tester.tap(find.byKey(const Key('searchRideFeaturesExpandButton')));
          await tester.pump();

          await tester.tap(find.byKey(Key('searchRideFeatureChip${mutuallyExclusive1.name}')));
          await tester.pump();
          await tester.tap(find.byKey(Key('searchRideFeatureChip${mutuallyExclusive2.name}')));
          await tester.pump();

          expect(find.byKey(const Key('searchRideFeatureMutuallyExclusiveSnackBar')), findsOneWidget);
        });
      });

      testWidgets('Filter rating and features', (WidgetTester tester) async {
        final DateTime startTime = DateTime.now();

        const int minRating = 3;
        final List<Feature> shuffledFeatures = [...Feature.values]..shuffle();
        final List<Feature> mutuallyExclusiveFiltered = [];
        for (final Feature feature in shuffledFeatures) {
          if (mutuallyExclusiveFiltered.firstWhereOrNull((Feature other) => feature.isMutuallyExclusive(other)) ==
              null) {
            mutuallyExclusiveFiltered.add(feature);
          }
        }
        final List<Feature> requiredFeatures =
            mutuallyExclusiveFiltered.sublist(random.integer(mutuallyExclusiveFiltered.length - 1));

        final List<Profile> drivers = [
          //Satisfies everything
          ProfileFactory().generateFake(
            reviewsReceived: [
              ReviewFactory().generateFake(
                rating: minRating,
                comfortRating: NullableParameter(minRating + 1),
                safetyRating: NullableParameter(minRating),
                reliabilityRating: NullableParameter(minRating),
                hospitalityRating: NullableParameter(minRating),
              ),
            ],
            profileFeatures: requiredFeatures
                .map((Feature feature) => ProfileFeatureFactory().generateFake(feature: feature))
                .toList(),
          ),
          //Not enough category rating
          ProfileFactory().generateFake(
            reviewsReceived: [
              ReviewFactory().generateFake(
                rating: minRating,
                comfortRating: NullableParameter(minRating - 1),
              ),
            ],
            profileFeatures: requiredFeatures
                .map((Feature feature) => ProfileFeatureFactory().generateFake(feature: feature))
                .toList(),
          ),
          //Not enough overall rating
          ProfileFactory().generateFake(
            reviewsReceived: [
              ReviewFactory().generateFake(
                rating: minRating - 1,
              ),
            ],
            profileFeatures: requiredFeatures
                .map((Feature feature) => ProfileFeatureFactory().generateFake(feature: feature))
                .toList(),
          ),
          //No ratings
          ProfileFactory().generateFake(
            reviewsReceived: [],
            profileFeatures: requiredFeatures
                .map((Feature feature) => ProfileFeatureFactory().generateFake(feature: feature))
                .toList(),
          ),
          //Not enough features
          ProfileFactory().generateFake(
            reviewsReceived: [
              ReviewFactory().generateFake(
                rating: minRating,
                comfortRating: NullableParameter(minRating),
                safetyRating: NullableParameter(minRating),
                reliabilityRating: NullableParameter(minRating),
                hospitalityRating: NullableParameter(minRating),
              ),
            ],
            profileFeatures: requiredFeatures
                .map((Feature feature) => ProfileFeatureFactory().generateFake(feature: feature))
                .toList()
                .sublist(1),
          ),
        ];

        //I am setting the duration and positions here because default Dart sort isn't stable and I want indices to work
        //TODO use duration instead of endTime
        final List<Drive> drives = drivers
            .map((Profile driver) => DriveFactory().generateFake(
                startTime: startTime,
                endTime: startTime.add(Duration(minutes: drivers.indexOf(driver))),
                startPosition: Position(0, 0),
                endPosition: Position(0, 0),
                driver: NullableParameter(driver)))
            .toList();
        final List<Map<String, dynamic>> driveJsons = drives.map((Drive drive) => drive.toJsonForApi()).toList();

        whenRequest(processor).thenReturnJson(driveJsons);
        for (final Drive drive in drives) {
          whenRequest(processor, urlMatcher: matches(RegExp('/rest/v1/drives.*id=eq.${drive.id}')))
              .thenReturnJson(drive.toJsonForApi());
        }

        await pumpMaterial(tester, const SearchRidePage());

        final SearchRidePageState pageState = tester.state(pageFinder);

        await enterStartAndDestination(tester, faker.address.city(), faker.address.city());

        //Only ratings, shows 3 drives: Satisfies everything, no ratings, not enough features
        await enterFilter(
          tester,
          rating: minRating,
          comfortRating: minRating,
          safetyRating: minRating,
          reliabilityRating: minRating,
          hospitalityRating: minRating,
        );

        List<Ride> filteredRides = pageState.filter.apply(pageState.rideSuggestions!, pageState.selectedDate);
        expect(filteredRides, hasLength(3));
        expect(filteredRides[0].driveId, drives[0].id);
        expect(filteredRides[1].driveId, drives[3].id);
        expect(filteredRides[2].driveId, drives[4].id);

        //Only filters, shows 4 drives: Satisfies everything, not enough category ratings, not enough overall rating, no ratings
        await enterFilter(tester, features: requiredFeatures);

        filteredRides = pageState.filter.apply(pageState.rideSuggestions!, pageState.selectedDate);
        expect(filteredRides, hasLength(4));
        expect(filteredRides[0].driveId, drives[0].id);
        expect(filteredRides[1].driveId, drives[1].id);
        expect(filteredRides[2].driveId, drives[2].id);
        expect(filteredRides[3].driveId, drives[3].id);

        //Ratings and features, shows 2 drives: Satisfies everything, no ratings
        await enterFilter(
          tester,
          rating: minRating,
          comfortRating: minRating,
          safetyRating: minRating,
          reliabilityRating: minRating,
          hospitalityRating: minRating,
          features: requiredFeatures,
        );

        filteredRides = pageState.filter.apply(pageState.rideSuggestions!, pageState.selectedDate);
        expect(filteredRides, hasLength(2));
        expect(filteredRides[0].driveId, drives[0].id);
        expect(filteredRides[1].driveId, drives[3].id);
      });

      group('Sort', () {
        double latDiffForKm(double km) => km / 110.574;

        testWidgets('Relevance (not whole day)', (WidgetTester tester) async {
          final DateTime startTime = DateTime.now();

          //TODO use duration here instead of endTime
          final List<Drive> drives = [
            //This is the base case, I will compare everything to this
            DriveFactory().generateFake(
                startTime: startTime.add(const Duration(hours: 1)),
                endTime: startTime.add(const Duration(hours: 2)),
                startPosition: Position(0, 0),
                endPosition: Position(latDiffForKm(10), 0)),
            //Time proximity and duration are weighted equally, so this is better by 9 minutes
            DriveFactory().generateFake(
                startTime: startTime.add(const Duration(minutes: 50)),
                endTime: startTime.add(const Duration(minutes: 111)),
                startPosition: Position(0, 0),
                endPosition: Position(latDiffForKm(10), 0)),
            //The price of this will be approx. 9.95€ because the price of rides is equal to the distance in km right now
            //Every cent is worth one minute of time proximity/duration, so this is better than the base by 5 minutes but worse than the previous by 4 minutes
            DriveFactory().generateFake(
                startTime: startTime.add(const Duration(hours: 1)),
                endTime: startTime.add(const Duration(hours: 2)),
                startPosition: Position(0, 0),
                endPosition: Position(latDiffForKm(9.95), 0)),
          ];

          final List<Map<String, dynamic>> driveJsons = drives.map((Drive drive) => drive.toJsonForApi()).toList();

          whenRequest(processor).thenReturnJson(driveJsons);
          for (final Drive drive in drives) {
            whenRequest(processor, urlMatcher: matches(RegExp('/rest/v1/drives.*id=eq.${drive.id}')))
                .thenReturnJson(drive.toJsonForApi());
          }

          await pumpMaterial(tester, const SearchRidePage());

          final SearchRidePageState pageState = tester.state(pageFinder);

          await enterStartAndDestination(tester, faker.address.city(), faker.address.city());
          await enterDateAndTime(tester, startTime);

          await enterSorting(tester, SearchRideSorting.relevance);

          final List<Ride> filteredRides = pageState.filter.apply(pageState.rideSuggestions!, pageState.selectedDate);
          expect(filteredRides, hasLength(3));
          expect(filteredRides[0].driveId, drives[1].id);
          expect(filteredRides[1].driveId, drives[2].id);
          expect(filteredRides[2].driveId, drives[0].id);
        });

        testWidgets('Relevance (whole day)', (WidgetTester tester) async {
          final DateTime startTime = DateTime.now();

          //TODO use duration here instead of endTime
          final List<Drive> drives = [
            //This is the base case, I will compare everything to this
            DriveFactory().generateFake(
                startTime: startTime.add(const Duration(hours: 1)),
                endTime: startTime.add(const Duration(hours: 2)),
                startPosition: Position(0, 0),
                endPosition: Position(latDiffForKm(10), 0)),
            //Time proximity is ignored in wholeDay, so this is worse because it's longer
            DriveFactory().generateFake(
                startTime: startTime.add(const Duration(minutes: 50)),
                endTime: startTime.add(const Duration(minutes: 111)),
                startPosition: Position(0, 0),
                endPosition: Position(latDiffForKm(10), 0)),
          ];
          final List<Map<String, dynamic>> driveJsons = drives.map((Drive drive) => drive.toJsonForApi()).toList();

          whenRequest(processor).thenReturnJson(driveJsons);
          for (final Drive drive in drives) {
            whenRequest(processor, urlMatcher: matches(RegExp('/rest/v1/drives.*id=eq.${drive.id}')))
                .thenReturnJson(drive.toJsonForApi());
          }

          await pumpMaterial(tester, const SearchRidePage());

          final SearchRidePageState pageState = tester.state(pageFinder);

          await enterStartAndDestination(tester, faker.address.city(), faker.address.city());
          await enterDate(tester, startTime);

          await enterSorting(tester, SearchRideSorting.relevance);

          final List<Ride> filteredRides = pageState.filter.apply(pageState.rideSuggestions!, pageState.selectedDate);
          expect(filteredRides, hasLength(2));
          expect(filteredRides[0].driveId, drives[0].id);
          expect(filteredRides[1].driveId, drives[1].id);
        });

        testWidgets('Travel Duration', (WidgetTester tester) async {
          final DateTime startTime = DateTime.now();

          final List<Drive> drives = [
            DriveFactory().generateFake(startTime: startTime, endTime: startTime.add(const Duration(hours: 2))),
            DriveFactory().generateFake(startTime: startTime, endTime: startTime.add(const Duration(hours: 3))),
            DriveFactory().generateFake(startTime: startTime, endTime: startTime.add(const Duration(hours: 1))),
          ];
          final List<Map<String, dynamic>> driveJsons = drives.map((Drive drive) => drive.toJsonForApi()).toList();

          whenRequest(processor).thenReturnJson(driveJsons);
          for (final Drive drive in drives) {
            whenRequest(processor, urlMatcher: matches(RegExp('/rest/v1/drives.*id=eq.${drive.id}')))
                .thenReturnJson(drive.toJsonForApi());
          }

          await pumpMaterial(tester, const SearchRidePage());

          final SearchRidePageState pageState = tester.state(pageFinder);

          await enterStartAndDestination(tester, faker.address.city(), faker.address.city());

          await enterSorting(tester, SearchRideSorting.travelDuration);

          final List<Ride> filteredRides = pageState.filter.apply(pageState.rideSuggestions!, pageState.selectedDate);
          expect(filteredRides, hasLength(3));
          expect(filteredRides[0].driveId, drives[2].id);
          expect(filteredRides[1].driveId, drives[0].id);
          expect(filteredRides[2].driveId, drives[1].id);
        });

        testWidgets('Price', (WidgetTester tester) async {
          final List<Drive> drives = [
            DriveFactory().generateFake(startPosition: Position(0, 0), endPosition: Position(latDiffForKm(10), 0)),
            DriveFactory().generateFake(startPosition: Position(0, 0), endPosition: Position(latDiffForKm(5), 0)),
            DriveFactory().generateFake(startPosition: Position(0, 0), endPosition: Position(latDiffForKm(8), 0)),
          ];
          final List<Map<String, dynamic>> driveJsons = drives.map((Drive drive) => drive.toJsonForApi()).toList();

          whenRequest(processor).thenReturnJson(driveJsons);
          for (final Drive drive in drives) {
            whenRequest(processor, urlMatcher: matches(RegExp('/rest/v1/drives.*id=eq.${drive.id}')))
                .thenReturnJson(drive.toJsonForApi());
          }

          await pumpMaterial(tester, const SearchRidePage());

          final SearchRidePageState pageState = tester.state(pageFinder);

          await enterStartAndDestination(tester, faker.address.city(), faker.address.city());

          await enterSorting(tester, SearchRideSorting.price);

          final List<Ride> filteredRides = pageState.filter.apply(pageState.rideSuggestions!, pageState.selectedDate);
          expect(filteredRides, hasLength(3));
          expect(filteredRides[0].driveId, drives[1].id);
          expect(filteredRides[1].driveId, drives[2].id);
          expect(filteredRides[2].driveId, drives[0].id);
        });

        testWidgets('Time proximity', (WidgetTester tester) async {
          final DateTime startTime = DateTime.now();

          final List<Drive> drives = [
            DriveFactory().generateFake(startTime: startTime.add(const Duration(hours: 3))),
            DriveFactory().generateFake(startTime: startTime.add(const Duration(hours: 2))),
            DriveFactory().generateFake(startTime: startTime.add(const Duration(hours: 1))),
          ];
          final List<Map<String, dynamic>> driveJsons = drives.map((Drive drive) => drive.toJsonForApi()).toList();

          whenRequest(processor).thenReturnJson(driveJsons);
          for (final Drive drive in drives) {
            whenRequest(processor, urlMatcher: matches(RegExp('/rest/v1/drives.*id=eq.${drive.id}')))
                .thenReturnJson(drive.toJsonForApi());
          }

          await pumpMaterial(tester, const SearchRidePage());

          final SearchRidePageState pageState = tester.state(pageFinder);

          await enterStartAndDestination(tester, faker.address.city(), faker.address.city());
          await enterDateAndTime(tester, startTime);

          await enterSorting(tester, SearchRideSorting.timeProximity);

          final List<Ride> filteredRides = pageState.filter.apply(pageState.rideSuggestions!, pageState.selectedDate);
          expect(filteredRides, hasLength(3));
          expect(filteredRides[0].driveId, drives[2].id);
          expect(filteredRides[1].driveId, drives[1].id);
          expect(filteredRides[2].driveId, drives[0].id);
        });

        testWidgets('Turning on wholeDay switches time proximity sorting off', (WidgetTester tester) async {
          await pumpMaterial(tester, const SearchRidePage());

          final SearchRidePageState pageState = tester.state(pageFinder);

          //wholeDay is on by default, so I'm turning it off here
          await tester.tap(find.byKey(const Key('searchRideWholeDayCheckbox')));
          await tester.pump();

          await enterSorting(tester, SearchRideSorting.timeProximity);

          expect(pageState.filter.sorting, SearchRideSorting.timeProximity);

          await tester.tap(find.byKey(const Key('searchRideWholeDayCheckbox')));
          await tester.pump();

          expect(pageState.filter.sorting, SearchRideSorting.relevance);
        });

        testWidgets('Time proximity disabled (whole day)', (WidgetTester tester) async {
          await pumpMaterial(tester, const SearchRidePage());

          await tester.tap(find.byKey(const Key('searchRideSortingDropdownButton')));
          await tester.pump();

          final DropdownMenuItem timeProximityItem = find
              .byKey(const Key('searchRideSortingDropdownItemtimeProximity'))
              .evaluate()
              .first
              .widget as DropdownMenuItem;
          expect(timeProximityItem.enabled, isFalse);
        });
      });
    });
  });
}
