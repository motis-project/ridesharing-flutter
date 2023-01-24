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
      final Trip ride = RideFactory().generateFake(
          startTime: now,
          endTime: now.add(
            const Duration(hours: 2),
          ));
      expect(ride.duration, const Duration(hours: 2));
    });
    test('returns the duration of a drive', () {
      final DateTime now = DateTime.now();
      final Trip drive = DriveFactory().generateFake(
          startTime: now,
          endTime: now.add(
            const Duration(hours: 2),
          ));
      expect(drive.duration, const Duration(hours: 2));
    });
  });
  group('Trip.isFinished', () {
    test('returns true if the ride is before now', () {
      final Trip ride = RideFactory().generateFake(
          startTime: DateTime.now().subtract(const Duration(hours: 4)),
          endTime: DateTime.now().subtract(const Duration(hours: 2)));
      expect(ride.isFinished, true);
    });
    test('returns false if the ride is after now', () {
      final Trip ride = RideFactory().generateFake(
          startTime: DateTime.now().add(const Duration(hours: 2)),
          endTime: DateTime.now().add(const Duration(hours: 4)));
      expect(ride.isFinished, false);
    });
    test('returns true if the Drive is before now', () {
      final Trip drive = DriveFactory().generateFake(
          startTime: DateTime.now().subtract(const Duration(hours: 4)),
          endTime: DateTime.now().subtract(const Duration(hours: 2)));
      expect(drive.isFinished, true);
    });
    test('returns false if the Drive is after now', () {
      final Trip drive = DriveFactory().generateFake(
          startTime: DateTime.now().add(const Duration(hours: 2)),
          endTime: DateTime.now().add(const Duration(hours: 4)));
      expect(drive.isFinished, false);
    });
  });
  group('Ride.isOngoing', () {
    test('returns true if the Ride is started before now and is not done', () {
      final Trip ride = RideFactory().generateFake(
          startTime: DateTime.now().subtract(const Duration(hours: 1)),
          endTime: DateTime.now().add(const Duration(hours: 2)));
      expect(ride.isOngoing, true);
    });
    test('returns false if the Ride is in the past', () {
      final Trip ride = RideFactory().generateFake(
          startTime: DateTime.now().subtract(const Duration(hours: 6)),
          endTime: DateTime.now().subtract(const Duration(hours: 2)));
      expect(ride.isOngoing, false);
    });
    test('returns false if the Ride is upcoming', () {
      final Trip ride = RideFactory().generateFake(
          startTime: DateTime.now().add(const Duration(hours: 2)),
          endTime: DateTime.now().add(const Duration(hours: 6)));
      expect(ride.isOngoing, false);
    });
    test('returns true if the Drive started before now and is not done', () {
      final Trip drive = DriveFactory().generateFake(
          startTime: DateTime.now().subtract(const Duration(hours: 1)),
          endTime: DateTime.now().add(const Duration(hours: 2)));
      expect(drive.isOngoing, true);
    });
    test('returns false if the Drive is in the past', () {
      final Trip drive = DriveFactory().generateFake(
          startTime: DateTime.now().subtract(const Duration(hours: 6)),
          endTime: DateTime.now().subtract(const Duration(hours: 2)));
      expect(drive.isOngoing, false);
    });
    test('returns false if the Drive is upcoming', () {
      final Trip drive = DriveFactory().generateFake(
          startTime: DateTime.now().add(const Duration(hours: 2)),
          endTime: DateTime.now().add(const Duration(hours: 6)));
      expect(drive.isOngoing, false);
    });
  });
  group('Trip.overlapsWith', () {
    test('returns false if they are in seperated times', () {
      final Trip drive1 = RideFactory().generateFake(
          startTime: DateTime.now().subtract(const Duration(hours: 6)),
          endTime: DateTime.now().subtract(const Duration(hours: 2)));
      final Trip drive2 = RideFactory().generateFake(
          startTime: DateTime.now().add(const Duration(hours: 2)),
          endTime: DateTime.now().add(const Duration(hours: 6)));
      expect(drive1.overlapsWith(drive2), false);
    });
    test('returns true if they are overlapping', () {
      final Trip drive1 = DriveFactory().generateFake(
          startTime: DateTime.now().subtract(const Duration(hours: 6)),
          endTime: DateTime.now().subtract(const Duration(hours: 2)));
      final Trip drive2 = DriveFactory().generateFake(
          startTime: DateTime.now().subtract(const Duration(hours: 3)),
          endTime: DateTime.now().add(const Duration(hours: 2)));
      expect(drive1.overlapsWith(drive2), true);
    });
    test('can handel Rides as parameter', () {
      final Trip drive = DriveFactory().generateFake(
          startTime: DateTime.now().subtract(const Duration(hours: 6)),
          endTime: DateTime.now().subtract(const Duration(hours: 2)));
      final Trip ride = RideFactory().generateFake(
          startTime: DateTime.now().subtract(const Duration(hours: 3)),
          endTime: DateTime.now().add(const Duration(hours: 6)));
      expect(drive.overlapsWith(ride), true);
    });
    test('can handel Drive as parameter', () {
      final Trip ride = RideFactory().generateFake(
          startTime: DateTime.now().subtract(const Duration(hours: 6)),
          endTime: DateTime.now().subtract(const Duration(hours: 2)));
      final Trip drive = DriveFactory().generateFake(
          startTime: DateTime.now().subtract(const Duration(hours: 3)),
          endTime: DateTime.now().add(const Duration(hours: 6)));
      expect(ride.overlapsWith(drive), true);
    });
  });
  group('Trip.overlapswithRange', () {
    test('returns false if ride is not in range', () {
      final Trip ride = RideFactory().generateFake(
          startTime: DateTime.now().subtract(const Duration(hours: 4)),
          endTime: DateTime.now().subtract(const Duration(hours: 2)));
      expect(
          ride.overlapsWithTimeRange(DateTimeRange(
            start: DateTime.now().add(const Duration(hours: 3)),
            end: DateTime.now().add(const Duration(hours: 6)),
          )),
          false);
    });
    test('returns true if ride is in range', () {
      final Trip ride = RideFactory().generateFake(
          startTime: DateTime.now().add(const Duration(hours: 2)),
          endTime: DateTime.now().add(const Duration(hours: 4)));
      expect(
          ride.overlapsWithTimeRange(DateTimeRange(
            start: DateTime.now().add(const Duration(hours: 2)),
            end: DateTime.now().add(const Duration(hours: 6)),
          )),
          true);
    });
    test('returns false if drive is not in range', () {
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
    test('returns true drive it is in range', () {
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
    test('returns true if ride should show in ListView', () {
      final Trip ride = RideFactory().generateFake(
        status: RideStatus.approved,
        startTime: DateTime.now().add(const Duration(hours: 2)),
        endTime: DateTime.now().add(const Duration(hours: 4)),
      );
      expect(ride.shouldShowInListView(past: false), true);
    });
    test('returns false for ride with hideInListView', () {
      final Trip ride = RideFactory().generateFake(
        hideInListView: true,
        startTime: DateTime.now().add(const Duration(hours: 2)),
        endTime: DateTime.now().add(const Duration(hours: 4)),
      );
      expect(ride.shouldShowInListView(past: false), false);
    });
    test('returns true for past finsihed ride', () {
      final Trip ride = RideFactory().generateFake(
        status: RideStatus.approved,
        startTime: DateTime.now().subtract(const Duration(hours: 4)),
        endTime: DateTime.now().subtract(const Duration(hours: 2)),
      );
      expect(ride.shouldShowInListView(past: true), true);
    });
    test('returns false in ongoing ride', () {
      final Trip ride = RideFactory().generateFake(
        status: RideStatus.pending,
        startTime: DateTime.now().subtract(const Duration(hours: 2)),
        endTime: DateTime.now().add(const Duration(hours: 4)),
      );
      expect(ride.shouldShowInListView(past: true), false);
    });
    test('returns true if drive should show in ListView', () {
      final Trip drive = DriveFactory().generateFake(
        cancelled: false,
        startTime: DateTime.now().add(const Duration(hours: 2)),
        endTime: DateTime.now().add(const Duration(hours: 4)),
      );
      expect(drive.shouldShowInListView(past: false), true);
    });
    test('returns false for drive with hideInListView', () {
      final Trip drive = DriveFactory().generateFake(
        hideInListView: true,
        startTime: DateTime.now().add(const Duration(hours: 2)),
        endTime: DateTime.now().add(const Duration(hours: 4)),
      );
      expect(drive.shouldShowInListView(past: false), false);
    });
    test('returns true for past finished drive', () {
      final Trip drive = DriveFactory().generateFake(
        cancelled: false,
        startTime: DateTime.now().subtract(const Duration(hours: 4)),
        endTime: DateTime.now().subtract(const Duration(hours: 2)),
      );
      expect(drive.shouldShowInListView(past: true), true);
    });
    test('returns false in past for ongoing drive', () {
      final Trip drive = DriveFactory().generateFake(
        cancelled: true,
        startTime: DateTime.now().subtract(const Duration(hours: 2)),
        endTime: DateTime.now().add(const Duration(hours: 4)),
      );
      expect(drive.shouldShowInListView(past: true), false);
    });
  });
}
