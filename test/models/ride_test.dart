import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:motis_mitfahr_app/drives/models/drive.dart';
import 'package:motis_mitfahr_app/rides/models/ride.dart';
import 'package:motis_mitfahr_app/util/parse_helper.dart';
import 'package:motis_mitfahr_app/util/search/position.dart';

import '../util/factories/drive_factory.dart';
import '../util/factories/model_factory.dart';
import '../util/factories/profile_factory.dart';
import '../util/factories/ride_factory.dart';
import '../util/mock_server.dart';
import '../util/mock_server.mocks.dart';

void main() {
  final MockUrlProcessor rideProcessor = MockUrlProcessor();
  setUp(() async {
    MockServer.setProcessor(rideProcessor);
  });

  group('Ride.previewFromDrive', () {
    test('generates a Ride out of a Drive', () {
      final DateTime startTime = DateTime.now();
      final DateTime endTime = DateTime.now().add(const Duration(hours: 2));

      final Drive drive = DriveFactory().generateFake(id: 34);
      final Ride ride =
          Ride.previewFromDrive(drive, 'start', Position(1, 1), startTime, 'end', Position(3, 3), endTime, 2, 5, 6.5);
      expect(ride.start, 'start');
      expect(ride.startPosition, Position(1, 1));
      expect(ride.startTime, startTime);
      expect(ride.end, 'end');
      expect(ride.endPosition, Position(3, 3));
      expect(ride.endTime, endTime);
      expect(ride.seats, 2);
      expect(ride.riderId, 5);
      expect(ride.status, RideStatus.preview);
      expect(ride.driveId, drive.id);
      expect(ride.drive, drive);
      expect(ride.price, 6.5);
    });
  });
  group('Ride.fromJson', () {
    test('parses a drive from json with no driver and no rides', () {
      final Map<String, dynamic> json = {
        'id': 43,
        'created_at': '2021-01-01T00:00:00.000Z',
        'start': 'London',
        'start_lat': 2,
        'start_lng': 3,
        'start_time': '2022-01-01T00:00:00.000Z',
        'end': 'Berlin',
        'end_lat': 4.0,
        'end_lng': 3.0,
        'end_time': '2023-01-01T00:00:00.000Z',
        'seats': 2,
        'price': 3.5,
        'status': 3,
        'drive_id': 7,
        'rider_id': 4,
        'hide_in_list_view': false,
      };
      final Ride ride = Ride.fromJson(json);
      expect(ride.id, json['id']);
      expect(ride.createdAt, DateTime.parse(json['created_at']));
      expect(ride.start, json['start']);
      expect(ride.startPosition, Position.fromDynamicValues(json['start_lat'], json['start_lng']));
      expect(ride.startTime, DateTime.parse(json['start_time']));
      expect(ride.end, json['end']);
      expect(ride.endPosition, Position.fromDynamicValues(json['end_lat'], json['end_lng']));
      expect(ride.endTime, DateTime.parse(json['end_time']));
      expect(ride.seats, json['seats']);
      expect(ride.price, parseHelper.parseDouble(json['price']));
      expect(ride.status, RideStatus.values[json['status']]);
      expect(ride.riderId, json['rider_id']);
      expect(ride.driveId, json['drive_id']);
      expect(ride.drive, null);
      expect(ride.rider, null);
      expect(ride.hideInListView, json['hide_in_list_view']);
    });
    test('can handle associated models', () {
      RideFactory().generateFakeJsonList(length: 3);
      final Map<String, dynamic> json = {
        'id': 43,
        'created_at': '2021-01-01T00:00:00.000Z',
        'start': 'London',
        'start_lat': 2,
        'start_lng': 3,
        'start_time': '2022-01-01T00:00:00.000Z',
        'end': 'Berlin',
        'end_lat': 4.0,
        'end_lng': 3.0,
        'end_time': '2023-01-01T00:00:00.000Z',
        'seats': 2,
        'price': 3.5,
        'status': 3,
        'drive_id': 7,
        'rider_id': 4,
        'drive': DriveFactory().generateFake(id: 7).toJsonForApi(),
        'rider': ProfileFactory().generateFake(id: 4).toJsonForApi(),
        'hide_in_list_view': false,
      };
      final Ride ride = Ride.fromJson(json);
      expect(ride.id, json['id']);
      expect(ride.createdAt, DateTime.parse(json['created_at']));
      expect(ride.start, json['start']);
      expect(ride.startPosition, Position.fromDynamicValues(json['start_lat'], json['start_lng']));
      expect(ride.startTime, DateTime.parse(json['start_time']));
      expect(ride.end, json['end']);
      expect(ride.endPosition, Position.fromDynamicValues(json['end_lat'], json['end_lng']));
      expect(ride.endTime, DateTime.parse(json['end_time']));
      expect(ride.seats, json['seats']);
      expect(ride.price, parseHelper.parseDouble(json['price']));
      expect(ride.status, RideStatus.values[json['status']]);
      expect(ride.riderId, json['rider_id']);
      expect(ride.driveId, json['drive_id']);
      expect(ride.drive!.id, json['drive_id']);
      expect(ride.rider!.id, json['rider_id']);
      expect(ride.hideInListView, json['hide_in_list_view']);
    });
  });
  group('Ride.fromJsonList', () {
    test('parses a list of drives from json', () {
      final Map<String, dynamic> json = {
        'id': 43,
        'created_at': '2021-01-01T00:00:00.000Z',
        'start': 'London',
        'start_lat': 2,
        'start_lng': 3,
        'start_time': '2022-01-01T00:00:00.000Z',
        'end': 'Berlin',
        'end_lat': 4.0,
        'end_lng': 3.0,
        'end_time': '2023-01-01T00:00:00.000Z',
        'seats': 2,
        'price': 3.5,
        'status': 3,
        'drive_id': 7,
        'rider_id': 4,
        'hide_in_list_view': false,
      };
      final List<Map<String, dynamic>> jsonList = [json, json, json];
      final List<Ride> rides = Ride.fromJsonList(jsonList);
      expect(rides.length, 3);
      expect(rides.first.id, json['id']);
      expect(rides[1].start, json['start']);
      expect(rides.last.seats, 2);
    });
    test('can handle an empty list', () {
      final List<Ride> drives = Ride.fromJsonList([]);
      expect(drives, []);
    });
  });
  group('Ride.toJson', () {
    test('returns a json representation of the ride', () async {
      final Ride ride = RideFactory().generateFake();
      final Map<String, dynamic> json = ride.toJson();
      expect(json['start'], ride.start);
      expect(json['start_lat'], ride.startPosition.lat);
      expect(json['start_lng'], ride.startPosition.lng);
      expect(json['start_time'], ride.startTime.toString());
      expect(json['end'], ride.end);
      expect(json['end_lat'], ride.endPosition.lat);
      expect(json['end_lng'], ride.endPosition.lng);
      expect(json['end_time'], ride.endTime.toString());
      expect(json['status'], ride.status.index);
      expect(json['seats'], ride.seats);
      expect(json['price'], ride.price);
      expect(json['drive_id'], ride.driveId);
      expect(json['rider_id'], ride.riderId);
      expect(json['hide_in_list_view'], ride.hideInListView);
      expect(json.keys.length, 14);
    });
  });
  group('Ride.toJsonforApi', () {});
  group('Ride.userHasRideAtTimeRange', () {
    test('returns true when there is a approved not finished Ride at set time', () async {
      when.call(rideProcessor.processUrl(any)).thenReturn(jsonEncode([
            RideFactory()
                .generateFake(
                  riderId: 2,
                  status: RideStatus.approved,
                  startTime: DateTime.now().add(const Duration(hours: 2)),
                  endTime: DateTime.now().add(const Duration(hours: 4)),
                )
                .toJsonForApi()
          ]));
      expect(
          await Ride.userHasRideAtTimeRange(
              DateTimeRange(start: DateTime.now(), end: DateTime.now().add(const Duration(hours: 10))), 2),
          true);
    });
    test('returns false if there is no approved and not finished ride at the time range', () async {
      when.call(rideProcessor.processUrl(any)).thenReturn(jsonEncode([
            RideFactory()
                .generateFake(
                  riderId: 2,
                  status: RideStatus.pending,
                  startTime: DateTime.now().add(const Duration(hours: 8)),
                  endTime: DateTime.now().add(const Duration(hours: 10)),
                )
                .toJsonForApi(),
            RideFactory()
                .generateFake(
                  riderId: 2,
                  startTime: DateTime.now().add(const Duration(hours: 2)),
                  endTime: DateTime.now().add(const Duration(hours: 4)),
                )
                .toJsonForApi(),
            RideFactory()
                .generateFake(
                  riderId: 2,
                  startTime: DateTime.now().subtract(const Duration(hours: 4)),
                  endTime: DateTime.now().subtract(const Duration(hours: 2)),
                )
                .toJsonForApi(),
            RideFactory()
                .generateFake(
                  riderId: 2,
                  status: RideStatus.approved,
                  startTime: DateTime.now().add(const Duration(hours: 16)),
                  endTime: DateTime.now().add(const Duration(hours: 20)),
                )
                .toJsonForApi(),
            RideFactory()
                .generateFake(
                  riderId: 2,
                  startTime: DateTime.now().add(const Duration(hours: 12)),
                  endTime: DateTime.now().add(const Duration(hours: 15)),
                  status: RideStatus.cancelledByDriver,
                )
                .toJsonForApi(),
          ]));
      expect(
          await Ride.userHasRideAtTimeRange(
              DateTimeRange(
                start: DateTime.now().add(const Duration(hours: 4)),
                end: DateTime.now().add(const Duration(hours: 15)),
              ),
              2),
          false);
    });
  });
  group('Ride.shouldShowInListView', () {
    test('returns true if it should show in ListView', () {
      final Ride ride = RideFactory().generateFake(
        status: RideStatus.approved,
        startTime: DateTime.now().add(const Duration(hours: 2)),
        endTime: DateTime.now().add(const Duration(hours: 4)),
      );
      expect(ride.shouldShowInListView(past: false), true);
    });
    test('returns false because of hideInListView', () {
      final Ride ride = RideFactory().generateFake(
        hideInListView: true,
        startTime: DateTime.now().add(const Duration(hours: 2)),
        endTime: DateTime.now().add(const Duration(hours: 4)),
      );
      expect(ride.shouldShowInListView(past: false), false);
    });
    test('returns true past finished', () {
      final Ride ride = RideFactory().generateFake(
        status: RideStatus.approved,
        startTime: DateTime.now().subtract(const Duration(hours: 4)),
        endTime: DateTime.now().subtract(const Duration(hours: 2)),
      );
      expect(ride.shouldShowInListView(past: true), true);
    });
    test('returns false in past', () {
      final Ride ride = RideFactory().generateFake(
        status: RideStatus.pending,
        startTime: DateTime.now().subtract(const Duration(hours: 2)),
        endTime: DateTime.now().add(const Duration(hours: 4)),
      );
      expect(ride.shouldShowInListView(past: true), false);
    });
  });
  group('Ride.equals', () {
    test('retrurns true when the rides are the same', () async {
      final Ride ride = RideFactory().generateFake();
      expect(ride.equals(ride), true);
    });
    test('returns false when parameter is not a ride', () async {
      final Drive drive = DriveFactory().generateFake(createDependencies: false);
      final Ride ride = RideFactory().generateFake(createDependencies: false);
      expect(ride.equals(drive), false);
    });
    test('returns false when ride has not the same status', () async {
      final Ride ride0 = RideFactory().generateFake(
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
        driveId: 2,
        riderId: 3,
        status: RideStatus.approved,
        price: NullableParameter(6),
      );
      final Ride ride1 = RideFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        driveId: 2,
        riderId: 3,
        status: RideStatus.cancelledByDriver,
        price: NullableParameter(6),
        createDependencies: false,
      );
      expect(ride0.equals(ride1), false);
    });
    test('returns false when ride has not the same driveId', () async {
      final Ride ride0 = RideFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        driveId: 2,
        riderId: 3,
        status: RideStatus.approved,
        price: NullableParameter(6),
        createDependencies: false,
      );
      final Ride ride1 = RideFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        driveId: 4,
        riderId: 3,
        status: RideStatus.approved,
        price: NullableParameter(6),
        createDependencies: false,
      );
      expect(ride0.equals(ride1), false);
    });
    test('returns false when ride has not the same id', () async {
      final Ride ride0 = RideFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        driveId: 2,
        riderId: 3,
        status: RideStatus.approved,
        price: NullableParameter(6),
        createDependencies: false,
      );
      final Ride ride1 = RideFactory().generateFake(
        id: 2,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        driveId: 2,
        riderId: 3,
        status: RideStatus.approved,
        price: NullableParameter(6),
        createDependencies: false,
      );
      expect(ride0.equals(ride1), false);
    });
    test('returns false when ride has not the same createdAt', () async {
      final Ride ride0 = RideFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        driveId: 2,
        riderId: 3,
        status: RideStatus.approved,
        price: NullableParameter(6),
        createDependencies: false,
      );
      final Ride ride1 = RideFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 9),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        driveId: 2,
        riderId: 3,
        status: RideStatus.approved,
        price: NullableParameter(6),
        createDependencies: false,
      );
      expect(ride0.equals(ride1), false);
    });
    test('returns false when ride has not the same start', () async {
      final Ride ride0 = RideFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        driveId: 2,
        riderId: 3,
        status: RideStatus.approved,
        price: NullableParameter(6),
        createDependencies: false,
      );
      final Ride ride1 = RideFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: 'Hamburg',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        driveId: 2,
        riderId: 3,
        status: RideStatus.approved,
        price: NullableParameter(6),
        createDependencies: false,
      );
      expect(ride0.equals(ride1), false);
    });
    test('returns false when ride has not the same startPosition', () async {
      final Ride ride0 = RideFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        driveId: 2,
        riderId: 3,
        status: RideStatus.approved,
        price: NullableParameter(6),
        createDependencies: false,
      );
      final Ride ride1 = RideFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(2, 1),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        driveId: 2,
        riderId: 3,
        status: RideStatus.approved,
        price: NullableParameter(6),
        createDependencies: false,
      );
      expect(ride0.equals(ride1), false);
    });
    test('returns false when ride has not the same startTime', () async {
      final Ride ride0 = RideFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        driveId: 2,
        riderId: 3,
        status: RideStatus.approved,
        price: NullableParameter(6),
        createDependencies: false,
      );
      final Ride ride1 = RideFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 10),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        driveId: 2,
        riderId: 3,
        status: RideStatus.approved,
        price: NullableParameter(6),
        createDependencies: false,
      );
      expect(ride0.equals(ride1), false);
    });
    test('returns false when ride has not the same end', () async {
      final Ride ride0 = RideFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        driveId: 2,
        riderId: 3,
        status: RideStatus.approved,
        price: NullableParameter(6),
        createDependencies: false,
      );
      final Ride ride1 = RideFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Darmstadt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        driveId: 2,
        riderId: 3,
        status: RideStatus.approved,
        price: NullableParameter(6),
        createDependencies: false,
      );
      expect(ride0.equals(ride1), false);
    });
    test('returns false when ride has not the same endPosition', () async {
      final Ride ride0 = RideFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(2, 1),
        endTime: DateTime(2022, 12),
        seats: 1,
        driveId: 2,
        riderId: 3,
        status: RideStatus.approved,
        price: NullableParameter(6),
        createDependencies: false,
      );
      final Ride ride1 = RideFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        driveId: 2,
        riderId: 3,
        status: RideStatus.approved,
        price: NullableParameter(6),
        createDependencies: false,
      );
      expect(ride0.equals(ride1), false);
    });
    test('returns false when ride has not the same endTime', () async {
      final Ride ride0 = RideFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        driveId: 2,
        riderId: 3,
        status: RideStatus.approved,
        price: NullableParameter(6),
        createDependencies: false,
      );
      final Ride ride1 = RideFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 11),
        seats: 1,
        driveId: 2,
        riderId: 3,
        status: RideStatus.approved,
        price: NullableParameter(6),
        createDependencies: false,
      );
      expect(ride0.equals(ride1), false);
    });
    test('returns false when ride has not the same seats', () async {
      final Ride ride0 = RideFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        driveId: 2,
        riderId: 3,
        status: RideStatus.approved,
        price: NullableParameter(6),
        createDependencies: false,
      );
      final Ride ride1 = RideFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 2,
        driveId: 2,
        riderId: 3,
        status: RideStatus.approved,
        price: NullableParameter(6),
        createDependencies: false,
      );
      expect(ride0.equals(ride1), false);
    });
    test('returns false when ride has not the same hideInListView', () async {
      final Ride ride0 = RideFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        driveId: 2,
        riderId: 3,
        status: RideStatus.approved,
        price: NullableParameter(6),
        createDependencies: false,
      );
      final Ride ride1 = RideFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        driveId: 2,
        riderId: 3,
        status: RideStatus.approved,
        price: NullableParameter(6),
        createDependencies: false,
        hideInListView: true,
      );
      expect(ride0.equals(ride1), false);
    });
    test('returns false when ride has not the same price', () async {
      final Ride ride0 = RideFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        driveId: 2,
        riderId: 3,
        status: RideStatus.approved,
        price: NullableParameter(6),
        createDependencies: false,
      );
      final Ride ride1 = RideFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        driveId: 2,
        riderId: 3,
        status: RideStatus.approved,
        price: NullableParameter(7),
        createDependencies: false,
      );
      expect(ride0.equals(ride1), false);
    });
    test('returns false when ride has not the same riderId', () async {
      final Ride ride0 = RideFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        driveId: 2,
        riderId: 3,
        status: RideStatus.approved,
        price: NullableParameter(6),
        createDependencies: false,
      );
      final Ride ride1 = RideFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        driveId: 2,
        riderId: 4,
        status: RideStatus.approved,
        price: NullableParameter(6),
        createDependencies: false,
      );
      expect(ride0.equals(ride1), false);
    });
  });
  group('Ride.cancel', () {
    test('The Status is being changed to canncelledByRider', () async {
      final Ride ride = RideFactory().generateFake(status: RideStatus.approved, createDependencies: false);
      when.call(rideProcessor.processUrl(any)).thenReturn(ride.toString());
      ride.cancel();
      expect(ride.status, RideStatus.cancelledByRider);
    });
  });
  group('Ride.withdraw', () {
    test('Status is changed to withdrawnByRider', () async {
      final Ride ride = RideFactory().generateFake(status: RideStatus.pending, createDependencies: false);
      when.call(rideProcessor.processUrl(any)).thenReturn(ride.toString());
      ride.withdraw();
      expect(ride.status, RideStatus.withdrawnByRider);
    });
  });
  group('Ride.toString', () {
    test('returns a string representation of the ride', () async {
      final Ride ride = RideFactory().generateFake(
        id: 1,
        start: 'start',
        startTime: DateTime.parse('2022-02-02T00:00:00.000Z'),
        end: 'end',
        endTime: DateTime.parse('2023-03-03T00:00:00.000Z'),
        driveId: 7,
        riderId: 5,
        createDependencies: false,
      );
      expect(
        ride.toString(),
        'Ride{id: 1, in: 7, from: start at 2022-02-02 00:00:00.000Z, to: end at 2023-03-03 00:00:00.000Z, by: 5}',
      );
    });
  });
  group('Ride.duration', () {
    test('returns the duration of a drive', () {
      final Ride ride = RideFactory().generateFake(
          startTime: DateTime.now(),
          endTime: DateTime.now().add(
            const Duration(hours: 2),
          ));
      expect(ride.duration, const Duration(hours: 2));
    });
  });
  group('Ride.isFinished', () {
    test('returns true if the Ride is before now', () {
      final Ride ride = RideFactory().generateFake(
          startTime: DateTime.now().subtract(const Duration(hours: 4)),
          endTime: DateTime.now().subtract(const Duration(hours: 2)));
      expect(ride.isFinished, true);
    });
    test('returns false if the Ride is after now', () {
      final Ride ride = RideFactory().generateFake(
          startTime: DateTime.now().add(const Duration(hours: 2)),
          endTime: DateTime.now().add(const Duration(hours: 4)));
      expect(ride.isFinished, false);
    });
  });
  group('Ride.isOngoing', () {
    test('returns true if the Ride is started before now and is not done', () {
      final Ride ride = RideFactory().generateFake(
          startTime: DateTime.now().subtract(const Duration(hours: 1)),
          endTime: DateTime.now().add(const Duration(hours: 2)));
      expect(ride.isOngoing, true);
    });
    test('returns false if the Ride is in the past', () {
      final Ride ride = RideFactory().generateFake(
          startTime: DateTime.now().subtract(const Duration(hours: 6)),
          endTime: DateTime.now().subtract(const Duration(hours: 2)));
      expect(ride.isOngoing, false);
    });
    test('returns false if the Ride is upcoming', () {
      final Ride ride = RideFactory().generateFake(
          startTime: DateTime.now().add(const Duration(hours: 2)),
          endTime: DateTime.now().add(const Duration(hours: 6)));
      expect(ride.isOngoing, false);
    });
  });
  group('Ride.overlapsWith', () {
    test('returns false if they are in seperated times', () {
      final Ride ride1 = RideFactory().generateFake(
          startTime: DateTime.now().subtract(const Duration(hours: 6)),
          endTime: DateTime.now().subtract(const Duration(hours: 2)));
      final Ride ride2 = RideFactory().generateFake(
          startTime: DateTime.now().add(const Duration(hours: 2)),
          endTime: DateTime.now().add(const Duration(hours: 6)));
      expect(ride1.overlapsWith(ride2), false);
    });
    test('returns true if they are overlapping', () {
      final Ride ride1 = RideFactory().generateFake(
          startTime: DateTime.now().subtract(const Duration(hours: 6)),
          endTime: DateTime.now().subtract(const Duration(hours: 2)));
      final Ride ride2 = RideFactory().generateFake(
          startTime: DateTime.now().subtract(const Duration(hours: 3)),
          endTime: DateTime.now().add(const Duration(hours: 2)));
      expect(ride1.overlapsWith(ride2), true);
    });
    test('can handel Drive as parameter', () {
      final Ride ride = RideFactory().generateFake(
          startTime: DateTime.now().subtract(const Duration(hours: 6)),
          endTime: DateTime.now().subtract(const Duration(hours: 2)));
      final Drive drive = DriveFactory().generateFake(
          startTime: DateTime.now().subtract(const Duration(hours: 3)),
          endTime: DateTime.now().add(const Duration(hours: 6)));
      expect(ride.overlapsWith(drive), true);
    });
  });
  group('Ride.overlapsWithTimeRange', () {
    test('returns false if it is not in range', () {
      final Ride ride = RideFactory().generateFake(
          startTime: DateTime.now().subtract(const Duration(hours: 4)),
          endTime: DateTime.now().subtract(const Duration(hours: 2)));
      expect(
          ride.overlapsWithTimeRange(DateTimeRange(
            start: DateTime.now().add(const Duration(hours: 3)),
            end: DateTime.now().add(const Duration(hours: 6)),
          )),
          false);
    });
    test('returns true if it is in range', () {
      final Ride ride = RideFactory().generateFake(
          startTime: DateTime.now().add(const Duration(hours: 2)),
          endTime: DateTime.now().add(const Duration(hours: 4)));
      expect(
          ride.overlapsWithTimeRange(DateTimeRange(
            start: DateTime.now().add(const Duration(hours: 2)),
            end: DateTime.now().add(const Duration(hours: 6)),
          )),
          true);
    });
  });
  group('RideStatus.isCancelled', () {
    test('returns false if ride is not cancelled', () {
      final Ride ride = RideFactory().generateFake(status: RideStatus.approved);
      expect(ride.status.isCancelled(), false);
    });
    test('returns true if ride is cancelledByDriver', () {
      final Ride ride = RideFactory().generateFake(status: RideStatus.cancelledByDriver);
      expect(ride.status.isCancelled(), true);
    });
    test('returns true if ride is cancelledByRide', () {
      final Ride ride = RideFactory().generateFake(status: RideStatus.cancelledByRider);
      expect(ride.status.isCancelled(), true);
    });
  });
  group('RideStatus.isApproved', () {
    test('returns true if ride is approved', () {
      final Ride ride = RideFactory().generateFake(status: RideStatus.approved);
      expect(ride.status.isApproved(), true);
    });
    test('returns false if ride is not approved', () {
      final Ride ride = RideFactory().generateFake(status: RideStatus.pending);
      expect(ride.status.isApproved(), false);
    });
  });
}
