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
    test('can handel a Ride', () {
      final DateTime now = DateTime.now();
      final Trip trip = RideFactory().generateFake(
          startTime: now,
          endTime: now.add(
            const Duration(hours: 2),
          ));
      expect(trip.duration, const Duration(hours: 2));
    });
    test('can handel a Drive', () {
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
    test('returns true if the trip is before now', () {
      final Trip ride = RideFactory().generateFake(
          startTime: DateTime.now().subtract(const Duration(hours: 4)),
          endTime: DateTime.now().subtract(const Duration(hours: 2)));
      expect(ride.isFinished, true);
      final Trip drive = DriveFactory().generateFake(
          startTime: DateTime.now().subtract(const Duration(hours: 4)),
          endTime: DateTime.now().subtract(const Duration(hours: 2)));
      expect(drive.isFinished, true);
    });
    test('returns false if the trip is after now', () {
      final Trip ride = RideFactory().generateFake(
          startTime: DateTime.now().add(const Duration(hours: 2)),
          endTime: DateTime.now().add(const Duration(hours: 4)));
      expect(ride.isFinished, false);
      final Trip drive = DriveFactory().generateFake(
          startTime: DateTime.now().add(const Duration(hours: 2)),
          endTime: DateTime.now().add(const Duration(hours: 4)));
      expect(drive.isFinished, false);
    });
  });
  group('Trip.isOngoing', () {
    test('returns true if the Trip is started before now and is not done', () {
      final Trip ride = RideFactory().generateFake(
          startTime: DateTime.now().subtract(const Duration(hours: 1)),
          endTime: DateTime.now().add(const Duration(hours: 2)));
      expect(ride.isOngoing, true);
      final Trip drive = DriveFactory().generateFake(
          startTime: DateTime.now().subtract(const Duration(hours: 1)),
          endTime: DateTime.now().add(const Duration(hours: 2)));
      expect(drive.isOngoing, true);
    });
    test('returns false if the trip is in the past', () {
      final Trip ride = RideFactory().generateFake(
          startTime: DateTime.now().subtract(const Duration(hours: 6)),
          endTime: DateTime.now().subtract(const Duration(hours: 2)));
      expect(ride.isOngoing, false);
      final Trip drive = DriveFactory().generateFake(
          startTime: DateTime.now().subtract(const Duration(hours: 6)),
          endTime: DateTime.now().subtract(const Duration(hours: 2)));
      expect(drive.isOngoing, false);
    });
    test('returns false if the trip is upcoming', () {
      final Trip ride = RideFactory().generateFake(
          startTime: DateTime.now().add(const Duration(hours: 2)),
          endTime: DateTime.now().add(const Duration(hours: 6)));
      expect(ride.isOngoing, false);
      final Trip drive = DriveFactory().generateFake(
          startTime: DateTime.now().add(const Duration(hours: 2)),
          endTime: DateTime.now().add(const Duration(hours: 6)));
      expect(drive.isOngoing, false);
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
    test('returns false if trip is not in range', () {
      final Trip ride = RideFactory().generateFake(
          startTime: DateTime.now().subtract(const Duration(hours: 4)),
          endTime: DateTime.now().subtract(const Duration(hours: 2)));
      expect(
          ride.overlapsWithTimeRange(DateTimeRange(
            start: DateTime.now().add(const Duration(hours: 3)),
            end: DateTime.now().add(const Duration(hours: 6)),
          )),
          false);
      final Trip drive = DriveFactory().generateFake(
          startTime: DateTime.now().subtract(const Duration(hours: 4)),
          endTime: DateTime.now().subtract(const Duration(hours: 2)));
      expect(
          drive.overlapsWithTimeRange(DateTimeRange(
            start: DateTime.now().add(const Duration(hours: 3)),
            end: DateTime.now().add(const Duration(hours: 6)),
          )),
          false);
    });
    test('returns true if trip is in range', () {
      final Trip ride = RideFactory().generateFake(
          startTime: DateTime.now().add(const Duration(hours: 2)),
          endTime: DateTime.now().add(const Duration(hours: 4)));
      expect(
          ride.overlapsWithTimeRange(DateTimeRange(
            start: DateTime.now().add(const Duration(hours: 2)),
            end: DateTime.now().add(const Duration(hours: 6)),
          )),
          true);
      final Trip drive = DriveFactory().generateFake(
          startTime: DateTime.now().subtract(const Duration(hours: 4)),
          endTime: DateTime.now().subtract(const Duration(hours: 2)));
      expect(
          drive.overlapsWithTimeRange(DateTimeRange(
            start: DateTime.now().subtract(const Duration(hours: 3)),
            end: DateTime.now().add(const Duration(hours: 6)),
          )),
          true);
    });
  });
  group('Trip.shouldShowInListView', () {
    test('returns true if trip should show in ListView', () {
      final Trip ride = RideFactory().generateFake(
        status: RideStatus.approved,
        startTime: DateTime.now().add(const Duration(hours: 2)),
        endTime: DateTime.now().add(const Duration(hours: 4)),
      );
      expect(ride.shouldShowInListView(past: false), true);
      final Trip drive = DriveFactory().generateFake(
        cancelled: false,
        startTime: DateTime.now().add(const Duration(hours: 2)),
        endTime: DateTime.now().add(const Duration(hours: 4)),
      );
      expect(drive.shouldShowInListView(past: false), true);
    });
    test('returns false for trip with hideInListView', () {
      final Trip ride = RideFactory().generateFake(
        hideInListView: true,
        startTime: DateTime.now().add(const Duration(hours: 2)),
        endTime: DateTime.now().add(const Duration(hours: 4)),
      );
      expect(ride.shouldShowInListView(past: false), false);
      final Trip drive = DriveFactory().generateFake(
        hideInListView: true,
        startTime: DateTime.now().add(const Duration(hours: 2)),
        endTime: DateTime.now().add(const Duration(hours: 4)),
      );
      expect(drive.shouldShowInListView(past: false), false);
    });
    test('returns true for past finsihed trip', () {
      final Trip ride = RideFactory().generateFake(
        status: RideStatus.approved,
        startTime: DateTime.now().subtract(const Duration(hours: 4)),
        endTime: DateTime.now().subtract(const Duration(hours: 2)),
      );
      expect(ride.shouldShowInListView(past: true), true);
      final Trip drive = DriveFactory().generateFake(
        cancelled: false,
        startTime: DateTime.now().subtract(const Duration(hours: 4)),
        endTime: DateTime.now().subtract(const Duration(hours: 2)),
      );
      expect(drive.shouldShowInListView(past: true), true);
    });
    test('returns false in ongoing trip', () {
      final Trip ride = RideFactory().generateFake(
        status: RideStatus.pending,
        startTime: DateTime.now().subtract(const Duration(hours: 2)),
        endTime: DateTime.now().add(const Duration(hours: 4)),
      );
      expect(ride.shouldShowInListView(past: true), false);
      final Trip drive = DriveFactory().generateFake(
        cancelled: true,
        startTime: DateTime.now().subtract(const Duration(hours: 2)),
        endTime: DateTime.now().add(const Duration(hours: 4)),
      );
      expect(drive.shouldShowInListView(past: true), false);
    });
  });
}
