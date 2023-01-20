import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/drives/models/drive.dart';
import 'package:motis_mitfahr_app/rides/models/ride.dart';
import 'package:motis_mitfahr_app/util/search/position.dart';

import '../util/factories/drive_factory.dart';
import '../util/factories/model_factory.dart';
import '../util/factories/profile_factory.dart';
import '../util/factories/ride_factory.dart';
import '../util/mock_server.dart';
import '../util/mock_server.mocks.dart';

// Die Klasse UrlProcessor muss zu Beginn jeder Testdatei implementiert werden und die Methode processUrl überschrieben werden
// Wird die Methode ProcessUrl aufgrufen, wird für den dort definierten Fall (in dem Beispiel client.from('drives').select('driver_id,seats')) die Antwort definiert
// Die Datenbankabfrage an den Client wird so abgefangen und das gewünschte Ergebnis zurückgegeben.
// Um herauszufinden welche URL durch die jeweilige Datenbankabfrage generiert wird, einfach den auskommentierten Print-Aufruf in der mockServer.Dart Datei aktivieren

void main() {
  final MockUrlProcessor driveProcessor = MockUrlProcessor();
  //setup muss in jeder Testklasse einmal aufgerufen werden
  setUp(() async {
    await MockServer.initialize();
    MockServer.handleRequests(driveProcessor);
  });

  group('Drive.fromJson', () {
    test('parses a drive from json with no driver and no rides', () {
      final Map<String, dynamic> json = {
        'id': 43,
        'created_at': '2021-01-01T00:00:00.000Z',
        'start': 'London',
        'start_lat': 2,
        'start_lng': 3,
        'start_time': '2022-01-01T00:00:00.000Z',
        'end': 'Berlin',
        'end_lat': 4,
        'end_lng': 5,
        'end_time': '2023-01-01T00:00:00.000Z',
        'seats': 2,
        'cancelled': true,
        'driver_id': 7,
        'hide_in_list_view': false,
      };
      final Drive drive = Drive.fromJson(json);
      expect(drive.id, json['id']);
      expect(drive.createdAt, DateTime.parse(json['created_at']));
      expect(drive.start, json['start']);
      expect(drive.startPosition, Position.fromDynamicValues(json['start_lat'], json['start_lng']));
      expect(drive.startTime, DateTime.parse(json['start_time']));
      expect(drive.end, json['end']);
      expect(drive.endPosition, Position.fromDynamicValues(json['end_lat'], json['end_lng']));
      expect(drive.endTime, DateTime.parse(json['end_time']));
      expect(drive.seats, json['seats']);
      expect(drive.cancelled, json['cancelled']);
      expect(drive.driverId, json['driver_id']);
      expect(drive.driver, null);
      expect(drive.rides, null);
      expect(drive.hideInListView, json['hide_in_list_view']);
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
        'end_lat': 4,
        'end_lng': 5,
        'end_time': '2023-01-01T00:00:00.000Z',
        'seats': 2,
        'cancelled': true,
        'driver_id': 7,
        'driver': ProfileFactory().generateFake().toJsonForApi(),
        'rides': RideFactory().generateFakeJsonList(length: 3),
        'hide_in_list_view': false,
      };
      final Drive drive = Drive.fromJson(json);
      expect(drive.id, json['id']);
      expect(drive.createdAt, DateTime.parse(json['created_at']));
      expect(drive.start, json['start']);
      expect(drive.startPosition, Position.fromDynamicValues(json['start_lat'], json['start_lng']));
      expect(drive.startTime, DateTime.parse(json['start_time']));
      expect(drive.end, json['end']);
      expect(drive.endPosition, Position.fromDynamicValues(json['end_lat'], json['end_lng']));
      expect(drive.endTime, DateTime.parse(json['end_time']));
      expect(drive.seats, json['seats']);
      expect(drive.cancelled, json['cancelled']);
      expect(drive.driverId, json['driver_id']);
      expect(drive.hideInListView, json['hide_in_list_view']);
      expect(drive.driver == null, false);
      expect(drive.rides!.length, 3);
    });
  });
  group('Drive.fromJsonList', () {
    test('parses a list of drives from json', () {
      final Map<String, dynamic> json = {
        'id': 43,
        'created_at': '2021-01-01T00:00:00.000Z',
        'start': 'London',
        'start_lat': 2,
        'start_lng': 3,
        'start_time': '2022-01-01T00:00:00.000Z',
        'end': 'Berlin',
        'end_lat': 4,
        'end_lng': 5,
        'end_time': '2023-01-01T00:00:00.000Z',
        'seats': 2,
        'cancelled': true,
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
    test('can handle an empty list', () {
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
      expect(json['start_time'], drive.startTime.toString());
      expect(json['end'], drive.end);
      expect(json['end_lat'], drive.endPosition.lat);
      expect(json['end_lng'], drive.endPosition.lng);
      expect(json['end_time'], drive.endTime.toString());
      expect(json['cancelled'], drive.cancelled);
      expect(json['seats'], drive.seats);
      expect(json['driver_id'], drive.driverId);
      expect(json.keys.length, 11);
    });
  });
  group('Drive.approvedrides', () {
    test('return null if rides is null', () async {
      final Drive drive = DriveFactory().generateFake(
        createDependencies: false,
      );
      expect(drive.approvedRides, null);
    });
    test('return an empty List if rides has no approved rides', () async {
      final Drive drive = DriveFactory().generateFake(
        rides: [
          RideFactory().generateFake(status: RideStatus.pending),
        ],
      );
      expect(drive.approvedRides, []);
    });
    test('return a List with 1 ride if rides has rides only has 1 ride and it is approved', () async {
      final Ride ride = RideFactory().generateFake(status: RideStatus.approved);
      final Drive drive = DriveFactory().generateFake(rides: [ride]);
      expect(drive.approvedRides, [ride]);
    });
    test('return the right ride with a rides have 1 approved in it', () async {
      final Ride ride = RideFactory().generateFake(status: RideStatus.approved);
      final Drive drive = DriveFactory().generateFake(
        rides: [
          RideFactory().generateFake(status: RideStatus.pending),
          RideFactory().generateFake(status: RideStatus.cancelledByDriver),
          RideFactory().generateFake(status: RideStatus.pending),
          ride,
          RideFactory().generateFake(status: RideStatus.rejected),
          RideFactory().generateFake(status: RideStatus.cancelledByRider),
          RideFactory().generateFake(status: RideStatus.withdrawnByRider),
        ],
      );
      expect(drive.approvedRides, [ride]);
    });
    test('return the right rides with a rides have more than 1 approved in it', () async {
      final Ride ride1 = RideFactory().generateFake(status: RideStatus.approved);
      final Ride ride2 = RideFactory().generateFake(status: RideStatus.approved);
      final Ride ride3 = RideFactory().generateFake(status: RideStatus.approved);

      final Drive drive = DriveFactory().generateFake(
        rides: [
          RideFactory().generateFake(status: RideStatus.pending),
          RideFactory().generateFake(status: RideStatus.cancelledByDriver),
          RideFactory().generateFake(status: RideStatus.pending),
          ride1,
          ride2,
          RideFactory().generateFake(status: RideStatus.rejected),
          RideFactory().generateFake(status: RideStatus.cancelledByRider),
          RideFactory().generateFake(status: RideStatus.withdrawnByRider),
          ride3,
        ],
      );
      expect(drive.approvedRides, [ride1, ride2, ride3]);
    });
  });
  group('Drive.pendingRides', () {
    test('return null if rides is null', () async {
      final Drive drive = DriveFactory().generateFake(
        createDependencies: false,
      );
      expect(drive.pendingRides, null);
    });
    test('return an empty List if rides has no pending rides', () async {
      final Drive drive = DriveFactory().generateFake(
        rides: [
          RideFactory().generateFake(status: RideStatus.approved),
        ],
      );
      expect(drive.pendingRides, []);
    });
    test('return a List with 1 ride if rides has 1 ride and is pending', () async {
      final Ride ride = RideFactory().generateFake(status: RideStatus.pending);
      final Drive drive = DriveFactory().generateFake(
        rides: [ride],
      );
      expect(drive.pendingRides, [ride]);
    });
    test('return the right ride with a rides have 1 pending in it', () async {
      final Ride ride = RideFactory().generateFake(status: RideStatus.pending);
      final Drive drive = DriveFactory().generateFake(
        rides: [
          RideFactory().generateFake(status: RideStatus.approved),
          RideFactory().generateFake(status: RideStatus.cancelledByDriver),
          ride,
          RideFactory().generateFake(status: RideStatus.rejected),
          RideFactory().generateFake(status: RideStatus.cancelledByRider),
          RideFactory().generateFake(status: RideStatus.withdrawnByRider),
        ],
      );
      expect(drive.pendingRides, [ride]);
    });
    test('return the right rides with a rides have more than 1 pending in it', () async {
      final Ride ride1 = RideFactory().generateFake(status: RideStatus.pending);
      final Ride ride2 = RideFactory().generateFake(status: RideStatus.pending);
      final Ride ride3 = RideFactory().generateFake(status: RideStatus.pending);

      final Drive drive = DriveFactory().generateFake(
        rides: [
          RideFactory().generateFake(status: RideStatus.approved),
          RideFactory().generateFake(status: RideStatus.cancelledByDriver),
          RideFactory().generateFake(status: RideStatus.approved),
          ride1,
          ride2,
          RideFactory().generateFake(status: RideStatus.rejected),
          RideFactory().generateFake(status: RideStatus.cancelledByRider),
          RideFactory().generateFake(status: RideStatus.withdrawnByRider),
          ride3,
        ],
      );
      expect(drive.pendingRides, [ride1, ride2, ride3]);
    });
  });
  group('Drive.getDrivesOfUser', () {});
  group('Drive.userHasDriveAtTimeRange', () {});
  // What to do if we use more seats than we have
  group('Drive.getMaxUsedSeats', () {
    test('returns null if rides are null', () async {
      final Drive drive = DriveFactory().generateFake(createDependencies: false);
      expect(drive.getMaxUsedSeats(), null);
    });
    test('returns 0 if there is no approved ride', () async {
      final Drive drive = DriveFactory().generateFake(seats: 3, rides: <Ride>[
        RideFactory().generateFake(
            startTime: DateTime(2022, 2, 2, 14, 30),
            endTime: DateTime(2022, 2, 2, 15),
            status: RideStatus.pending,
            seats: 1),
        RideFactory().generateFake(
            startTime: DateTime(2022, 2, 2, 14, 30),
            endTime: DateTime(2022, 2, 2, 15),
            status: RideStatus.pending,
            seats: 3),
        RideFactory().generateFake(
            startTime: DateTime(2022, 2, 2, 14, 30),
            endTime: DateTime(2022, 2, 2, 15),
            status: RideStatus.cancelledByRider,
            seats: 2),
        RideFactory().generateFake(
            startTime: DateTime(2022, 2, 2, 14, 30),
            endTime: DateTime(2022, 2, 2, 15),
            status: RideStatus.rejected,
            seats: 2),
        RideFactory().generateFake(
            startTime: DateTime(2022, 2, 2, 14, 30),
            endTime: DateTime(2022, 2, 2, 15),
            status: RideStatus.withdrawnByRider,
            seats: 1),
        RideFactory().generateFake(
            startTime: DateTime(2022, 2, 2, 14, 30),
            endTime: DateTime(2022, 2, 2, 15),
            status: RideStatus.cancelledByDriver,
            seats: 2),
      ]);
      expect(drive.getMaxUsedSeats(), 0);
    });
    test('returns 1 if rides has only 1 approved ride with 1 seat', () async {
      final Drive drive = DriveFactory().generateFake(seats: 3, rides: <Ride>[
        RideFactory().generateFake(
            startTime: DateTime(2022, 2, 2, 14, 30),
            endTime: DateTime(2022, 2, 2, 15),
            status: RideStatus.approved,
            seats: 1),
        RideFactory().generateFake(
            startTime: DateTime(2022, 2, 2, 14, 30),
            endTime: DateTime(2022, 2, 2, 15),
            status: RideStatus.pending,
            seats: 3),
        RideFactory().generateFake(
            startTime: DateTime(2022, 2, 2, 14, 30),
            endTime: DateTime(2022, 2, 2, 15),
            status: RideStatus.cancelledByRider,
            seats: 2),
        RideFactory().generateFake(
            startTime: DateTime(2022, 2, 2, 14, 30),
            endTime: DateTime(2022, 2, 2, 15),
            status: RideStatus.rejected,
            seats: 2),
        RideFactory().generateFake(
            startTime: DateTime(2022, 2, 2, 14, 30),
            endTime: DateTime(2022, 2, 2, 15),
            status: RideStatus.withdrawnByRider,
            seats: 1),
        RideFactory().generateFake(
            startTime: DateTime(2022, 2, 2, 14, 30),
            endTime: DateTime(2022, 2, 2, 15),
            status: RideStatus.cancelledByDriver,
            seats: 2),
      ]);
      expect(drive.getMaxUsedSeats(), 1);
    });
    test('returns 2 if rides has 2 approved ride with 1 seat at the same time', () async {
      final Drive drive = DriveFactory().generateFake(seats: 3, rides: <Ride>[
        RideFactory().generateFake(
            startTime: DateTime(2022, 2, 2, 14, 30),
            endTime: DateTime(2022, 2, 2, 15),
            status: RideStatus.approved,
            seats: 1),
        RideFactory().generateFake(
            startTime: DateTime(2022, 2, 2, 14, 30),
            endTime: DateTime(2022, 2, 2, 15),
            status: RideStatus.approved,
            seats: 1),
        RideFactory().generateFake(
            startTime: DateTime(2022, 2, 2, 14),
            endTime: DateTime(2022, 2, 2, 14, 20),
            status: RideStatus.approved,
            seats: 1),
        RideFactory().generateFake(
            startTime: DateTime(2022, 2, 2, 15),
            endTime: DateTime(2022, 2, 2, 15, 30),
            status: RideStatus.approved,
            seats: 1),
        RideFactory().generateFake(
            startTime: DateTime(2022, 2, 2, 14, 30),
            endTime: DateTime(2022, 2, 2, 15),
            status: RideStatus.withdrawnByRider,
            seats: 1),
        RideFactory().generateFake(
            startTime: DateTime(2022, 2, 2, 14, 30),
            endTime: DateTime(2022, 2, 2, 15),
            status: RideStatus.pending,
            seats: 1),
      ]);
      expect(drive.getMaxUsedSeats(), 2);
    });
    test('returns 4 if rides has a complex overlay where at its peak has 4 seats taken by approved rides', () async {
      final Drive drive = DriveFactory().generateFake(seats: 4, rides: <Ride>[
        RideFactory().generateFake(
            startTime: DateTime(2022, 2, 2, 14, 30),
            endTime: DateTime(2022, 2, 2, 15),
            status: RideStatus.approved,
            seats: 1),
        RideFactory().generateFake(
            startTime: DateTime(2022, 2, 2, 14),
            endTime: DateTime(2022, 2, 2, 14, 20),
            status: RideStatus.approved,
            seats: 3),
        RideFactory().generateFake(
            startTime: DateTime(2022, 2, 2, 14, 20),
            endTime: DateTime(2022, 2, 2, 15),
            status: RideStatus.approved,
            seats: 2),
        RideFactory().generateFake(
            startTime: DateTime(2022, 2, 2, 15),
            endTime: DateTime(2022, 2, 2, 15, 30),
            status: RideStatus.approved,
            seats: 2),
        RideFactory().generateFake(
            startTime: DateTime(2022, 2, 2, 14, 40),
            endTime: DateTime(2022, 2, 2, 14, 50),
            status: RideStatus.approved,
            seats: 1),
        RideFactory().generateFake(
            startTime: DateTime(2022, 2, 2, 15),
            endTime: DateTime(2022, 2, 2, 15, 20),
            status: RideStatus.approved,
            seats: 1),
      ]);
      expect(drive.getMaxUsedSeats(), 4);
    });
  });
  // what if ride starts or ends outside of the Drive time
  group('Drive.isRidePossible', () {
    test('returns true if ride has space in an empty drive', () async {
      final Drive drive = DriveFactory().generateFake(
        startTime: DateTime(2022, 2, 2, 14),
        endTime: DateTime(2022, 2, 2, 16),
        seats: 4,
        rides: [],
        createDependencies: false,
      );
      final Ride ride = RideFactory().generateFake(
          startTime: DateTime(2022, 2, 2, 14, 50),
          endTime: DateTime(2022, 2, 2, 15, 10),
          status: RideStatus.approved,
          seats: 1);
      expect(drive.isRidePossible(ride), true);
    });
    test('returns false if drive has 1 seat and its already taken', () async {
      final Drive drive = DriveFactory().generateFake(
        startTime: DateTime(2022, 2, 2, 14),
        endTime: DateTime(2022, 2, 2, 15),
        seats: 1,
        rides: [
          RideFactory().generateFake(
              startTime: DateTime(2022, 2, 2, 14),
              endTime: DateTime(2022, 2, 2, 15),
              status: RideStatus.approved,
              seats: 1)
        ],
        createDependencies: false,
      );
      final Ride ride = RideFactory().generateFake(
        startTime: DateTime(2022, 2, 2, 14, 50),
        endTime: DateTime(2022, 2, 2, 15),
        seats: 1,
      );
      expect(drive.isRidePossible(ride), false);
    });
    test('returns true if ride is able to fit in with a drive with many riders', () async {
      final Drive drive = DriveFactory().generateFake(
        startTime: DateTime(2022, 2, 2, 14),
        endTime: DateTime(2022, 2, 2, 16),
        seats: 4,
        rides: <Ride>[
          RideFactory().generateFake(
              startTime: DateTime(2022, 2, 2, 14),
              endTime: DateTime(2022, 2, 2, 15),
              status: RideStatus.approved,
              seats: 1),
          RideFactory().generateFake(
              startTime: DateTime(2022, 2, 2, 14),
              endTime: DateTime(2022, 2, 2, 14, 20),
              status: RideStatus.approved,
              seats: 3),
          RideFactory().generateFake(
              startTime: DateTime(2022, 2, 2, 14, 20),
              endTime: DateTime(2022, 2, 2, 15),
              status: RideStatus.approved,
              seats: 2),
          RideFactory().generateFake(
              startTime: DateTime(2022, 2, 2, 14, 40),
              endTime: DateTime(2022, 2, 2, 14, 50),
              status: RideStatus.approved,
              seats: 1),
          RideFactory().generateFake(
              startTime: DateTime(2022, 2, 2, 15),
              endTime: DateTime(2022, 2, 2, 15, 30),
              status: RideStatus.approved,
              seats: 2),
          RideFactory().generateFake(
              startTime: DateTime(2022, 2, 2, 15),
              endTime: DateTime(2022, 2, 2, 15, 20),
              status: RideStatus.approved,
              seats: 1),
        ],
      );
      final Ride ride = RideFactory().generateFake(
          startTime: DateTime(2022, 2, 2, 14, 50),
          endTime: DateTime(2022, 2, 2, 15, 10),
          status: RideStatus.approved,
          seats: 1);
      expect(drive.isRidePossible(ride), true);
    });
    test('returns false if ride not able to fit in with a drive with many riders', () async {
      final Drive drive = DriveFactory().generateFake(
        startTime: DateTime(2022, 2, 2, 14),
        endTime: DateTime(2022, 2, 2, 16),
        seats: 4,
        rides: <Ride>[
          RideFactory().generateFake(
              startTime: DateTime(2022, 2, 2, 14),
              endTime: DateTime(2022, 2, 2, 15),
              status: RideStatus.approved,
              seats: 1),
          RideFactory().generateFake(
              startTime: DateTime(2022, 2, 2, 14),
              endTime: DateTime(2022, 2, 2, 14, 20),
              status: RideStatus.approved,
              seats: 3),
          RideFactory().generateFake(
              startTime: DateTime(2022, 2, 2, 14, 20),
              endTime: DateTime(2022, 2, 2, 15),
              status: RideStatus.approved,
              seats: 2),
          RideFactory().generateFake(
              startTime: DateTime(2022, 2, 2, 14, 40),
              endTime: DateTime(2022, 2, 2, 14, 50),
              status: RideStatus.approved,
              seats: 1),
          RideFactory().generateFake(
              startTime: DateTime(2022, 2, 2, 15),
              endTime: DateTime(2022, 2, 2, 15, 30),
              status: RideStatus.approved,
              seats: 2),
          RideFactory().generateFake(
              startTime: DateTime(2022, 2, 2, 15),
              endTime: DateTime(2022, 2, 2, 15, 20),
              status: RideStatus.approved,
              seats: 1),
        ],
      );
      final Ride ride = RideFactory().generateFake(
          startTime: DateTime(2022, 2, 2, 14, 15),
          endTime: DateTime(2022, 2, 2, 15, 10),
          status: RideStatus.approved,
          seats: 1);
      expect(drive.isRidePossible(ride), false);
    });
  });
  group('Drive.cancel', () {});
  group('Drive.toString', () {
    test('returns a string representation of the drive', () async {
      final Drive drive = DriveFactory().generateFake(
        id: 1,
        start: 'start',
        startTime: DateTime.parse('2022-02-02T00:00:00.000Z'),
        end: 'end',
        endTime: DateTime.parse('2023-03-03T00:00:00.000Z'),
        driverId: 5,
        createDependencies: false,
      );
      expect(
        drive.toString(),
        'Drive{id: 1, from: start at 2022-02-02 00:00:00.000Z, to: end at 2023-03-03 00:00:00.000Z, by: 5}',
      );
    });
  });
  //soll equals auch auf rides prüfen und auf driver?
  group('Drive.equals', () {
    test('retrurns true when the drives are the same', () async {
      final Drive drive = DriveFactory().generateFake();
      expect(drive.equals(drive), true);
    });
    test('returns false when parameter is not a drive', () async {
      final Drive drive = DriveFactory().generateFake(createDependencies: false);
      final Ride ride = RideFactory().generateFake(createDependencies: false);
      expect(drive.equals(ride), false);
    });
    test('returns false when drive has not the same cancelled', () async {
      final Drive drive0 = DriveFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        cancelled: true,
        driverId: 2,
        createDependencies: false,
      );
      final Drive drive1 = DriveFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        cancelled: false,
        driver: NullableParameter(drive0.driver),
        createDependencies: false,
      );
      expect(drive0.equals(drive1), false);
    });
    test('returns false when drive has not the same driverId', () async {
      final Drive drive0 = DriveFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        cancelled: true,
        driverId: 2,
        createDependencies: false,
      );
      final Drive drive1 = DriveFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        cancelled: true,
        driverId: 3,
        createDependencies: false,
      );
      expect(drive0.equals(drive1), false);
    });
    test('returns false when drive has not the same id', () async {
      final Drive drive0 = DriveFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        cancelled: true,
        driverId: 2,
        createDependencies: false,
      );
      final Drive drive1 = DriveFactory().generateFake(
        id: 2,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        cancelled: true,
        driver: NullableParameter(drive0.driver),
        createDependencies: false,
      );
      expect(drive0.equals(drive1), false);
    });
    test('returns false when drive has not the same createdAt', () async {
      final Drive drive0 = DriveFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        cancelled: true,
        driverId: 2,
        createDependencies: false,
      );
      final Drive drive1 = DriveFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 9),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        cancelled: true,
        driver: NullableParameter(drive0.driver),
        createDependencies: false,
      );
      expect(drive0.equals(drive1), false);
    });
    test('returns false when drive has not the same start', () async {
      final Drive drive0 = DriveFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        cancelled: true,
        driverId: 2,
        createDependencies: false,
      );
      final Drive drive1 = DriveFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: 'Hamburg',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        cancelled: true,
        driver: NullableParameter(drive0.driver),
        createDependencies: false,
      );
      expect(drive0.equals(drive1), false);
    });
    test('returns false when drive has not the same startPosition', () async {
      final Drive drive0 = DriveFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        cancelled: true,
        driverId: 2,
        createDependencies: false,
      );
      final Drive drive1 = DriveFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(2, 1),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        cancelled: true,
        driver: NullableParameter(drive0.driver),
        createDependencies: false,
      );
      expect(drive0.equals(drive1), false);
    });
    test('returns false when drive has not the same startTime', () async {
      final Drive drive0 = DriveFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        cancelled: true,
        driverId: 2,
        createDependencies: false,
      );
      final Drive drive1 = DriveFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 10),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        cancelled: true,
        driver: NullableParameter(drive0.driver),
        createDependencies: false,
      );
      expect(drive0.equals(drive1), false);
    });
    test('returns false when drive has not the same end', () async {
      final Drive drive0 = DriveFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        cancelled: true,
        driverId: 2,
        createDependencies: false,
      );
      final Drive drive1 = DriveFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Darmstadt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        cancelled: true,
        driver: NullableParameter(drive0.driver),
        createDependencies: false,
      );
      expect(drive0.equals(drive1), false);
    });
    test('returns false when drive has not the same endPosition', () async {
      final Drive drive0 = DriveFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(2, 1),
        endTime: DateTime(2022, 12),
        seats: 1,
        cancelled: true,
        driverId: 2,
        createDependencies: false,
      );
      final Drive drive1 = DriveFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        cancelled: true,
        driver: NullableParameter(drive0.driver),
        createDependencies: false,
      );
      expect(drive0.equals(drive1), false);
    });
    test('returns false when drive has not the same endTime', () async {
      final Drive drive0 = DriveFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        cancelled: true,
        driverId: 2,
        createDependencies: false,
      );
      final Drive drive1 = DriveFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 11),
        seats: 1,
        cancelled: true,
        driver: NullableParameter(drive0.driver),
        createDependencies: false,
      );
      expect(drive0.equals(drive1), false);
    });
    test('returns false when drive has not the same seats', () async {
      final Drive drive0 = DriveFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        cancelled: true,
        driverId: 2,
        createDependencies: false,
      );
      final Drive drive1 = DriveFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 2,
        cancelled: true,
        driver: NullableParameter(drive0.driver),
        createDependencies: false,
      );
      expect(drive0.equals(drive1), false);
    });
    test('returns false when drive has not the same hideInListView', () async {
      final Drive drive0 = DriveFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        cancelled: true,
        driverId: 2,
        createDependencies: false,
      );
      final Drive drive1 = DriveFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: 'Berlin',
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: 'Frankfurt',
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        cancelled: true,
        driver: NullableParameter(drive0.driver),
        createDependencies: false,
        hideInListView: true,
      );
      expect(drive0.equals(drive1), false);
    });
  });
}
