import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/search/position.dart';
import 'package:motis_mitfahr_app/trips/models/drive.dart';
import 'package:motis_mitfahr_app/trips/models/ride.dart';
import 'package:motis_mitfahr_app/util/parse_helper.dart';

import '../../test_util/factories/chat_factory.dart';
import '../../test_util/factories/drive_factory.dart';
import '../../test_util/factories/model_factory.dart';
import '../../test_util/factories/profile_factory.dart';
import '../../test_util/factories/ride_factory.dart';
import '../../test_util/mocks/mock_server.dart';
import '../../test_util/mocks/request_processor.dart';
import '../../test_util/mocks/request_processor.mocks.dart';

void main() {
  final MockRequestProcessor rideProcessor = MockRequestProcessor();
  setUp(() async {
    MockServer.setProcessor(rideProcessor);
  });

  group('Ride.previewFromDrive', () {
    test('generates a ride out of a drive', () {
      final Drive drive = DriveFactory().generateFake(
        id: 34,
        startPosition: Position(48.8566, 2.3522),
        destinationPosition: Position(50.0755, 14.4378),
      );
      final Ride ride = Ride.previewFromDrive(
        drive,
        start: 'start',
        startPosition: Position(1, 1),
        destination: 'destination',
        destinationPosition: Position(3, 3),
        seats: 2,
        riderId: 5,
      );
      expect(ride.start, 'start');
      expect(ride.startPosition, Position(1, 1));
      expect(ride.startDateTime, drive.startDateTime);
      expect(ride.destination, 'destination');
      expect(ride.destinationPosition, Position(3, 3));
      expect(ride.destinationDateTime, drive.destinationDateTime);
      expect(ride.seats, 2);
      expect(ride.riderId, 5);
      expect(ride.status, RideStatus.preview);
      expect(ride.driveId, drive.id);
      expect(ride.drive, drive);
      expect(ride.price, 882.82);
    });
  });
  group('Ride.fromJson', () {
    test('parses a drive from json with no driver and no rides', () {
      final Map<String, dynamic> json = {
        'id': 43,
        'created_at': '2021-01-01T00:00:00.000',
        'start': 'London',
        'start_lat': 2,
        'start_lng': 3,
        'start_date_time': '2022-01-01T00:00:00.000',
        'destination': 'Berlin',
        'destination_lat': 4.0,
        'destination_lng': 3.0,
        'destination_date_time': '2023-01-01T00:00:00.000',
        'seats': 2,
        'price': 3.5,
        'status': 3,
        'drive_id': 7,
        'rider_id': 4,
        'chat_id': 5,
        'hide_in_list_view': false,
      };
      final Ride ride = Ride.fromJson(json);
      expect(ride.id, json['id']);
      expect(ride.createdAt, DateTime.parse(json['created_at']));
      expect(ride.start, json['start']);
      expect(ride.startPosition, Position.fromDynamicValues(json['start_lat'], json['start_lng']));
      expect(ride.startDateTime, DateTime.parse(json['start_date_time']));
      expect(ride.destination, json['destination']);
      expect(ride.destinationPosition, Position.fromDynamicValues(json['destination_lat'], json['destination_lng']));
      expect(ride.destinationDateTime, DateTime.parse(json['destination_date_time']));
      expect(ride.seats, json['seats']);
      expect(ride.price, parseHelper.parseDouble(json['price']));
      expect(ride.status, RideStatus.values[json['status']]);
      expect(ride.riderId, json['rider_id']);
      expect(ride.driveId, json['drive_id']);
      expect(ride.chatId, json['chat_id']);
      expect(ride.rider, null);
      expect(ride.drive, null);
      expect(ride.chat, null);
      expect(ride.hideInListView, json['hide_in_list_view']);
    });
    test('associated models', () {
      RideFactory().generateFakeJsonList(length: 3);
      final Map<String, dynamic> json = {
        'id': 43,
        'created_at': '2021-01-01T00:00:00.000',
        'start': 'London',
        'start_lat': 2,
        'start_lng': 3,
        'start_date_time': '2022-01-01T00:00:00.000',
        'destination': 'Berlin',
        'destination_lat': 4.0,
        'destination_lng': 3.0,
        'destination_date_time': '2023-01-01T00:00:00.000',
        'seats': 2,
        'price': 3.5,
        'status': 3,
        'drive_id': 7,
        'rider_id': 4,
        'chat_id': 5,
        'drive': DriveFactory().generateFake(id: 7).toJsonForApi(),
        'rider': ProfileFactory().generateFake(id: 4).toJsonForApi(),
        'chat': ChatFactory().generateFake(id: 5).toJsonForApi(),
        'hide_in_list_view': false,
      };
      final Ride ride = Ride.fromJson(json);
      expect(ride.id, json['id']);
      expect(ride.createdAt, DateTime.parse(json['created_at']));
      expect(ride.start, json['start']);
      expect(ride.startPosition, Position.fromDynamicValues(json['start_lat'], json['start_lng']));
      expect(ride.startDateTime, DateTime.parse(json['start_date_time']));
      expect(ride.destination, json['destination']);
      expect(ride.destinationPosition, Position.fromDynamicValues(json['destination_lat'], json['destination_lng']));
      expect(ride.destinationDateTime, DateTime.parse(json['destination_date_time']));
      expect(ride.seats, json['seats']);
      expect(ride.price, parseHelper.parseDouble(json['price']));
      expect(ride.status, RideStatus.values[json['status']]);
      expect(ride.hideInListView, json['hide_in_list_view']);
      expect(ride.riderId, json['rider_id']);
      expect(ride.rider!.id, json['rider_id']);
      expect(ride.driveId, json['drive_id']);
      expect(ride.drive!.id, json['drive_id']);
      expect(ride.chatId, json['chat_id']);
      expect(ride.chat!.id, json['chat_id']);
    });
  });
  group('Ride.fromJsonList', () {
    test('parses a list of drives from json', () {
      final Map<String, dynamic> json = {
        'id': 43,
        'created_at': '2021-01-01T00:00:00.000',
        'start': 'London',
        'start_lat': 2,
        'start_lng': 3,
        'start_date_time': '2022-01-01T00:00:00.000',
        'destination': 'Berlin',
        'destination_lat': 4.0,
        'destination_lng': 3.0,
        'destination_date_time': '2023-01-01T00:00:00.000',
        'seats': 2,
        'price': 3.5,
        'hide_in_list_view': false,
        'status': 3,
        'drive_id': 7,
        'rider_id': 4,
        'chat_id': 5,
      };
      final List<Map<String, dynamic>> jsonList = [json, json, json];
      final List<Ride> rides = Ride.fromJsonList(jsonList);
      expect(rides.length, 3);
      expect(rides.first.id, json['id']);
      expect(rides[1].start, json['start']);
      expect(rides.last.seats, 2);
    });
    test('empty list', () {
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
      expect(json['start_date_time'], ride.startDateTime.toUtc().toString());
      expect(json['destination'], ride.destination);
      expect(json['destination_lat'], ride.destinationPosition.lat);
      expect(json['destination_lng'], ride.destinationPosition.lng);
      expect(json['destination_date_time'], ride.destinationDateTime.toUtc().toString());
      expect(json['status'], ride.status.index);
      expect(json['seats'], ride.seats);
      expect(json['price'], ride.price);
      expect(json['hide_in_list_view'], ride.hideInListView);
      expect(json['drive_id'], ride.driveId);
      expect(json['rider_id'], ride.riderId);
      expect(json['chat_id'], ride.chatId);
      expect(json.keys.length, 15);
    });
  });
  group('Ride.toJsonForApi', () {
    test('returns a Json for Api representation of the ride', () async {
      final Ride ride = RideFactory().generateFake();
      final Map<String, dynamic> json = ride.toJsonForApi();
      expect(json['start'], ride.start);
      expect(json['start_lat'], ride.startPosition.lat);
      expect(json['start_lng'], ride.startPosition.lng);
      expect(json['start_date_time'], ride.startDateTime.toUtc().toString());
      expect(json['destination'], ride.destination);
      expect(json['destination_lat'], ride.destinationPosition.lat);
      expect(json['destination_lng'], ride.destinationPosition.lng);
      expect(json['destination_date_time'], ride.destinationDateTime.toUtc().toString());
      expect(json['status'], ride.status.index);
      expect(json['seats'], ride.seats);
      expect(json['price'], ride.price);
      expect(json['hide_in_list_view'], ride.hideInListView);
      expect(json['drive_id'], ride.driveId);
      expect(json['rider_id'], ride.riderId);
      expect(json['chat_id'], ride.chatId);
      expect(json['id'], ride.id);
      expect(json['created_at'], ride.createdAt?.toIso8601String());
      expect(json.keys.length, 20);
    });
  });
  group('Ride.userHasRideAtTimeRange', () {
    test('has ride in time range', () async {
      final DateTime now = DateTime.now();
      whenRequest(rideProcessor).thenReturnJson([
        RideFactory()
            .generateFake(
              riderId: 2,
              status: RideStatus.approved,
              startDateTime: now.add(const Duration(hours: 2)),
              destinationDateTime: now.add(const Duration(hours: 4)),
            )
            .toJsonForApi()
      ]);
      expect(
        await Ride.userHasRideAtTimeRange(
          DateTimeRange(start: now, end: now.add(const Duration(hours: 10))),
          2,
        ),
        true,
      );
    });
    test('has no ride at time range', () async {
      final DateTime now = DateTime.now();
      whenRequest(rideProcessor).thenReturnJson([
        RideFactory()
            .generateFake(
              riderId: 2,
              status: RideStatus.approved,
              startDateTime: now.add(const Duration(hours: 8)),
              destinationDateTime: now.add(const Duration(hours: 10)),
            )
            .toJsonForApi(),
        RideFactory()
            .generateFake(
              riderId: 2,
              startDateTime: now.add(const Duration(hours: 2)),
              destinationDateTime: now.add(const Duration(hours: 4)),
            )
            .toJsonForApi(),
      ]);
      expect(
        await Ride.userHasRideAtTimeRange(
          DateTimeRange(
            start: now.add(const Duration(hours: 4)),
            end: now.add(const Duration(hours: 6)),
          ),
          2,
        ),
        false,
      );
    });
    test('not approved ride overlaps with time range', () async {
      final DateTime now = DateTime.now();
      whenRequest(rideProcessor).thenReturnJson([
        RideFactory()
            .generateFake(
              riderId: 2,
              status: RideStatus.pending,
              startDateTime: now.add(const Duration(hours: 7)),
              destinationDateTime: now.add(const Duration(hours: 10)),
            )
            .toJsonForApi(),
      ]);
      expect(
        await Ride.userHasRideAtTimeRange(
          DateTimeRange(
            start: now.add(const Duration(hours: 6)),
            end: now.add(const Duration(hours: 8)),
          ),
          2,
        ),
        false,
      );
    });
    test('ride overlaps with time range', () async {
      final DateTime now = DateTime.now();
      whenRequest(rideProcessor).thenReturnJson([
        RideFactory()
            .generateFake(
              riderId: 2,
              status: RideStatus.approved,
              startDateTime: now.add(const Duration(hours: 7)),
              destinationDateTime: now.add(const Duration(hours: 10)),
            )
            .toJsonForApi(),
      ]);
      expect(
        await Ride.userHasRideAtTimeRange(
          DateTimeRange(
            start: now.add(const Duration(hours: 6)),
            end: now.add(const Duration(hours: 8)),
          ),
          2,
        ),
        true,
      );
    });
  });
  group('Ride.shouldShowInListView', () {
    test('rides are shown in ListView', () {
      final Ride ride = RideFactory().generateFake(
        destinationDateTime: DateTime.now().add(const Duration(hours: 2)),
        status: RideStatus.pending,
      );
      expect(ride.shouldShowInListView(past: false), true);
    });
    test('rides are shown in past ListView', () {
      final Ride ride = RideFactory().generateFake(
        destinationDateTime: DateTime.now().subtract(const Duration(hours: 2)),
        status: RideStatus.approved,
      );
      expect(ride.shouldShowInListView(past: true), true);
    });
    test('withdrawn rides are not shown in past ListView', () {
      final Ride ride = RideFactory().generateFake(
        startDateTime: DateTime.now().subtract(const Duration(hours: 4)),
        destinationDateTime: DateTime.now().subtract(const Duration(hours: 2)),
        status: RideStatus.withdrawnByRider,
      );
      expect(ride.shouldShowInListView(past: true), false);
    });
  });
  group('Ride.equals', () {
    final Ride ride0 = RideFactory().generateFake(
      id: 1,
      createdAt: DateTime(2022, 10),
      start: 'Berlin',
      startPosition: Position(1, 1),
      startDateTime: DateTime(2022, 11),
      destination: 'Frankfurt',
      destinationPosition: Position(2, 2),
      destinationDateTime: DateTime(2022, 12),
      seats: 1,
      createDependencies: false,
      driveId: 2,
      riderId: 3,
      chatId: 5,
      status: RideStatus.approved,
      price: NullableParameter(6),
    );
    test('same ride', () async {
      final Ride ride1 = RideFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startDateTime: DateTime(2022, 11),
        destination: 'Frankfurt',
        destinationPosition: Position(2, 2),
        destinationDateTime: DateTime(2022, 12),
        seats: 1,
        price: NullableParameter(6),
        status: RideStatus.approved,
        driveId: 2,
        riderId: 3,
        chatId: 5,
        createDependencies: false,
      );
      expect(ride0.equals(ride1), true);
    });
    test('handle drive', () async {
      final Drive drive = DriveFactory().generateFake(createDependencies: false);
      expect(ride0.equals(drive), false);
    });
    test('different parameter', () {
      for (int i = 0; i < 5; i++) {
        final Ride ride1 = RideFactory().generateFake(
          id: 1,
          createdAt: DateTime(2022, 10),
          start: 'Berlin',
          startPosition: Position(1, 1),
          startDateTime: DateTime(2022, 11),
          destination: 'Frankfurt',
          destinationPosition: Position(2, 2),
          destinationDateTime: DateTime(2022, 12),
          seats: 1,
          price: i == 0 ? NullableParameter(5) : NullableParameter(6),
          status: i == 1 ? RideStatus.pending : RideStatus.approved,
          driveId: i == 2 ? 5 : 2,
          riderId: i == 3 ? 6 : 3,
          chatId: i == 4 ? 7 : 5,
          createDependencies: false,
        );
        expect(ride0.equals(ride1), false);
      }
    });
  });
  group('Ride.cancel', () {
    test('status changes to cancelledByRider', () async {
      final Ride ride = RideFactory().generateFake(status: RideStatus.approved, createDependencies: false);
      whenRequest(rideProcessor).thenReturnJson(ride.toJsonForApi());
      ride.cancel();
      expect(ride.status, RideStatus.cancelledByRider);
    });
  });
  group('Ride.withdraw', () {
    test('status changes to withdrawnByRider', () async {
      final Ride ride = RideFactory().generateFake(status: RideStatus.pending, createDependencies: false);
      whenRequest(rideProcessor).thenReturnJson(ride.toJsonForApi());
      ride.withdraw();
      expect(ride.status, RideStatus.withdrawnByRider);
    });
  });
  group('Ride.toString', () {
    test('returns a string representation of the ride', () async {
      final Ride ride = RideFactory().generateFake(
        id: 1,
        start: 'start',
        startDateTime: DateTime.parse('2022-02-02T00:00:00.000'),
        destination: 'destination',
        destinationDateTime: DateTime.parse('2023-03-03T00:00:00.000'),
        driveId: 7,
        riderId: 5,
        chatId: 6,
        createDependencies: false,
      );
      expect(
        ride.toString(),
        'Ride{id: 1, in: 7, from: start at 2022-02-02 00:00:00.000, to: destination at 2023-03-03 00:00:00.000, by: 5}',
      );
    });
  });
  group('RideStatus.isCancelled', () {
    test('not cancelled', () {
      final Ride ride = RideFactory().generateFake(status: RideStatus.approved);
      expect(ride.status.isCancelled(), false);
    });
    test('cancelledByDriver', () {
      final Ride ride = RideFactory().generateFake(status: RideStatus.cancelledByDriver);
      expect(ride.status.isCancelled(), true);
    });
    test('cancelledByRider', () {
      final Ride ride = RideFactory().generateFake(status: RideStatus.cancelledByRider);
      expect(ride.status.isCancelled(), true);
    });
  });
  group('RideStatus.isApproved', () {
    test('approved', () {
      final Ride ride = RideFactory().generateFake(status: RideStatus.approved);
      expect(ride.status.isApproved(), true);
    });
    test('not approved', () {
      final Ride ride = RideFactory().generateFake(status: RideStatus.pending);
      expect(ride.status.isApproved(), false);
    });
  });
}
