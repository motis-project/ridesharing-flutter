import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/drives/models/recurring_drive.dart';
import 'package:rrule/rrule.dart';

import '../util/factories/drive_factory.dart';
import '../util/factories/profile_factory.dart';
import '../util/factories/recurring_drive_factory.dart';
import '../util/mocks/mock_server.dart';
import '../util/mocks/request_processor.dart';
import '../util/mocks/request_processor.mocks.dart';

void main() {
  final MockRequestProcessor processor = MockRequestProcessor();
  setUp(() async {
    MockServer.setProcessor(processor);
  });

  group('RecurringDrive.fromJson', () {
    test('parses a Chat from json', () {
      final Map<String, dynamic> json = {
        'id': 43,
        'created_at': '2021-01-01T00:00:00.000Z',
        'start': 'London',
        'start_lat': 2,
        'start_lng': 3,
        'start_time': '22:37:23',
        'end': 'Berlin',
        'end_lat': 4,
        'end_lng': 5,
        'end_time': '12:47:01',
        'seats': 2,
        'stopped': false,
        'rrule': 'DTSTART:20230207T234500Z\nRRULE:FREQ=DAILY;UNTIL=20230410T234500Z;INTERVAL=1;WKST=MO',
        'driver_id': 7,
      };
      final RecurringDrive recurringDrive = RecurringDrive.fromJson(json);
      expect(recurringDrive.id, json['id']);
      expect(recurringDrive.createdAt, DateTime.parse(json['created_at']));
      expect(recurringDrive.start, json['start']);
      expect(recurringDrive.startPosition.lat, json['start_lat']);
      expect(recurringDrive.startPosition.lng, json['start_lng']);
      expect(recurringDrive.startTime, const TimeOfDay(hour: 22, minute: 37));
      expect(recurringDrive.stopped, json['stopped']);
      expect(recurringDrive.rrule.frequency, Frequency.daily);
      expect(recurringDrive.driverId, json['driver_id']);
    });

    test('can handle associated models', () {
      final Map<String, dynamic> json = {
        'id': 43,
        'created_at': '2021-01-01T00:00:00.000Z',
        'start': 'London',
        'start_lat': 2,
        'start_lng': 3,
        'start_time': '22:37:23',
        'end': 'Berlin',
        'end_lat': 4,
        'end_lng': 5,
        'end_time': '12:47:01',
        'seats': 2,
        'stopped': false,
        'rrule': 'DTSTART:20230207T234500Z\nRRULE:FREQ=DAILY;UNTIL=20230410T234500Z;INTERVAL=1;WKST=MO',
        'driver_id': 7,
        'driver': ProfileFactory().generateFake().toJsonForApi(),
        'drives': [DriveFactory().generateFake().toJsonForApi(), DriveFactory().generateFake().toJsonForApi()],
      };
      final RecurringDrive recurringDrive = RecurringDrive.fromJson(json);
      expect(recurringDrive.driver, isNotNull);
      expect(recurringDrive.drives, hasLength(2));
    });
  });

  group('RecurringDrive.fromJsonList', () {
    test('parses a List of recurring drives from json', () {
      final Map<String, dynamic> json = {
        'id': 43,
        'created_at': '2021-01-01T00:00:00.000Z',
        'start': 'London',
        'start_lat': 2,
        'start_lng': 3,
        'start_time': '22:37:23',
        'end': 'Berlin',
        'end_lat': 4,
        'end_lng': 5,
        'end_time': '12:47:01',
        'seats': 2,
        'stopped': false,
        'rrule': 'DTSTART:20230207T234500Z\nRRULE:FREQ=DAILY;UNTIL=20230410T234500Z;INTERVAL=1;WKST=MO',
        'driver_id': 7,
      };
      final List<RecurringDrive> recurringDrives = RecurringDrive.fromJsonList([json, json, json]);
      expect(recurringDrives.length, 3);
      expect(recurringDrives[0].id, json['id']);
      expect(recurringDrives[2].rrule.frequency, Frequency.daily);
    });

    test('can handle empty List', () {
      final List<RecurringDrive> recurringDrives = RecurringDrive.fromJsonList([]);
      expect(recurringDrives.length, 0);
    });
  });

  group('RecurringDrive.toJson', () {
    test('transforms a recurring drive to json', () {
      final RecurringDrive recurringDrive = RecurringDriveFactory().generateFake();
      final Map<String, dynamic> json = recurringDrive.toJson();
      expect(json['start'], recurringDrive.start);
      expect(json['stopped'], recurringDrive.stopped);
      expect(json['rrule'], contains('\n${recurringDrive.rrule}'));
      expect(json.keys.length, 12);
    });
  });

  group('RecurringDrive.stop', () {
    test('cancelled is being changed from false to true', () async {
      final RecurringDrive recurringDrive =
          RecurringDriveFactory().generateFake(stopped: false, createDependencies: false);
      whenRequest(processor).thenReturnJson(recurringDrive.toJsonForApi());
      await recurringDrive.stop();
      verifyRequest(
        processor,
        urlMatcher: equals('/rest/v1/recurring_drives?id=eq.${recurringDrive.id}'),
        methodMatcher: equals('PATCH'),
        bodyMatcher: equals({
          'stopped': true,
        }),
      );
      expect(recurringDrive.stopped, true);
    });
  });

  group('RecurringDrive.toString', () {
    test('transforms a recurring drive to String', () {
      final RecurringDrive recurringDrive = RecurringDriveFactory().generateFake();
      final String string = recurringDrive.toString();
      expect(
        string,
        'RecurringDrive{id: ${recurringDrive.id}, from: ${recurringDrive.start} at ${recurringDrive.startTime}, to: ${recurringDrive.end} at ${recurringDrive.endTime}, by: ${recurringDrive.driverId}, rule: ${recurringDrive.rrule}}',
      );
    });
  });
}
