import 'package:faker/faker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:motis_mitfahr_app/account/models/profile_feature.dart';
import 'package:motis_mitfahr_app/rides/pages/search_ride_page.dart';
import 'package:motis_mitfahr_app/rides/widgets/search_ride_filter.dart';
import 'package:motis_mitfahr_app/util/search/start_destination_timeline.dart';
import 'package:motis_mitfahr_app/util/trip/ride_card.dart';
import 'package:motis_mitfahr_app/util/trip/trip.dart';

import '../util/factories/address_suggestion_factory.dart';
import '../util/factories/drive_factory.dart';
import '../util/mocks/mock_server.dart';
import '../util/mocks/request_processor.dart';
import '../util/mocks/request_processor.mocks.dart';
import '../util/pump_material.dart';

void main() {
  final MockRequestProcessor processor = MockRequestProcessor();

  setUpAll(() {
    MockServer.setProcessor(processor);
  });

  setUp(() {
    reset(processor);
  });

  Future<void> enterStartAndDestination(WidgetTester tester, String? start, String? destination) async {
    final SearchRidePageState pageState = tester.state(find.byType(SearchRidePage));
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
    }
    await tester.pump();
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
    await tester.tap(find.byKey(const Key('searchRideRatingExtendButton')));
    await tester.pump();
    if (rating != null) {
      await tester.tap(find
          .descendant(of: find.byKey(const Key('searchRideFilterRating')), matching: find.byIcon(Icons.star))
          .at(rating - 1));
    }
    if (comfortRating != null) {
      await tester.tap(find
          .descendant(of: find.byKey(const Key('searchRideFilterComfortRating')), matching: find.byIcon(Icons.star))
          .at(comfortRating - 1));
    }
    if (safetyRating != null) {
      await tester.tap(find
          .descendant(of: find.byKey(const Key('searchRideFilterSafetyRating')), matching: find.byIcon(Icons.star))
          .at(safetyRating - 1));
    }
    if (reliabilityRating != null) {
      await tester.tap(find
          .descendant(of: find.byKey(const Key('searchRideFilterReliabilityRating')), matching: find.byIcon(Icons.star))
          .at(reliabilityRating - 1));
    }
    if (hospitalityRating != null) {
      await tester.tap(find
          .descendant(of: find.byKey(const Key('searchRideFilterHospitalityRating')), matching: find.byIcon(Icons.star))
          .at(hospitalityRating - 1));
    }
    if (features != null) {
      await tester.tap(find.byKey(const Key('searchRideFeaturesExpandButton')));
      await tester.pump();
      for (final Feature feature in features) {
        await tester.scrollUntilVisible(find.byKey(Key('searchRideFeatureChip${feature.name}')), 100);
        await tester.tap(find.byKey(Key('searchRideFeatureChip${feature.name}')));
      }
    }
    await tester.tap(find.byKey(const Key('searchRideFilterOkayButton')));
    await tester.pump();
  }

  Future<void> enterSorting(WidgetTester tester, SearchRideSorting sorting) async {
    await tester.tap(find.byKey(const Key('searchRideSortingDropdownButton')));
    await tester.pump();
    await tester.tap(find.byKey(Key('searchRideSortingDropdownItem${sorting.name}')));
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

        final SearchRidePageState pageState = tester.state(find.byType(SearchRidePage));

        await enterStartAndDestination(tester, start, destination);

        expect(pageState.startController.text, start);
        expect(pageState.destinationController.text, destination);
      });

      group('Swap start and destination', () {
        testWidgets('Start and destination empty', (WidgetTester tester) async {
          await pumpMaterial(tester, const SearchRidePage());
          await tester.pump();

          final SearchRidePageState pageState = tester.state(find.byType(SearchRidePage));

          await tester.tap(find.byKey(const Key('swapButton')));
          await tester.pump();

          expect(pageState.startController.text, '');
          expect(pageState.destinationController.text, '');
        });

        testWidgets('Start present', (WidgetTester tester) async {
          await pumpMaterial(tester, const SearchRidePage());
          await tester.pump();

          final SearchRidePageState pageState = tester.state(find.byType(SearchRidePage));

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

          final SearchRidePageState pageState = tester.state(find.byType(SearchRidePage));

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

          final SearchRidePageState pageState = tester.state(find.byType(SearchRidePage));

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

            final SearchRidePageState pageState = tester.state(find.byType(SearchRidePage));

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

            final SearchRidePageState pageState = tester.state(find.byType(SearchRidePage));

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

            final SearchRidePageState pageState = tester.state(find.byType(SearchRidePage));

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

        final SearchRidePageState pageState = tester.state(find.byType(SearchRidePage));

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
        final String start = faker.address.city();
        final String destination = faker.address.city();
        final DateTime now = DateTime.now();
        final DateTime startTime = DateTime(now.year, now.month, now.day + 1);

        final int seats = faker.randomGenerator.integer(Trip.maxSelectableSeats - 1) + 1;

        final List<Map<String, dynamic>> drives = [
          DriveFactory().generateFake(start: start, startTime: startTime, seats: seats).toJsonForApi(),
          DriveFactory()
              .generateFake(start: start, startTime: startTime.add(const Duration(hours: 1)), seats: seats + 1)
              .toJsonForApi(),
          DriveFactory()
              .generateFake(start: start, startTime: startTime.add(const Duration(days: 1)), seats: seats)
              .toJsonForApi(),
        ];
        whenRequest(processor).thenReturnJson(drives);
        whenRequest(processor, urlMatcher: matches(RegExp('/rest/v1/drives.*id=eq.')))
            .thenReturnJson(DriveFactory().generateFake().toJsonForApi());

        await pumpMaterial(tester, const SearchRidePage());

        await enterStartAndDestination(tester, start, destination);
        await enterDateAndTime(tester, startTime);
        await enterSeats(tester, seats);

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
        final String start = faker.address.city();
        final String destination = faker.address.city();
        final DateTime startTime = DateTime.now();
        final int seats = faker.randomGenerator.integer(Trip.maxSelectableSeats - 1) + 1;

        final List<Map<String, dynamic>> drives = [];
        whenRequest(processor).thenReturnJson(drives);

        await pumpMaterial(tester, const SearchRidePage());

        await enterStartAndDestination(tester, start, destination);
        await enterDateAndTime(tester, startTime);
        await enterSeats(tester, seats);

        expect(find.byType(RideCard, skipOffstage: false), findsNothing);
        expect(find.byKey(const Key('searchRideNoResults')), findsOneWidget);
      });

      testWidgets('No results', (WidgetTester tester) async {
        final String start = faker.address.city();
        final String destination = faker.address.city();
        final DateTime startTime = DateTime.now();
        final int seats = faker.randomGenerator.integer(Trip.maxSelectableSeats - 1) + 1;

        final List<Map<String, dynamic>> drives = [];
        whenRequest(processor).thenReturnJson(drives);

        await pumpMaterial(tester, const SearchRidePage());

        await enterStartAndDestination(tester, start, destination);
        await enterDateAndTime(tester, startTime);
        await enterSeats(tester, seats);

        expect(find.byType(RideCard, skipOffstage: false), findsNothing);
        expect(find.byKey(const Key('searchRideNoResults')), findsOneWidget);
      });

      testWidgets('Results at wrong times', (WidgetTester tester) async {
        final String start = faker.address.city();
        final String destination = faker.address.city();
        final DateTime searchTime = DateTime.now();
        final DateTime rightTime = searchTime.add(const Duration(days: 2));
        final DateTime farAwayTime = searchTime.add(const Duration(days: 4));
        final int seats = faker.randomGenerator.integer(Trip.maxSelectableSeats - 1) + 1;

        final List<Map<String, dynamic>> drives = [
          DriveFactory().generateFake(start: start, startTime: farAwayTime, seats: seats).toJsonForApi(),
          DriveFactory().generateFake(start: start, startTime: rightTime, seats: seats).toJsonForApi(),
        ];
        whenRequest(processor).thenReturnJson(drives);
        whenRequest(processor, urlMatcher: matches(RegExp('/rest/v1/drives.*id=eq.')))
            .thenReturnJson(DriveFactory().generateFake().toJsonForApi());

        await pumpMaterial(tester, const SearchRidePage());

        await enterStartAndDestination(tester, start, destination);
        await enterDateAndTime(tester, searchTime);
        await enterSeats(tester, seats);

        expect(find.byType(RideCard, skipOffstage: false), findsNothing);

        await tester.tap(find.byKey(const Key('searchRideWrongTime')));
        await tester.pump();

        final SearchRidePageState pageState = tester.state(find.byType(SearchRidePage));

        expect(pageState.selectedDate, rightTime);
        expect(find.byType(RideCard, skipOffstage: false), findsOneWidget);
      });
    });
  });
}
