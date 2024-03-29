import 'package:faker/faker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/search/position.dart';
import 'package:motis_mitfahr_app/trips/models/drive.dart';
import 'package:motis_mitfahr_app/trips/models/ride.dart';

import '../../test_util/factories/drive_factory.dart';
import '../../test_util/factories/model_factory.dart';
import '../../test_util/factories/profile_factory.dart';
import '../../test_util/factories/recurring_drive_factory.dart';
import '../../test_util/factories/ride_factory.dart';
import '../../test_util/mocks/mock_server.dart';
import '../../test_util/mocks/request_processor.dart';
import '../../test_util/mocks/request_processor.mocks.dart';

void main() {
  final MockRequestProcessor driveProcessor = MockRequestProcessor();
  setUp(() async {
    MockServer.setProcessor(driveProcessor);
  });
  group('Drive.fromJson', () {
    test('parses a drive from json with no driver and no rides', () {
      final Map<String, dynamic> json = {
        'id': 43,
        'created_at': '2021-01-01T00:00:00.000',
        'start': 'London',
        'start_lat': 2,
        'start_lng': 3,
        'start_date_time': '2022-01-01T00:00:00.000',
        'destination': 'Berlin',
        'destination_lat': 4,
        'destination_lng': 5,
        'destination_date_time': '2023-01-01T00:00:00.000',
        'seats': 2,
        'status': 1,
        'driver_id': 7,
        'recurring_drive_id': 8,
        'hide_in_list_view': false,
      };
      final Drive drive = Drive.fromJson(json);
      expect(drive.id, json['id']);
      expect(drive.createdAt, DateTime.parse(json['created_at']));
      expect(drive.start, json['start']);
      expect(drive.startPosition, Position.fromDynamicValues(json['start_lat'], json['start_lng']));
      expect(drive.startDateTime, DateTime.parse(json['start_date_time']));
      expect(drive.destination, json['destination']);
      expect(drive.destinationPosition, Position.fromDynamicValues(json['destination_lat'], json['destination_lng']));
      expect(drive.destinationDateTime, DateTime.parse(json['destination_date_time']));
      expect(drive.seats, json['seats']);
      expect(drive.status.index, json['status']);
      expect(drive.driverId, json['driver_id']);
      expect(drive.driver, null);
      expect(drive.recurringDriveId, json['recurring_drive_id']);
      expect(drive.recurringDrive, null);
      expect(drive.rides, null);
      expect(drive.hideInListView, json['hide_in_list_view']);
    });
    test('associated models', () {
      final Map<String, dynamic> json = {
        'id': 43,
        'created_at': '2021-01-01T00:00:00.000',
        'start': 'London',
        'start_lat': 2,
        'start_lng': 3,
        'start_date_time': '2022-01-01T00:00:00.000',
        'destination': 'Berlin',
        'destination_lat': 4,
        'destination_lng': 5,
        'destination_date_time': '2023-01-01T00:00:00.000',
        'seats': 2,
        'status': 1,
        'hide_in_list_view': false,
        'driver_id': 7,
        'driver': ProfileFactory().generateFake().toJsonForApi(),
        'recurring_drive_id': 8,
        'recurring_drive': RecurringDriveFactory().generateFake().toJsonForApi(),
        'rides': RideFactory().generateFakeJsonList(length: 3),
      };
      final Drive drive = Drive.fromJson(json);
      expect(drive.id, json['id']);
      expect(drive.createdAt, DateTime.parse(json['created_at']));
      expect(drive.start, json['start']);
      expect(drive.startPosition, Position.fromDynamicValues(json['start_lat'], json['start_lng']));
      expect(drive.startDateTime, DateTime.parse(json['start_date_time']));
      expect(drive.destination, json['destination']);
      expect(drive.destinationPosition, Position.fromDynamicValues(json['destination_lat'], json['destination_lng']));
      expect(drive.destinationDateTime, DateTime.parse(json['destination_date_time']));
      expect(drive.seats, json['seats']);
      expect(drive.status.index, json['status']);
      expect(drive.hideInListView, json['hide_in_list_view']);
      expect(drive.driverId, json['driver_id']);
      expect(drive.driver, isNotNull);
      expect(drive.recurringDriveId, json['recurring_drive_id']);
      expect(drive.recurringDrive, isNotNull);
      expect(drive.rides!.length, 3);
    });
  });
  group('Drive.fromJsonList', () {
    test('parses a list of drives from json', () {
      final Map<String, dynamic> json = {
        'id': 43,
        'created_at': '2021-01-01T00:00:00.000',
        'start': 'London',
        'start_lat': 2,
        'start_lng': 3,
        'start_date_time': '2022-01-01T00:00:00.000',
        'destination': 'Berlin',
        'destination_lat': 4,
        'destination_lng': 5,
        'destination_date_time': '2023-01-01T00:00:00.000',
        'seats': 2,
        'status': 1,
        'driver_id': 7,
        'hide_in_list_view': false,
      };
      final List<Map<String, dynamic>> jsonList = [json, json, json];
      final List<Drive> drives = Drive.fromJsonList(jsonList);
      expect(drives.length, 3);
      expect(drives.first.id, json['id']);
      expect(drives[1].start, json['start']);
      expect(drives.last.seats, 2);
    });
    test('empty list', () {
      final List<Drive> drives = Drive.fromJsonList([]);
      expect(drives, []);
    });
  });
  group('Drive.toJson', () {
    test('returns a json representation of the drive', () async {
      final Drive drive = DriveFactory().generateFake();
      final Map<String, dynamic> json = drive.toJson();
      expect(json['start'], drive.start);
      expect(json['start_lat'], drive.startPosition.lat);
      expect(json['start_lng'], drive.startPosition.lng);
      expect(json['start_date_time'], drive.startDateTime.toUtc().toString());
      expect(json['destination'], drive.destination);
      expect(json['destination_lat'], drive.destinationPosition.lat);
      expect(json['destination_lng'], drive.destinationPosition.lng);
      expect(json['destination_date_time'], drive.destinationDateTime.toUtc().toString());
      expect(json['status'], drive.status.index);
      expect(json['seats'], drive.seats);
      expect(json['driver_id'], drive.driverId);
      expect(json['recurring_drive_id'], drive.recurringDriveId);
      expect(json['hide_in_list_view'], drive.hideInListView);
      expect(json.keys.length, 13);
    });
  });
  group('Drive.approvedRides', () {
    test('has no approved rides', () async {
      final Drive drive = DriveFactory().generateFake(
        rides: List.generate(
          RideStatus.values.length,
          (index) => RideFactory().generateFake(status: RideStatus.values[index]),
        ).where((element) => element.status != RideStatus.approved).toList(),
      );
      expect(drive.approvedRides, []);
    });
    test('has approved rides', () async {
      final Ride ride1 = RideFactory().generateFake(status: RideStatus.approved);
      final Ride ride2 = RideFactory().generateFake(status: RideStatus.approved);

      final Drive drive = DriveFactory().generateFake(
        rides: List.generate(
          RideStatus.values.length,
          (index) => RideFactory().generateFake(status: RideStatus.values[index]),
        ).where((element) => element.status != RideStatus.approved).toList(),
      );
      drive.rides!.addAll([ride1, ride2]);
      expect(drive.approvedRides, [ride1, ride2]);
    });
  });
  group('Drive.pendingRides', () {
    test('has no pending rides', () async {
      final Drive drive = DriveFactory().generateFake(
        rides: List.generate(
          RideStatus.values.length,
          (index) => RideFactory().generateFake(status: RideStatus.values[index]),
        ).where((element) => element.status != RideStatus.pending).toList(),
      );
      expect(drive.pendingRides, []);
    });
    test('has pending rides', () async {
      final Ride ride1 = RideFactory().generateFake(status: RideStatus.pending);
      final Ride ride2 = RideFactory().generateFake(status: RideStatus.pending);

      final Drive drive = DriveFactory().generateFake(
        rides: List.generate(
          RideStatus.values.length,
          (index) => RideFactory().generateFake(status: RideStatus.values[index]),
        ).where((element) => element.status != RideStatus.pending).toList(),
      );
      drive.rides!.addAll([ride1, ride2]);
      expect(drive.pendingRides, [ride1, ride2]);
    });
  });

  group('Drive.isUpcomingRecurringDriveInstance', () {
    test('is upcoming recurring drive instance', () async {
      final Drive drive = DriveFactory().generateFake(
        startDateTime: DateTime.now().add(const Duration(hours: 2)),
        destinationDateTime: DateTime.now().add(const Duration(hours: 4)),
        recurringDriveId: NullableParameter(random.integer(1000)),
        hideInListView: false,
        status: [DriveStatus.cancelledByDriver, DriveStatus.plannedOrFinished][random.integer(2)],
      );
      expect(drive.isUpcomingRecurringDriveInstance, isTrue);
    });

    test('No recurring drive', () async {
      final Drive drive = DriveFactory().generateFake(
        startDateTime: DateTime.now().add(const Duration(hours: 2)),
        destinationDateTime: DateTime.now().add(const Duration(hours: 4)),
        recurringDrive: NullableParameter(null),
        recurringDriveId: NullableParameter(null),
      );
      expect(drive.isUpcomingRecurringDriveInstance, isFalse);
    });

    test('Hidden in list view', () async {
      final Drive drive = DriveFactory().generateFake(
        startDateTime: DateTime.now().add(const Duration(hours: 2)),
        destinationDateTime: DateTime.now().add(const Duration(hours: 4)),
        recurringDriveId: NullableParameter(random.integer(1000)),
        hideInListView: true,
      );
      expect(drive.isUpcomingRecurringDriveInstance, isFalse);
    });

    test('Cancelled by RRule and no rides', () async {
      final Drive drive = DriveFactory().generateFake(
        startDateTime: DateTime.now().add(const Duration(hours: 2)),
        destinationDateTime: DateTime.now().add(const Duration(hours: 4)),
        recurringDriveId: NullableParameter(random.integer(1000)),
        hideInListView: false,
        status: DriveStatus.cancelledByRecurrenceRule,
        rides: List.empty(),
      );
      expect(drive.isUpcomingRecurringDriveInstance, isFalse);
    });

    test('Cancelled by RRule and rides not loaded', () async {
      final Drive drive = DriveFactory().generateFake(
        startDateTime: DateTime.now().add(const Duration(hours: 2)),
        destinationDateTime: DateTime.now().add(const Duration(hours: 4)),
        recurringDriveId: NullableParameter(random.integer(1000)),
        hideInListView: false,
        status: DriveStatus.cancelledByRecurrenceRule,
        createDependencies: false,
      );
      expect(drive.isUpcomingRecurringDriveInstance, isTrue);
    });

    test('Cancelled by RRule and rides', () async {
      final Drive drive = DriveFactory().generateFake(
        startDateTime: DateTime.now().add(const Duration(hours: 2)),
        destinationDateTime: DateTime.now().add(const Duration(hours: 4)),
        recurringDriveId: NullableParameter(random.integer(1000)),
        hideInListView: false,
        status: DriveStatus.cancelledByRecurrenceRule,
        rides: RideFactory().generateFakeList(),
      );
      expect(drive.isUpcomingRecurringDriveInstance, isTrue);
    });
  });
  group('Drive.getMaxUsedSeats', () {
    test('can handle null', () async {
      final Drive drive = DriveFactory().generateFake(createDependencies: false);
      expect(drive.getMaxUsedSeats(), null);
    });
    test('no seats taken', () async {
      final Drive drive = DriveFactory().generateFake(
        seats: 3,
        rides: [
          RideFactory().generateFake(status: RideStatus.pending),
          RideFactory().generateFake(status: RideStatus.withdrawnByRider),
          RideFactory().generateFake(status: RideStatus.cancelledByDriver),
        ],
      );
      expect(drive.getMaxUsedSeats(), 0);
    });
    test('seats are taken by approved rides', () async {
      final DateTime now = DateTime.now();
      final Drive drive = DriveFactory().generateFake(
        seats: 3,
        rides: <Ride>[
          RideFactory().generateFake(
            startDateTime: now,
            destinationDateTime: now.add(const Duration(minutes: 30)),
            status: RideStatus.approved,
            seats: 2,
          ),
          RideFactory().generateFake(
            startDateTime: now,
            status: RideStatus.cancelledByRider,
            seats: 2,
          ),
          RideFactory().generateFake(
            startDateTime: now,
            status: RideStatus.rejected,
            seats: 2,
          ),
          RideFactory().generateFake(
            startDateTime: now.add(const Duration(hours: 1)),
            status: RideStatus.approved,
            seats: 1,
          ),
        ],
      );
      expect(drive.getMaxUsedSeats(), 2);
    });
    test('multiple rides take seats at the same time', () async {
      final DateTime now = DateTime.now();
      final Drive drive = DriveFactory().generateFake(
        seats: 3,
        rides: [
          RideFactory().generateFake(
            startDateTime: now.add(const Duration(minutes: 30)),
            destinationDateTime: now.add(const Duration(hours: 1)),
            status: RideStatus.approved,
            seats: 1,
          ),
          RideFactory().generateFake(
            startDateTime: now,
            destinationDateTime: now.add(const Duration(minutes: 20)),
            status: RideStatus.approved,
            seats: 1,
          ),
          RideFactory().generateFake(
            startDateTime: now.add(const Duration(minutes: 20)),
            destinationDateTime: now.add(const Duration(hours: 1)),
            status: RideStatus.approved,
            seats: 2,
          ),
        ],
      );
      expect(drive.getMaxUsedSeats(), 3);
    });
  });
  group('Drive.isRidePossible', () {
    test('empty drive', () async {
      final Drive drive = DriveFactory().generateFake(
        seats: 4,
        rides: [],
        createDependencies: false,
      );
      final Ride ride = RideFactory().generateFake(
        startDateTime: drive.startDateTime,
        destinationDateTime: drive.destinationDateTime,
        seats: 2,
      );
      expect(drive.isRidePossible(ride), true);
    });
    test('full ride', () async {
      final DateTime now = DateTime.now();
      final Drive drive = DriveFactory().generateFake(
        startDateTime: now,
        destinationDateTime: now.add(const Duration(hours: 1)),
        seats: 1,
        rides: [
          RideFactory().generateFake(
            startDateTime: now,
            destinationDateTime: now.add(const Duration(hours: 1)),
            status: RideStatus.approved,
            seats: 1,
          )
        ],
        createDependencies: false,
      );
      final Ride ride = RideFactory().generateFake(
        startDateTime: now.add(const Duration(minutes: 30)),
        destinationDateTime: now.add(const Duration(hours: 1)),
      );
      expect(drive.isRidePossible(ride), false);
    });
    test('share ride with other rides', () async {
      final DateTime now = DateTime.now();
      final Drive drive = DriveFactory().generateFake(
        startDateTime: now,
        destinationDateTime: now.add(const Duration(hours: 2)),
        seats: 4,
        rides: <Ride>[
          RideFactory().generateFake(
            startDateTime: now.add(const Duration(minutes: 20)),
            destinationDateTime: now.add(const Duration(hours: 1)),
            status: RideStatus.approved,
            seats: 2,
          ),
          RideFactory().generateFake(
            startDateTime: now.add(const Duration(minutes: 40)),
            destinationDateTime: now.add(const Duration(minutes: 50)),
            status: RideStatus.approved,
            seats: 1,
          ),
          RideFactory().generateFake(
            startDateTime: now.add(const Duration(hours: 1)),
            destinationDateTime: now.add(const Duration(hours: 1, minutes: 30)),
            status: RideStatus.approved,
            seats: 2,
          ),
        ],
      );
      final Ride ride = RideFactory().generateFake(
        startDateTime: now.add(const Duration(minutes: 50)),
        destinationDateTime: now.add(const Duration(hours: 1, minutes: 10)),
        seats: 1,
      );
      expect(drive.isRidePossible(ride), true);
    });
  });
  group('Drive.cancel', () {
    test('status is set to cancelledByDriver', () async {
      final Drive drive = DriveFactory().generateFake(createDependencies: false);
      whenRequest(driveProcessor).thenReturnJson(drive.toJsonForApi());
      await drive.cancel();
      verifyRequest(
        driveProcessor,
        urlMatcher: equals('/rest/v1/drives?id=eq.${drive.id}'),
        methodMatcher: equals('PATCH'),
        bodyMatcher: equals({
          'status': 2,
        }),
      );
      expect(drive.status, DriveStatus.cancelledByDriver);
    });
  });
  group('Drive.toString', () {
    test('returns a string representation of the drive', () async {
      final Drive drive = DriveFactory().generateFake(
        id: 1,
        start: 'start',
        startDateTime: DateTime.parse('2022-02-02T00:00:00.000'),
        destination: 'destination',
        destinationDateTime: DateTime.parse('2023-03-03T00:00:00.000'),
        driverId: 5,
        createDependencies: false,
      );
      expect(
        drive.toString(),
        'Drive{id: 1, from: start at 2022-02-02 00:00:00.000, to: destination at 2023-03-03 00:00:00.000, by: 5}',
      );
    });
  });
  group('Drive.equals', () {
    final Drive drive0 = DriveFactory().generateFake(
      id: 1,
      createdAt: DateTime(2022, 10),
      start: 'Berlin',
      startPosition: Position(1, 1),
      startDateTime: DateTime(2022, 11),
      destination: 'Frankfurt',
      destinationPosition: Position(2, 2),
      destinationDateTime: DateTime(2022, 12),
      seats: 1,
      status: DriveStatus.cancelledByDriver,
      driverId: 2,
      createDependencies: false,
    );
    test('same drive', () async {
      final Drive drive1 = DriveFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startDateTime: DateTime(2022, 11),
        destination: 'Frankfurt',
        destinationPosition: Position(2, 2),
        destinationDateTime: DateTime(2022, 12),
        seats: 1,
        status: DriveStatus.cancelledByDriver,
        driverId: 2,
        createDependencies: false,
      );
      expect(drive0.equals(drive1), true);
    });
    test('handle ride', () async {
      final Ride ride = RideFactory().generateFake(createDependencies: false);
      expect(drive0.equals(ride), false);
    });
    test('different parameter', () async {
      for (int i = 0; i < 2; i++) {
        final Drive drive1 = DriveFactory().generateFake(
          id: 1,
          createdAt: DateTime(2022, 10),
          start: 'Berlin',
          startPosition: Position(1, 1),
          startDateTime: DateTime(2022, 11),
          destination: 'Frankfurt',
          destinationPosition: Position(2, 2),
          destinationDateTime: DateTime(2022, 12),
          seats: 1,
          status: i != 0 ? DriveStatus.plannedOrFinished : DriveStatus.cancelledByDriver,
          driverId: i == 1 ? 2 : 3,
          createDependencies: false,
        );
        expect(drive0.equals(drive1), false);
      }
    });
  });
}
