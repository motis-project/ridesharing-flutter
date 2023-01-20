import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/drives/models/drive.dart';
import 'package:motis_mitfahr_app/rides/models/ride.dart';
import 'package:motis_mitfahr_app/util/search/position.dart';

import '../util/factories/drive_factory.dart';
import '../util/factories/model_factory.dart';
import '../util/factories/ride_factory.dart';
import '../util/mock_server.dart';
import '../util/mock_server.mocks.dart';

// Die Klasse UrlProcessor muss zu Beginn jeder Testdatei implementiert werden und die Methode processUrl überschrieben werden
// Wird die Methode ProcessUrl aufgrufen, wird für den dort definierten Fall (in dem Beispiel client.from('drives').select('driver_id,seats')) die Antwort definiert
// Die Datenbankabfrage an den Client wird so abgefangen und das gewünschte Ergebnis zurückgegeben.
// Um herauszufinden welche URL durch die jeweilige Datenbankabfrage generiert wird, einfach den auskommentierten Print-Aufruf in der mockServer.Dart Datei aktivieren

void main() {
  MockUrlProcessor driveProcessor = MockUrlProcessor();
  //setup muss in jeder Testklasse einmal aufgerufen werden
  setUp(() async {
    await MockServer.initialize();
    MockServer.handleRequests(driveProcessor);
  });

  group('Drive.fromJson', () {});
  group('Drive.fromJsonList', () {});
  group('Drive.toJson', () {});
  group('Drive.approvedrides', () {});
  group('Drive.pendingRides', () {});
  group('Drive.getDrivesOfUser', () {});
  group('Drive.userHasDriveAtTimeRange', () {});
  // What to do if we use more seats than we have
  group('Drive.getMaxUsedSeats', () {
    test('returns null if rides are null', () async {
      Drive drive = DriveFactory().generateFake(rides: null, createDependencies: false);
      expect(drive.getMaxUsedSeats(), null);
    });
    test('returns 0 if there is no approved ride', () async {
      Drive drive = DriveFactory().generateFake(seats: 3, rides: <Ride>[
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
      Drive drive = DriveFactory().generateFake(seats: 3, rides: <Ride>[
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
      Drive drive = DriveFactory().generateFake(seats: 3, rides: <Ride>[
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
      Drive drive = DriveFactory().generateFake(seats: 4, rides: <Ride>[
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
  group('Drive.isRidePossible', () {
    test('returns true if ride has space in an empty drive', () async {
      Drive drive = DriveFactory().generateFake(
        startTime: DateTime(2022, 2, 2, 14),
        endTime: DateTime(2022, 2, 2, 16),
        seats: 4,
        rides: [],
        createDependencies: false,
      );
      Ride ride = RideFactory().generateFake(
          startTime: DateTime(2022, 2, 2, 14, 50),
          endTime: DateTime(2022, 2, 2, 15, 10),
          status: RideStatus.approved,
          seats: 1);
      expect(drive.isRidePossible(ride), true);
    });
    test('returns false if drive has 1 seat and its already taken', () async {
      Drive drive = DriveFactory().generateFake(
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
      Ride ride = RideFactory().generateFake(
        startTime: DateTime(2022, 2, 2, 14, 50),
        endTime: DateTime(2022, 2, 2, 15, 10),
        seats: 1,
      );
      expect(drive.isRidePossible(ride), true);
    });
    test('returns true if ride is able to fit in with a drive with many riders', () async {
      Drive drive = DriveFactory().generateFake(
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
      Ride ride = RideFactory().generateFake(
          startTime: DateTime(2022, 2, 2, 14, 50),
          endTime: DateTime(2022, 2, 2, 15, 10),
          status: RideStatus.approved,
          seats: 1);
      expect(drive.isRidePossible(ride), true);
    });
  });
  group('Drive.cancel', () {});
  group('Drive.toString', () {
    test('returns a string representation of the drive', () async {
      Drive drive = DriveFactory().generateFake(
        id: 1,
        start: "start",
        startTime: DateTime.parse("2022-02-02T00:00:00.000Z"),
        end: "end",
        endTime: DateTime.parse("2023-03-03T00:00:00.000Z"),
        driverId: 5,
        createDependencies: false,
      );
      expect(
        drive.toString(),
        "Drive{id: 1, from: start at 2022-02-02 00:00:00.000Z, to: end at 2023-03-03 00:00:00.000Z, by: 5}",
      );
    });
  });
  //soll equals auch auf rides prüfen und auf driver?
  group('Drive.equals', () {
    test('retrurns true when the drives are the same', () async {
      Drive drive = DriveFactory().generateFake(createDependencies: true);
      expect(drive.equals(drive), true);
    });
    test('returns false when parameter is not a drive', () async {
      Drive drive = DriveFactory().generateFake(createDependencies: false);
      Ride ride = RideFactory().generateFake(createDependencies: false);
      expect(drive.equals(ride), false);
    });
    test('returns false when drive has not the same cancelled', () async {
      Drive drive0 = DriveFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: "Berlin",
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: "Frankfurt",
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        cancelled: true,
        driverId: 2,
        rides: null,
        createDependencies: false,
      );
      Drive drive1 = DriveFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: "Berlin",
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: "Frankfurt",
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        cancelled: false,
        driver: NullableParameter(drive0.driver),
        rides: null,
        createDependencies: false,
      );
      expect(drive0.equals(drive1), false);
    });
    test('returns false when drive has not the same driverId', () async {
      Drive drive0 = DriveFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: "Berlin",
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: "Frankfurt",
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        cancelled: true,
        driverId: 2,
        rides: null,
        createDependencies: false,
      );
      Drive drive1 = DriveFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: "Berlin",
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: "Frankfurt",
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        cancelled: true,
        driverId: 3,
        rides: null,
        createDependencies: false,
      );
      expect(drive0.equals(drive1), false);
    });
    test('returns false when drive has not the same id', () async {
      Drive drive0 = DriveFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: "Berlin",
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: "Frankfurt",
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        cancelled: true,
        driverId: 2,
        rides: null,
        createDependencies: false,
      );
      Drive drive1 = DriveFactory().generateFake(
        id: 2,
        createdAt: DateTime(2022, 10),
        start: "Berlin",
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: "Frankfurt",
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        cancelled: true,
        driver: NullableParameter(drive0.driver),
        rides: null,
        createDependencies: false,
      );
      expect(drive0.equals(drive1), false);
    });
    test('returns false when drive has not the same createdAt', () async {
      Drive drive0 = DriveFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: "Berlin",
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: "Frankfurt",
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        cancelled: true,
        driverId: 2,
        rides: null,
        createDependencies: false,
      );
      Drive drive1 = DriveFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 9),
        start: "Berlin",
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: "Frankfurt",
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        cancelled: true,
        driver: NullableParameter(drive0.driver),
        rides: null,
        createDependencies: false,
      );
      expect(drive0.equals(drive1), false);
    });
    test('returns false when drive has not the same start', () async {
      Drive drive0 = DriveFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: "Berlin",
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: "Frankfurt",
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        cancelled: true,
        driverId: 2,
        rides: null,
        createDependencies: false,
      );
      Drive drive1 = DriveFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: "Hamburg",
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: "Frankfurt",
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        cancelled: true,
        driver: NullableParameter(drive0.driver),
        rides: null,
        createDependencies: false,
      );
      expect(drive0.equals(drive1), false);
    });
    test('returns false when drive has not the same startPosition', () async {
      Drive drive0 = DriveFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: "Berlin",
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: "Frankfurt",
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        cancelled: true,
        driverId: 2,
        rides: null,
        createDependencies: false,
      );
      Drive drive1 = DriveFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: "Berlin",
        startPosition: Position(2, 1),
        startTime: DateTime(2022, 11),
        end: "Frankfurt",
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        cancelled: true,
        driver: NullableParameter(drive0.driver),
        rides: null,
        createDependencies: false,
      );
      expect(drive0.equals(drive1), false);
    });
    test('returns false when drive has not the same startTime', () async {
      Drive drive0 = DriveFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: "Berlin",
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: "Frankfurt",
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        cancelled: true,
        driverId: 2,
        rides: null,
        createDependencies: false,
      );
      Drive drive1 = DriveFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: "Berlin",
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 10),
        end: "Frankfurt",
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        cancelled: true,
        driver: NullableParameter(drive0.driver),
        rides: null,
        createDependencies: false,
      );
      expect(drive0.equals(drive1), false);
    });
    test('returns false when drive has not the same end', () async {
      Drive drive0 = DriveFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: "Berlin",
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: "Frankfurt",
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        cancelled: true,
        driverId: 2,
        rides: null,
        createDependencies: false,
      );
      Drive drive1 = DriveFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: "Berlin",
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: "Darmstadt",
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        cancelled: true,
        driver: NullableParameter(drive0.driver),
        rides: null,
        createDependencies: false,
      );
      expect(drive0.equals(drive1), false);
    });
    test('returns false when drive has not the same endPosition', () async {
      Drive drive0 = DriveFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: "Berlin",
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: "Frankfurt",
        endPosition: Position(2, 1),
        endTime: DateTime(2022, 12),
        seats: 1,
        cancelled: true,
        driverId: 2,
        rides: null,
        createDependencies: false,
      );
      Drive drive1 = DriveFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: "Berlin",
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: "Frankfurt",
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        cancelled: true,
        driver: NullableParameter(drive0.driver),
        rides: null,
        createDependencies: false,
      );
      expect(drive0.equals(drive1), false);
    });
    test('returns false when drive has not the same endTime', () async {
      Drive drive0 = DriveFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: "Berlin",
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: "Frankfurt",
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        cancelled: true,
        driverId: 2,
        rides: null,
        createDependencies: false,
      );
      Drive drive1 = DriveFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: "Berlin",
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: "Frankfurt",
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 11),
        seats: 1,
        cancelled: true,
        driver: NullableParameter(drive0.driver),
        rides: null,
        createDependencies: false,
      );
      expect(drive0.equals(drive1), false);
    });
    test('returns false when drive has not the same seats', () async {
      Drive drive0 = DriveFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: "Berlin",
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: "Frankfurt",
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        cancelled: true,
        driverId: 2,
        rides: null,
        createDependencies: false,
      );
      Drive drive1 = DriveFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: "Berlin",
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: "Frankfurt",
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 2,
        cancelled: true,
        driver: NullableParameter(drive0.driver),
        rides: null,
        createDependencies: false,
      );
      expect(drive0.equals(drive1), false);
    });
    test('returns false when drive has not the same hideInListView', () async {
      Drive drive0 = DriveFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: "Berlin",
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: "Frankfurt",
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        cancelled: true,
        driverId: 2,
        rides: null,
        createDependencies: false,
      );
      Drive drive1 = DriveFactory().generateFake(
        id: 1,
        createdAt: DateTime(2022, 10),
        start: "Berlin",
        startPosition: Position(1, 1),
        startTime: DateTime(2022, 11),
        end: "Frankfurt",
        endPosition: Position(2, 2),
        endTime: DateTime(2022, 12),
        seats: 1,
        cancelled: true,
        driver: NullableParameter(drive0.driver),
        rides: null,
        createDependencies: false,
        hideInListView: true,
      );
      expect(drive0.equals(drive1), false);
    });
  });
}
