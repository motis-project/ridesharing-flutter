import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/search/position.dart';
import 'package:motis_mitfahr_app/trips/models/trip.dart';

import '../../test_util/factories/trip_factory.dart';
import '../../test_util/mocks/mock_server.dart';
import '../../test_util/mocks/request_processor.mocks.dart';

void main() {
  final MockRequestProcessor tripProcessor = MockRequestProcessor();
  setUp(() async {
    MockServer.setProcessor(tripProcessor);
  });

  group('Trip.duration', () {
    test('duration of a trip', () {
      final DateTime now = DateTime.now();
      final Trip trip = TripFactory().generateFake(
        startDateTime: now,
        destinationDateTime: now.add(const Duration(hours: 2)),
      );
      expect(trip.duration, const Duration(hours: 2));
    });
  });
  group('Trip.isFinished', () {
    test('trip is finished', () {
      final Trip trip = TripFactory().generateFake(
        startDateTime: DateTime.now().subtract(const Duration(hours: 4)),
        destinationDateTime: DateTime.now().subtract(const Duration(hours: 2)),
      );
      expect(trip.isFinished, true);
    });
    test('trip is not finished', () {
      final Trip ride = TripFactory().generateFake(
        startDateTime: DateTime.now().add(const Duration(hours: 2)),
        destinationDateTime: DateTime.now().add(const Duration(hours: 4)),
      );
      expect(ride.isFinished, false);
    });
  });
  group('Trip.isOngoing', () {
    test('trip is on going', () {
      final Trip trip = TripFactory().generateFake(
        startDateTime: DateTime.now().subtract(const Duration(hours: 1)),
        destinationDateTime: DateTime.now().add(const Duration(hours: 2)),
      );
      expect(trip.isOngoing, true);
    });
    test('trip is in the past', () {
      final Trip trip = TripFactory().generateFake(
        startDateTime: DateTime.now().subtract(const Duration(hours: 6)),
        destinationDateTime: DateTime.now().subtract(const Duration(hours: 2)),
      );
      expect(trip.isOngoing, false);
    });
    test('trip is upcoming', () {
      final Trip trip = TripFactory().generateFake(
        startDateTime: DateTime.now().add(const Duration(hours: 2)),
        destinationDateTime: DateTime.now().add(const Duration(hours: 6)),
      );
      expect(trip.isOngoing, false);
    });
  });
  group('Trip.overlapsWith', () {
    test('trip is before other', () {
      final Trip trip1 = TripFactory().generateFake(
        startDateTime: DateTime.now().subtract(const Duration(hours: 6)),
        destinationDateTime: DateTime.now().subtract(const Duration(hours: 2)),
      );
      final Trip trip2 = TripFactory().generateFake(
        startDateTime: DateTime.now().add(const Duration(hours: 2)),
        destinationDateTime: DateTime.now().add(const Duration(hours: 6)),
      );
      expect(trip1.overlapsWith(trip2), false);
    });
    test('trip is after other', () {
      final Trip trip1 = TripFactory().generateFake(
        startDateTime: DateTime.now().add(const Duration(hours: 2)),
        destinationDateTime: DateTime.now().add(const Duration(hours: 6)),
      );
      final Trip trip2 = TripFactory().generateFake(
        startDateTime: DateTime.now().subtract(const Duration(hours: 6)),
        destinationDateTime: DateTime.now().subtract(const Duration(hours: 2)),
      );
      expect(trip1.overlapsWith(trip2), false);
    });
    test('trip overlaps the other', () {
      final Trip trip1 = TripFactory().generateFake(
        startDateTime: DateTime.now().subtract(const Duration(hours: 6)),
        destinationDateTime: DateTime.now().subtract(const Duration(hours: 2)),
      );
      final Trip trip2 = TripFactory().generateFake(
        startDateTime: DateTime.now().subtract(const Duration(hours: 3)),
        destinationDateTime: DateTime.now().add(const Duration(hours: 2)),
      );
      expect(trip1.overlapsWith(trip2), true);
    });
  });
  group('Trip.overlapsWithTimeRange', () {
    test('trip is after range', () {
      final DateTimeRange range = DateTimeRange(
        start: DateTime.now().subtract(const Duration(hours: 6)),
        end: DateTime.now().subtract(const Duration(hours: 3)),
      );
      final Trip trip = TripFactory().generateFake(
        startDateTime: DateTime.now().add(const Duration(hours: 2)),
        destinationDateTime: DateTime.now().add(const Duration(hours: 4)),
      );
      expect(trip.overlapsWithTimeRange(range), false);
    });
    test('trip is before range', () {
      final DateTimeRange range = DateTimeRange(
        start: DateTime.now().add(const Duration(hours: 3)),
        end: DateTime.now().add(const Duration(hours: 6)),
      );
      final Trip trip = TripFactory().generateFake(
        startDateTime: DateTime.now().subtract(const Duration(hours: 4)),
        destinationDateTime: DateTime.now().subtract(const Duration(hours: 2)),
      );
      expect(trip.overlapsWithTimeRange(range), false);
    });
    test('trip overlaps with range', () {
      final DateTimeRange range = DateTimeRange(
        start: DateTime.now().add(const Duration(hours: 3)),
        end: DateTime.now().add(const Duration(hours: 6)),
      );
      final Trip trip = TripFactory().generateFake(
        startDateTime: DateTime.now().add(const Duration(hours: 2)),
        destinationDateTime: DateTime.now().add(const Duration(hours: 4)),
      );
      expect(trip.overlapsWithTimeRange(range), true);
    });
  });
  group('Trip.shouldShowInListView', () {
    test('this trip should show in ListView when built', () {
      final Trip trip = TripFactory().generateFake(
        startDateTime: DateTime.now().add(const Duration(hours: 2)),
        destinationDateTime: DateTime.now().add(const Duration(hours: 4)),
      );
      expect(trip.shouldShowInListView(past: false), true);
    });
    test('this trip will not show in ListView when built because of hideInListView', () {
      final Trip trip = TripFactory().generateFake(
        startDateTime: DateTime.now().add(const Duration(hours: 2)),
        destinationDateTime: DateTime.now().add(const Duration(hours: 4)),
        hideInListView: true,
      );
      expect(trip.shouldShowInListView(past: false), false);
    });
    test('this trip will  show in past ListView when built', () {
      final Trip trip = TripFactory().generateFake(
        startDateTime: DateTime.now().subtract(const Duration(hours: 4)),
        destinationDateTime: DateTime.now().subtract(const Duration(hours: 2)),
      );
      expect(trip.shouldShowInListView(past: true), true);
    });
    test('this trip will not show in past ListView when built', () {
      final Trip trip = TripFactory().generateFake(
        startDateTime: DateTime.now().subtract(const Duration(hours: 4)),
        destinationDateTime: DateTime.now().subtract(const Duration(hours: 2)),
      );
      expect(trip.shouldShowInListView(past: false), false);
    });
  });
  group('Trip.equals', () {
    final DateTime now = DateTime.now();
    final Trip trip0 = TripFactory().generateFake(
      id: 1,
      createdAt: now,
      start: 'Berlin',
      startPosition: Position(1, 1),
      startDateTime: now.add(const Duration(hours: 1)),
      destination: 'Frankfurt',
      destinationPosition: Position(2, 2),
      destinationDateTime: now.add(const Duration(hours: 2)),
      seats: 1,
      createDependencies: false,
    );
    test('same trip', () {
      final Trip trip1 = TripFactory().generateFake(
        id: 1,
        createdAt: now,
        start: 'Berlin',
        startPosition: Position(1, 1),
        startDateTime: now.add(const Duration(hours: 1)),
        destination: 'Frankfurt',
        destinationPosition: Position(2, 2),
        destinationDateTime: now.add(const Duration(hours: 2)),
        seats: 1,
        createDependencies: false,
      );
      expect(trip0.equals(trip1), true);
    });

    test('different parameter', () {
      for (int i = 0; i < 10; i++) {
        final Trip trip1 = TripFactory().generateFake(
          id: i == 0 ? 2 : 1,
          createdAt: i == 1 ? now.add(const Duration(hours: 1)) : now,
          start: i == 2 ? 'Hamburg' : 'Berlin',
          startPosition: i == 3 ? Position(1, 2) : Position(1, 1),
          startDateTime: i == 4 ? now : now.add(const Duration(hours: 1)),
          destination: i == 5 ? 'Hamburg' : 'Frankfurt',
          destinationPosition: i == 6 ? Position(2, 3) : Position(2, 2),
          destinationDateTime: i == 7 ? now.add(const Duration(hours: 3)) : now.add(const Duration(hours: 2)),
          seats: i == 8 ? 3 : 1,
          hideInListView: i == 9,
          createDependencies: false,
        );
        expect(trip0.equals(trip1), false);
      }
    });
  });
}
