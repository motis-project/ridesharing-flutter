import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/rides/models/ride.dart';
import 'package:motis_mitfahr_app/util/search/position.dart';
import 'package:motis_mitfahr_app/util/trip/trip.dart';

import '../util/factories/drive_factory.dart';
import '../util/factories/ride_factory.dart';
import '../util/factories/trip_factory.dart';
import '../util/mock_server.dart';
import '../util/mock_server.mocks.dart';

void main() {
  final MockUrlProcessor tripProcessor = MockUrlProcessor();
  //setup muss in jeder Testklasse einmal aufgerufen werden
  setUp(() async {
    MockServer.setProcessor(tripProcessor);
  });

  Object randomTripFactory() {
    final Random random = Random();
    final int type = random.nextInt(2);
    return type == 0 ? RideFactory() : DriveFactory();
  }

  group('Trip.duration', () {
    test('duration of a trip', () {
      final DateTime now = DateTime.now();
      final Trip trip = (randomTripFactory() as TripFactory).generateFake(
          startTime: now,
          endTime: now.add(
            const Duration(hours: 2),
          ));
      expect(trip.duration, const Duration(hours: 2));
    });
  });
  group('Trip.isFinished', () {
    test('trip is finsihed', () {
      final Trip trip = (randomTripFactory() as TripFactory).generateFake(
          startTime: DateTime.now().subtract(const Duration(hours: 4)),
          endTime: DateTime.now().subtract(const Duration(hours: 2)));
      expect(trip.isFinished, true);
    });
    test('trip is not finished', () {
      final Trip ride = (randomTripFactory() as TripFactory).generateFake(
          startTime: DateTime.now().add(const Duration(hours: 2)),
          endTime: DateTime.now().add(const Duration(hours: 4)));
      expect(ride.isFinished, false);
    });
  });
  group('Trip.isOngoing', () {
    test('trip is on going', () {
      final Trip trip = (randomTripFactory() as TripFactory).generateFake(
          startTime: DateTime.now().subtract(const Duration(hours: 1)),
          endTime: DateTime.now().add(const Duration(hours: 2)));
      expect(trip.isOngoing, true);
    });
    test('trip is in the past', () {
      final Trip trip = (randomTripFactory() as TripFactory).generateFake(
          startTime: DateTime.now().subtract(const Duration(hours: 6)),
          endTime: DateTime.now().subtract(const Duration(hours: 2)));
      expect(trip.isOngoing, false);
    });
    test('trip is upcoming', () {
      final Trip trip = (randomTripFactory() as TripFactory).generateFake(
          startTime: DateTime.now().add(const Duration(hours: 2)),
          endTime: DateTime.now().add(const Duration(hours: 6)));
      expect(trip.isOngoing, false);
    });
  });
  group('Trip.overlapsWith', () {
    test('trip is before other', () {
      final Trip trip1 = (randomTripFactory() as TripFactory).generateFake(
          startTime: DateTime.now().subtract(const Duration(hours: 6)),
          endTime: DateTime.now().subtract(const Duration(hours: 2)));
      final Trip trip2 = (randomTripFactory() as TripFactory).generateFake(
          startTime: DateTime.now().add(const Duration(hours: 2)),
          endTime: DateTime.now().add(const Duration(hours: 6)));
      expect(trip1.overlapsWith(trip2), false);
    });
    test('trip overlaps the other', () {
      final Trip trip1 = (randomTripFactory() as TripFactory).generateFake(
          startTime: DateTime.now().subtract(const Duration(hours: 6)),
          endTime: DateTime.now().subtract(const Duration(hours: 2)));
      final Trip trip2 = (randomTripFactory() as TripFactory).generateFake(
          startTime: DateTime.now().subtract(const Duration(hours: 3)),
          endTime: DateTime.now().add(const Duration(hours: 2)));
      expect(trip1.overlapsWith(trip2), true);
    });
  });
  group('Trip.overlapswithRange', () {
    test('trip is after range', () {
      final DateTimeRange range = DateTimeRange(
        start: DateTime.now().subtract(const Duration(hours: 6)),
        end: DateTime.now().subtract(const Duration(hours: 3)),
      );
      final Trip trip = (randomTripFactory() as TripFactory).generateFake(
          startTime: DateTime.now().add(const Duration(hours: 4)),
          endTime: DateTime.now().add(const Duration(hours: 2)));
      expect(trip.overlapsWithTimeRange(range), false);
    });
    test('trip overlaps with range', () {
      final DateTimeRange range = DateTimeRange(
        start: DateTime.now().add(const Duration(hours: 3)),
        end: DateTime.now().add(const Duration(hours: 6)),
      );
      final Trip trip = (randomTripFactory() as TripFactory).generateFake(
          startTime: DateTime.now().add(const Duration(hours: 2)),
          endTime: DateTime.now().add(const Duration(hours: 4)));
      expect(trip.overlapsWithTimeRange(range), true);
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
  group('Trip.shouldShowInListView', () {
    test('shows in ListView', () {
      final Trip trip = (randomTripFactory() as TripFactory).generateFake(
        startTime: DateTime.now().add(const Duration(hours: 2)),
        endTime: DateTime.now().add(const Duration(hours: 4)),
      );
      expect(trip.shouldShowInListView(past: false), true);
    });
    test('hideInListView', () {
      final Trip trip = (randomTripFactory() as TripFactory).generateFake(
        startTime: DateTime.now().add(const Duration(hours: 2)),
        endTime: DateTime.now().add(const Duration(hours: 4)),
        hideInListView: true,
      );
      expect(trip.shouldShowInListView(past: false), false);
    });
    test('shows in past ListView', () {
      final Trip trip = (randomTripFactory() as TripFactory).generateFake(
        startTime: DateTime.now().subtract(const Duration(hours: 4)),
        endTime: DateTime.now().subtract(const Duration(hours: 2)),
      );
      expect(trip.shouldShowInListView(past: true), true);
    });
    test('not showing in ListView', () {
      final Trip trip = (randomTripFactory() as TripFactory).generateFake(
        startTime: DateTime.now().subtract(const Duration(hours: 4)),
        endTime: DateTime.now().subtract(const Duration(hours: 2)),
      );
      expect(trip.shouldShowInListView(past: false), false);
    });
  });
  group('Trip.equals', () {
    final Trip trip0 = (randomTripFactory() as TripFactory).generateFake(
      id: 1,
      createdAt: DateTime(2022, 10),
      start: 'Berlin',
      startPosition: Position(1, 1),
      startTime: DateTime(2022, 11),
      end: 'Frankfurt',
      endPosition: Position(2, 2),
      endTime: DateTime(2022, 12),
      seats: 1,
      createDependencies: false,
    );
    test('different id', () async {
      final Trip trip1 = (randomTripFactory() as TripFactory).generateFake(
        id: 2,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        createDependencies: false,
      );
      expect(trip0.equals(trip1), false);
    });
    test('different createdAt', () async {
      final Trip trip1 = (randomTripFactory() as TripFactory).generateFake(
        id: 1,
        createdAt: DateTime(2022, 9),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        createDependencies: false,
      );
      expect(trip0.equals(trip1), false);
    });
    test('different start', () async {
      final Trip trip1 = (randomTripFactory() as TripFactory).generateFake(
        id: 2,
        createdAt: DateTime(2022, 10),
        start: 'Hamburg',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        createDependencies: false,
      );
      expect(trip0.equals(trip1), false);
    });
    test('different startPosition', () async {
      final Trip trip1 = (randomTripFactory() as TripFactory).generateFake(
        id: 2,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 2),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        createDependencies: false,
      );
      expect(trip0.equals(trip1), false);
    });
    test('different startTime', () async {
      final Trip trip1 = (randomTripFactory() as TripFactory).generateFake(
        id: 2,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11, 30),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        createDependencies: false,
      );
      expect(trip0.equals(trip1), false);
    });
    test('different end', () async {
      final Trip trip1 = (randomTripFactory() as TripFactory).generateFake(
        id: 2,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Hamburg',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        createDependencies: false,
      );
      expect(trip0.equals(trip1), false);
    });
    test('different endPosition', () async {
      final Trip trip1 = (randomTripFactory() as TripFactory).generateFake(
        id: 2,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(1, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        createDependencies: false,
      );
      expect(trip0.equals(trip1), false);
    });
    test('different endTime', () async {
      final Trip trip1 = (randomTripFactory() as TripFactory).generateFake(
        id: 2,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12, 30),
        seats: 1,
        createDependencies: false,
      );
      expect(trip0.equals(trip1), false);
    });
    test('different seats', () async {
      final Trip trip1 = (randomTripFactory() as TripFactory).generateFake(
        id: 2,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 3,
        createDependencies: false,
      );
      expect(trip0.equals(trip1), false);
    });
    test('different hideInListView', () async {
      final Trip trip1 = (randomTripFactory() as TripFactory).generateFake(
        id: 2,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        hideInListView: true,
        createDependencies: false,
      );
      expect(trip0.equals(trip1), false);
    });
  });
}
