import 'package:faker/faker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:motis_mitfahr_app/account/models/profile_feature.dart';
import 'package:motis_mitfahr_app/rides/pages/search_ride_page.dart';
import 'package:motis_mitfahr_app/rides/widgets/search_ride_filter.dart';
import 'package:motis_mitfahr_app/util/trip/ride_card.dart';

import '../util/mock_server.dart';
import '../util/pump_material.dart';
import '../util/request_processor.dart';
import '../util/request_processor.mocks.dart';

void main() {
  final MockRequestProcessor processor = MockRequestProcessor();

  setUpAll(() {
    MockServer.setProcessor(processor);
  });

  setUp(() {
    reset(processor);

    /*drive = DriveFactory().generateFake(
      start: 'Start',
      end: 'End',
      endTime: DateTime.now().add(const Duration(hours: 1)),
      rides: [RideFactory().generateFake(status: RideStatus.pending)],
    );
    whenRequest(processor).thenReturnJson(drive.toJsonForApi());*/
  });

  Future<void> enterStartAndDestination(WidgetTester tester, String start, String destination) async {
    final SearchRidePageState pageState = tester.state(find.byType(SearchRidePage));
    pageState.startController.text = start;
    pageState.destinationController.text = destination;
    await tester.pumpAndSettle();
  }

  Future<void> enterDateAndTime(WidgetTester tester, DateTime dateTime) async {
    tester.tap(find.byKey(const Key('searchRideDatePicker')));
    tester.tap(find.byIcon(Icons.edit));
    tester.enterText(find.byType(TextFormField), '${dateTime.month}/${dateTime.day}/${dateTime.year}');
    tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    tester.tap(find.byKey(const Key('searchRideTimePicker')));
    tester.tap(find.byIcon(Icons.keyboard));
    tester.enterText(find.byType(TextFormField).first, dateTime.hour.toString());
    tester.enterText(find.byType(TextFormField).last, dateTime.minute.toString());
    tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  Future<void> enterSeats(WidgetTester tester, int seats) async {
    for (int i = 1; i < seats; i++) {
      tester.tap(find.byKey(const Key('increment')));
    }
    await tester.pumpAndSettle();
  }

  Future<void> enterFilter(WidgetTester tester,
      {List<Feature>? features,
      int? rating,
      int? comfortRating,
      int? safetyRating,
      int? reliabilityRating,
      int? hospitalityRating}) async {
    tester.tap(find.byKey(const Key('searchRideFilterButton')));
    await tester.pumpAndSettle();
    tester.tap(find.byKey(const Key('searchRideRatingExtendButton')));
    await tester.pumpAndSettle();
    if (rating != null) {
      tester.tap(find
          .descendant(of: find.byKey(const Key('searchRideFilterRating')), matching: find.byIcon(Icons.star))
          .at(rating - 1));
    }
    if (comfortRating != null) {
      tester.tap(find
          .descendant(of: find.byKey(const Key('searchRideFilterComfortRating')), matching: find.byIcon(Icons.star))
          .at(comfortRating - 1));
    }
    if (safetyRating != null) {
      tester.tap(find
          .descendant(of: find.byKey(const Key('searchRideFilterSafetyRating')), matching: find.byIcon(Icons.star))
          .at(safetyRating - 1));
    }
    if (reliabilityRating != null) {
      tester.tap(find
          .descendant(of: find.byKey(const Key('searchRideFilterReliabilityRating')), matching: find.byIcon(Icons.star))
          .at(reliabilityRating - 1));
    }
    if (hospitalityRating != null) {
      tester.tap(find
          .descendant(of: find.byKey(const Key('searchRideFilterHospitalityRating')), matching: find.byIcon(Icons.star))
          .at(hospitalityRating - 1));
    }
    if (features != null) {
      tester.tap(find.byKey(const Key('searchRideFeaturesExpandButton')));
      await tester.pumpAndSettle();
      for (final Feature feature in features) {
        tester.tap(find.byKey(Key('searchRideFeatureChip${feature.name}')));
      }
    }
    tester.tap(find.byKey(const Key('searchRideFilterOkayButton')));
    await tester.pumpAndSettle();
  }

  Future<void> enterSorting(WidgetTester tester, SearchRideSorting sorting) async {
    tester.tap(find.byKey(const Key('searchRideSortingDropdownButton')));
    await tester.pumpAndSettle();
    tester.tap(find.byKey(Key('searchRideSortingDropdownItem${sorting.name}')));
    await tester.pumpAndSettle();
  }

  group('SearchRidePage', () {
    group('Swap start and destination', () {
      testWidgets('Start and destination empty', (WidgetTester tester) async {
        await pumpMaterial(tester, const SearchRidePage());
        await tester.pump();

        final SearchRidePageState pageState = tester.state(find.byType(SearchRidePage));

        await tester.tap(find.byKey(const Key('searchRideSwapButton')));
        await tester.pump();

        expect('', pageState.startController.text);
        expect('', pageState.destinationController.text);
      });

      testWidgets('Start present', (WidgetTester tester) async {
        await pumpMaterial(tester, const SearchRidePage());
        await tester.pump();

        final SearchRidePageState pageState = tester.state(find.byType(SearchRidePage));

        final String formerStart = faker.address.city();
        await enterStartAndDestination(tester, formerStart, '');
        await tester.tap(find.byKey(const Key('swapButton')));
        await tester.pump();

        expect('', pageState.startController.text);
        expect(formerStart, pageState.destinationController.text);
      });

      testWidgets('Destination present', (WidgetTester tester) async {
        await pumpMaterial(tester, const SearchRidePage());
        await tester.pump();

        final SearchRidePageState pageState = tester.state(find.byType(SearchRidePage));

        final String formerDestination = faker.address.city();
        await enterStartAndDestination(tester, '', formerDestination);
        await tester.tap(find.byKey(const Key('swapButton')));
        await tester.pump();

        expect(formerDestination, pageState.startController.text);
        expect('', pageState.destinationController.text);
      });

      testWidgets('Start and destination present', (WidgetTester tester) async {
        await pumpMaterial(tester, const SearchRidePage());
        await tester.pump();

        final SearchRidePageState pageState = tester.state(find.byType(SearchRidePage));

        final String formerStart = faker.address.city();
        final String formerDestination = faker.address.city();
        await enterStartAndDestination(tester, formerStart, formerDestination);
        await tester.tap(find.byKey(const Key('swapButton')));
        await tester.pump();

        expect(formerDestination, pageState.startController.text);
        expect(formerStart, pageState.destinationController.text);
      });
    });

    group('Search', () {
      testWidgets('Start and destination empty', (WidgetTester tester) async {
        await pumpMaterial(tester, const SearchRidePage());

        await tester.pump();

        expect(find.byType(RideCard), findsNothing);
      });

      testWidgets('Start empty', (WidgetTester tester) async {
        await pumpMaterial(tester, const SearchRidePage());

        final String destination = faker.address.city();
        await enterStartAndDestination(tester, '', destination);

        expect(find.byType(RideCard), findsNothing);
      });

      testWidgets('Destination empty', (WidgetTester tester) async {
        await pumpMaterial(tester, const SearchRidePage());

        final String start = faker.address.city();
        await enterStartAndDestination(tester, start, '');

        expect(find.byType(RideCard), findsNothing);
      });

      testWidgets('Start and destination present', (WidgetTester tester) async {
        whenRequest(processor).thenReturnJson('');

        await pumpMaterial(tester, const SearchRidePage());

        final String start = faker.address.city();
        final String destination = faker.address.city();
        await enterStartAndDestination(tester, start, destination);

        expect(find.byType(RideCard), findsNWidgets(2));
      });
    });
  });
}
