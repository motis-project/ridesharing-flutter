import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/rides/models/ride.dart';
import 'package:motis_mitfahr_app/util/trip/trip.dart';

import '../util/factories/drive_factory.dart';
import '../util/factories/ride_factory.dart';
import '../util/mock_server.dart';
import '../util/mock_server.mocks.dart';

void main() {
  final MockUrlProcessor tripProcessor = MockUrlProcessor();
  //setup muss in jeder Testklasse einmal aufgerufen werden
  setUp(() async {
    MockServer.setProcessor(tripProcessor);
  });
  group('Trip.duration', () {
    test('returns the duration of a ride', () {
      final DateTime now = DateTime.now();
      final Trip trip = RideFactory().generateFake(
          startTime: now,
          endTime: now.add(
            const Duration(hours: 2),
          ));
      expect(trip.duration, const Duration(hours: 2));
    });
    test('returns the duration of a drive', () {
      final DateTime now = DateTime.now();
      final Trip trip = DriveFactory().generateFake(
          startTime: now,
          endTime: now.add(
            const Duration(hours: 2),
          ));
      expect(trip.duration, const Duration(hours: 2));
    });
  });
  group('Trip.isFinished', () {
    test('returns true if the ride is before now', () {
      final Trip trip = RideFactory().generateFake(
          startTime: DateTime.now().subtract(const Duration(hours: 4)),
          endTime: DateTime.now().subtract(const Duration(hours: 2)));
      expect(trip.isFinished, true);
    });
    test('returns false if the ride is after now', () {
      final Trip trip = RideFactory().generateFake(
          startTime: DateTime.now().add(const Duration(hours: 2)),
          endTime: DateTime.now().add(const Duration(hours: 4)));
      expect(trip.isFinished, false);
    });
    test('returns true if the Drive is before now', () {
      final Trip trip = DriveFactory().generateFake(
          startTime: DateTime.now().subtract(const Duration(hours: 4)),
          endTime: DateTime.now().subtract(const Duration(hours: 2)));
      expect(trip.isFinished, true);
    });
    test('returns false if the Drive is after now', () {
      final Trip trip = DriveFactory().generateFake(
          startTime: DateTime.now().add(const Duration(hours: 2)),
          endTime: DateTime.now().add(const Duration(hours: 4)));
      expect(trip.isFinished, false);
    });
  });
  group('Ride.isOngoing', () {
    test('returns true if the Ride is started before now and is not done', () {
      final Trip trip = RideFactory().generateFake(
          startTime: DateTime.now().subtract(const Duration(hours: 1)),
          endTime: DateTime.now().add(const Duration(hours: 2)));
      expect(trip.isOngoing, true);
    });
    test('returns false if the Ride is in the past', () {
      final Trip trip = RideFactory().generateFake(
          startTime: DateTime.now().subtract(const Duration(hours: 6)),
          endTime: DateTime.now().subtract(const Duration(hours: 2)));
      expect(trip.isOngoing, false);
    });
    test('returns false if the Ride is upcoming', () {
      final Trip trip = RideFactory().generateFake(
          startTime: DateTime.now().add(const Duration(hours: 2)),
          endTime: DateTime.now().add(const Duration(hours: 6)));
      expect(trip.isOngoing, false);
    });
    test('returns true if the Drive started before now and is not done', () {
      final Trip trip = DriveFactory().generateFake(
          startTime: DateTime.now().subtract(const Duration(hours: 1)),
          endTime: DateTime.now().add(const Duration(hours: 2)));
      expect(trip.isOngoing, true);
    });
    test('returns false if the Drive is in the past', () {
      final Trip trip = DriveFactory().generateFake(
          startTime: DateTime.now().subtract(const Duration(hours: 6)),
          endTime: DateTime.now().subtract(const Duration(hours: 2)));
      expect(trip.isOngoing, false);
    });
    test('returns false if the Drive is upcoming', () {
      final Trip trip = DriveFactory().generateFake(
          startTime: DateTime.now().add(const Duration(hours: 2)),
          endTime: DateTime.now().add(const Duration(hours: 6)));
      expect(trip.isOngoing, false);
    });
  });
  group('Trip.overlapsWith', () {
    test('returns false if they are in seperated times', () {
      final Trip trip1 = RideFactory().generateFake(
          startTime: DateTime.now().subtract(const Duration(hours: 6)),
          endTime: DateTime.now().subtract(const Duration(hours: 2)));
      final Trip trip2 = RideFactory().generateFake(
          startTime: DateTime.now().add(const Duration(hours: 2)),
          endTime: DateTime.now().add(const Duration(hours: 6)));
      expect(trip1.overlapsWith(trip2), false);
    });
    test('returns true if they are overlapping', () {
      final Trip trip1 = DriveFactory().generateFake(
          startTime: DateTime.now().subtract(const Duration(hours: 6)),
          endTime: DateTime.now().subtract(const Duration(hours: 2)));
      final Trip trip2 = DriveFactory().generateFake(
          startTime: DateTime.now().subtract(const Duration(hours: 3)),
          endTime: DateTime.now().add(const Duration(hours: 2)));
      expect(trip1.overlapsWith(trip2), true);
    });
    test('can handel Rides as parameter', () {
      final Trip trip0 = DriveFactory().generateFake(
          startTime: DateTime.now().subtract(const Duration(hours: 6)),
          endTime: DateTime.now().subtract(const Duration(hours: 2)));
      final Trip trip1 = RideFactory().generateFake(
          startTime: DateTime.now().subtract(const Duration(hours: 3)),
          endTime: DateTime.now().add(const Duration(hours: 6)));
      expect(trip0.overlapsWith(trip1), true);
    });
    test('can handel Drive as parameter', () {
      final Trip trip0 = RideFactory().generateFake(
          startTime: DateTime.now().subtract(const Duration(hours: 6)),
          endTime: DateTime.now().subtract(const Duration(hours: 2)));
      final Trip trip1 = DriveFactory().generateFake(
          startTime: DateTime.now().subtract(const Duration(hours: 3)),
          endTime: DateTime.now().add(const Duration(hours: 6)));
      expect(trip0.overlapsWith(trip1), true);
    });
  });
  group('Trip.overlapswithRange', () {
    test('returns false if ride is not in range', () {
      final Trip trip = RideFactory().generateFake(
          startTime: DateTime.now().subtract(const Duration(hours: 4)),
          endTime: DateTime.now().subtract(const Duration(hours: 2)));
      expect(
          trip.overlapsWithTimeRange(DateTimeRange(
            start: DateTime.now().add(const Duration(hours: 3)),
            end: DateTime.now().add(const Duration(hours: 6)),
          )),
          false);
    });
    test('returns true if ride is in range', () {
      final Trip trip = RideFactory().generateFake(
          startTime: DateTime.now().add(const Duration(hours: 2)),
          endTime: DateTime.now().add(const Duration(hours: 4)));
      expect(
          trip.overlapsWithTimeRange(DateTimeRange(
            start: DateTime.now().add(const Duration(hours: 2)),
            end: DateTime.now().add(const Duration(hours: 6)),
          )),
          true);
    });
    test('returns false if drive is not in range', () {
      final Trip trip = DriveFactory().generateFake(
          startTime: DateTime.now().subtract(const Duration(hours: 4)),
          endTime: DateTime.now().subtract(const Duration(hours: 2)));
      expect(
          trip.overlapsWithTimeRange(DateTimeRange(
            start: DateTime.now().add(const Duration(hours: 3)),
            end: DateTime.now().add(const Duration(hours: 6)),
          )),
          false);
    });
    test('returns true drive it is in range', () {
      final Trip trip = DriveFactory().generateFake(
          startTime: DateTime.now().subtract(const Duration(hours: 4)),
          endTime: DateTime.now().subtract(const Duration(hours: 2)));
      expect(
          trip.overlapsWithTimeRange(DateTimeRange(
            start: DateTime.now().subtract(const Duration(hours: 3)),
            end: DateTime.now().add(const Duration(hours: 6)),
          )),
          true);
    });
  });
  group('Trip.shouldShowInListView', () {
    test('returns true if ride should show in ListView', () {
      final Trip trip = RideFactory().generateFake(
        status: RideStatus.approved,
        startTime: DateTime.now().add(const Duration(hours: 2)),
        endTime: DateTime.now().add(const Duration(hours: 4)),
      );
      expect(trip.shouldShowInListView(past: false), true);
    });
    test('returns false for ride with hideInListView', () {
      final Trip trip = RideFactory().generateFake(
        hideInListView: true,
        startTime: DateTime.now().add(const Duration(hours: 2)),
        endTime: DateTime.now().add(const Duration(hours: 4)),
      );
      expect(trip.shouldShowInListView(past: false), false);
    });
    test('returns true for past finsihed ride', () {
      final Trip trip = RideFactory().generateFake(
        status: RideStatus.approved,
        startTime: DateTime.now().subtract(const Duration(hours: 4)),
        endTime: DateTime.now().subtract(const Duration(hours: 2)),
      );
      expect(trip.shouldShowInListView(past: true), true);
    });
    test('returns false in ongoing ride', () {
      final Trip trip = RideFactory().generateFake(
        status: RideStatus.pending,
        startTime: DateTime.now().subtract(const Duration(hours: 2)),
        endTime: DateTime.now().add(const Duration(hours: 4)),
      );
      expect(trip.shouldShowInListView(past: true), false);
    });
    test('returns true if drive should show in ListView', () {
      final Trip trip = DriveFactory().generateFake(
        cancelled: false,
        startTime: DateTime.now().add(const Duration(hours: 2)),
        endTime: DateTime.now().add(const Duration(hours: 4)),
      );
      expect(trip.shouldShowInListView(past: false), true);
    });
    test('returns false for drive with hideInListView', () {
      final Trip trip = DriveFactory().generateFake(
        hideInListView: true,
        startTime: DateTime.now().add(const Duration(hours: 2)),
        endTime: DateTime.now().add(const Duration(hours: 4)),
      );
      expect(trip.shouldShowInListView(past: false), false);
    });
    test('returns true for past finished drive', () {
      final Trip trip = DriveFactory().generateFake(
        cancelled: false,
        startTime: DateTime.now().subtract(const Duration(hours: 4)),
        endTime: DateTime.now().subtract(const Duration(hours: 2)),
      );
      expect(trip.shouldShowInListView(past: true), true);
    });
    test('returns false in past for ongoing drive', () {
      final Trip trip = DriveFactory().generateFake(
        cancelled: true,
        startTime: DateTime.now().subtract(const Duration(hours: 2)),
        endTime: DateTime.now().add(const Duration(hours: 4)),
      );
      expect(trip.shouldShowInListView(past: true), false);
    });
  });
}
