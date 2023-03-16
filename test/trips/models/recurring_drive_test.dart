import 'package:faker/faker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/trips/models/recurring_drive.dart';
import 'package:motis_mitfahr_app/trips/util/recurrence/recurrence.dart';
import 'package:motis_mitfahr_app/util/extensions/time_of_day_extension.dart';
import 'package:rrule/rrule.dart';

import '../../test_util/factories/drive_factory.dart';
import '../../test_util/factories/profile_factory.dart';
import '../../test_util/factories/recurring_drive_factory.dart';
import '../../test_util/mocks/mock_server.dart';
import '../../test_util/mocks/request_processor.dart';
import '../../test_util/mocks/request_processor.mocks.dart';

void main() {
  final MockRequestProcessor processor = MockRequestProcessor();
  setUp(() async {
    MockServer.setProcessor(processor);
  });

  group('RecurringDrive.fromJson', () {
    test('parses a Chat from json', () {
      final Map<String, dynamic> json = {
        'id': 43,
        'created_at': '2021-01-01T00:00:00.000',
        'start': 'London',
        'start_lat': 2,
        'start_lng': 3,
        'start_time': '22:37:23',
        'destination': 'Berlin',
        'destination_lat': 4,
        'destination_lng': 5,
        'destination_time': '12:47:01',
        'seats': 2,
        'recurrence_rule': 'DTSTART:20230207T234500Z\nRRULE:FREQ=DAILY;UNTIL=20230410T234500Z;INTERVAL=1;WKST=MO',
        'until_field_entered_as_date': true,
        'driver_id': 7,
      };
      final RecurringDrive recurringDrive = RecurringDrive.fromJson(json);
      expect(recurringDrive.id, json['id']);
      expect(recurringDrive.createdAt, DateTime.parse(json['created_at']));
      expect(recurringDrive.start, json['start']);
      expect(recurringDrive.startPosition.lat, json['start_lat']);
      expect(recurringDrive.startPosition.lng, json['start_lng']);
      expect(recurringDrive.startTime, const TimeOfDay(hour: 22, minute: 37));
      expect(recurringDrive.startedAt, DateTime.parse('20230207T234500Z'));
      expect(recurringDrive.recurrenceRule.frequency, Frequency.daily);
      expect(recurringDrive.stoppedAt, json['stopped_at']);
      expect(recurringDrive.driverId, json['driver_id']);
    });

    test('can handle associated models', () {
      final Map<String, dynamic> json = {
        'id': 43,
        'created_at': '2021-01-01T00:00:00.000',
        'start': 'London',
        'start_lat': 2,
        'start_lng': 3,
        'start_time': '22:37:23',
        'destination': 'Berlin',
        'destination_lat': 4,
        'destination_lng': 5,
        'destination_time': '12:47:01',
        'seats': 2,
        'stopped_at': DateTime.now().toString(),
        'recurrence_rule': 'DTSTART:20230207T234500Z\nRRULE:FREQ=DAILY;UNTIL=20230410T234500Z;INTERVAL=1;WKST=MO',
        'until_field_entered_as_date': true,
        'driver_id': 7,
        'driver': ProfileFactory().generateFake().toJsonForApi(),
        'drives': [DriveFactory().generateFake().toJsonForApi(), DriveFactory().generateFake().toJsonForApi()],
      };
      final RecurringDrive recurringDrive = RecurringDrive.fromJson(json);
      expect(recurringDrive.stoppedAt, isNotNull);
      expect(recurringDrive.driver, isNotNull);
      expect(recurringDrive.drives, hasLength(2));
    });
  });

  group('RecurringDrive.fromJsonList', () {
    test('parses a List of recurring drives from json', () {
      final Map<String, dynamic> json = {
        'id': 43,
        'created_at': '2021-01-01T00:00:00.000',
        'start': 'London',
        'start_lat': 2,
        'start_lng': 3,
        'start_time': '22:37:23',
        'destination': 'Berlin',
        'destination_lat': 4,
        'destination_lng': 5,
        'destination_time': '12:47:01',
        'seats': 2,
        'recurrence_rule': 'DTSTART:20230207T234500Z\nRRULE:FREQ=DAILY;UNTIL=20230410T234500Z;INTERVAL=1;WKST=MO',
        'until_field_entered_as_date': true,
        'driver_id': 7,
      };
      final List<RecurringDrive> recurringDrives = RecurringDrive.fromJsonList([json, json, json]);
      expect(recurringDrives.length, 3);
      expect(recurringDrives[0].id, json['id']);
      expect(recurringDrives[2].recurrenceRule.frequency, Frequency.daily);
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
      expect(json['start_time'], recurringDrive.startTime.formatted);
      expect(json['stopped_at'], recurringDrive.stoppedAt?.toString());
      expect(json['recurrence_rule'], contains('\n${recurringDrive.recurrenceRule}'));
      expect(json.keys.length, 13);
    });
  });

  test('RecurringDrive.duration', () {
    final RecurringDrive recurringDrive = RecurringDriveFactory().generateFake();
    expect(recurringDrive.duration, recurringDrive.startTime.getDurationUntil(recurringDrive.destinationTime));
  });

  group('RecurringDrive.recurrenceEndChoice', () {
    test('date', () {
      final RecurrenceRule recurrenceRule = RecurrenceRule(
        frequency: Frequency.daily,
        until: DateTime.now().add(const Duration(days: 1)).toUtc(),
      );
      final RecurringDrive recurringDrive = RecurringDriveFactory()
          .generateFake(recurrenceEndType: RecurrenceEndType.date, recurrenceRule: recurrenceRule);
      expect(recurringDrive.recurrenceEndChoice.type, RecurrenceEndType.date);
      expect((recurringDrive.recurrenceEndChoice as RecurrenceEndChoiceDate).date, recurrenceRule.until);
    });

    group('interval', () {
      test('years', () {
        final DateTime now = DateTime.now();
        final DateTime startedAt = DateTime.utc(now.year, now.month, now.day);
        final int intervalSize = random.integer(10, min: 1);
        final RecurrenceRule recurrenceRule = RecurrenceRule(
          frequency: Frequency.daily,
          until: DateTime.utc(now.year + intervalSize, now.month, now.day),
        );
        final RecurringDrive recurringDrive = RecurringDriveFactory().generateFake(
            recurrenceEndType: RecurrenceEndType.interval, recurrenceRule: recurrenceRule, startedAt: startedAt);
        expect(recurringDrive.recurrenceEndChoice.type, RecurrenceEndType.interval);
        expect((recurringDrive.recurrenceEndChoice as RecurrenceEndChoiceInterval).intervalSize, intervalSize);
        expect(
          (recurringDrive.recurrenceEndChoice as RecurrenceEndChoiceInterval).intervalType,
          RecurrenceIntervalType.years,
        );
      });

      test('months', () {
        final DateTime now = DateTime.now();
        final DateTime startedAt = DateTime.utc(now.year, now.month, now.day);
        //Not divisible by 12
        final int intervalSize = random.integer(10) * 12 + random.integer(12, min: 1);
        final RecurrenceRule recurrenceRule = RecurrenceRule(
          frequency: Frequency.daily,
          until: DateTime.utc(now.year, now.month + intervalSize, now.day),
        );
        final RecurringDrive recurringDrive = RecurringDriveFactory().generateFake(
            recurrenceEndType: RecurrenceEndType.interval, recurrenceRule: recurrenceRule, startedAt: startedAt);
        expect(recurringDrive.recurrenceEndChoice.type, RecurrenceEndType.interval);
        expect((recurringDrive.recurrenceEndChoice as RecurrenceEndChoiceInterval).intervalSize, intervalSize);
        expect(
          (recurringDrive.recurrenceEndChoice as RecurrenceEndChoiceInterval).intervalType,
          RecurrenceIntervalType.months,
        );
      });

      test('weeks', () {
        final DateTime now = DateTime.now();
        final DateTime startedAt = DateTime.utc(now.year, now.month, now.day);
        final int intervalSize = random.integer(10);
        final RecurrenceRule recurrenceRule = RecurrenceRule(
          frequency: Frequency.daily,
          until: DateTime.utc(now.year, now.month, now.day + intervalSize * 7),
        );
        final RecurringDrive recurringDrive = RecurringDriveFactory().generateFake(
            recurrenceEndType: RecurrenceEndType.interval, recurrenceRule: recurrenceRule, startedAt: startedAt);
        expect(recurringDrive.recurrenceEndChoice.type, RecurrenceEndType.interval);
        expect((recurringDrive.recurrenceEndChoice as RecurrenceEndChoiceInterval).intervalSize, intervalSize);
        expect(
          (recurringDrive.recurrenceEndChoice as RecurrenceEndChoiceInterval).intervalType,
          RecurrenceIntervalType.weeks,
        );
      });

      test('days', () {
        final DateTime now = DateTime.now();
        final DateTime startedAt = DateTime.utc(now.year, now.month, now.day, 12);
        //Not divisible by 7
        int intervalSize = random.integer(10) * 7 + random.integer(7, min: 1);
        DateTime until = DateTime.utc(now.year, now.month, now.day + intervalSize, 12);
        //Make sure until is not exactly x months in the future
        while (until.day - startedAt.day == 0) {
          intervalSize = random.integer(10) * 7 + random.integer(7, min: 1);
          until = DateTime.utc(now.year, now.month, now.day + intervalSize, 12);
        }
        final RecurrenceRule recurrenceRule = RecurrenceRule(
          frequency: Frequency.daily,
          until: until,
        );
        final RecurringDrive recurringDrive = RecurringDriveFactory().generateFake(
            recurrenceEndType: RecurrenceEndType.interval, recurrenceRule: recurrenceRule, startedAt: startedAt);
        expect(recurringDrive.recurrenceEndChoice.type, RecurrenceEndType.interval);
        expect((recurringDrive.recurrenceEndChoice as RecurrenceEndChoiceInterval).intervalSize, intervalSize);
        expect(
          (recurringDrive.recurrenceEndChoice as RecurrenceEndChoiceInterval).intervalType,
          RecurrenceIntervalType.days,
        );
      });
    });

    test('occurence', () {
      final RecurrenceRule recurrenceRule = RecurrenceRule(
        frequency: Frequency.daily,
        count: random.integer(10, min: 1),
      );
      final RecurringDrive recurringDrive = RecurringDriveFactory()
          .generateFake(recurrenceEndType: RecurrenceEndType.occurrence, recurrenceRule: recurrenceRule);
      expect(recurringDrive.recurrenceEndChoice.type, RecurrenceEndType.occurrence);
      expect((recurringDrive.recurrenceEndChoice as RecurrenceEndChoiceOccurrence).occurrences, recurrenceRule.count);
    });
  });

  group('RecurringDrive.stop', () {
    test('stoppedAt is set to the given timestamp', () async {
      final RecurringDrive recurringDrive = RecurringDriveFactory().generateFake(createDependencies: false);
      whenRequest(processor).thenReturnJson(recurringDrive.toJsonForApi());

      final DateTime stoppedAt = DateTime.now();
      await recurringDrive.stop(stoppedAt);
      verifyRequest(
        processor,
        urlMatcher: equals('/rest/v1/recurring_drives?id=eq.${recurringDrive.id}'),
        methodMatcher: equals('PATCH'),
        bodyMatcher: equals({
          'stopped_at': stoppedAt.toUtc().toString(),
        }),
      );
      expect(recurringDrive.stoppedAt, stoppedAt);
    });
  });

  group('RecurringDrive.toString', () {
    test('transforms a recurring drive to String', () {
      final RecurringDrive recurringDrive = RecurringDriveFactory().generateFake();
      final String string = recurringDrive.toString();
      expect(
        string,
        'RecurringDrive{id: ${recurringDrive.id}, from: ${recurringDrive.start} at ${recurringDrive.startTime}, to: ${recurringDrive.destination} at ${recurringDrive.destinationTime}, by: ${recurringDrive.driverId}, rule: ${recurringDrive.recurrenceRule}}',
      );
    });
  });
}
