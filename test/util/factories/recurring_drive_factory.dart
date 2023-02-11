import 'package:flutter/material.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/drives/models/drive.dart';
import 'package:motis_mitfahr_app/drives/models/recurring_drive.dart';
import 'package:motis_mitfahr_app/util/search/position.dart';
import 'package:rrule/rrule.dart';

import 'drive_factory.dart';
import 'model_factory.dart';
import 'profile_factory.dart';

class RecurringDriveFactory extends ModelFactory<RecurringDrive> {
  @override
  RecurringDrive generateFake({
    int? id,
    DateTime? createdAt,
    String? start,
    Position? startPosition,
    TimeOfDay? startTime,
    String? end,
    Position? endPosition,
    TimeOfDay? endTime,
    int? seats,
    DateTime? startedAt,
    RecurrenceRule? recurrenceRule,
    DateTime? stoppedAt,
    int? driverId,
    NullableParameter<Profile>? driver,
    List<Drive>? drives,
    bool createDependencies = true,
  }) {
    assert(driverId == null || driver?.value == null || driver!.value?.id == driverId);

    final Profile? generatedDriver = getNullableParameterOr(
        driver,
        ProfileFactory().generateFake(
          id: driverId,
          createDependencies: false,
        ));
    final generatedDriverId = generatedDriver?.id ?? driverId ?? randomId;

    final generatedCreatedAt = createdAt ?? DateTime.now();
    final generatedStartTime = startTime ?? TimeOfDay.fromDateTime(faker.date.dateTime());
    final generatedEndTime = endTime ?? TimeOfDay.fromDateTime(faker.date.dateTime());

    final RecurrenceRule generatedRecurrenceRule = recurrenceRule ??
        RecurrenceRule(
          frequency: Frequency.weekly,
          interval: 1,
          until: generatedCreatedAt.add(const Duration(days: 30)).toUtc(),
          byWeekDays: (List<int>.generate(7, (index) => index)..shuffle())
              .take(random.nextInt(7))
              .map((day) => ByWeekDayEntry(day + 1))
              .toSet(),
        );

    final List<Drive>? generatedDrives = drives ??
        (createDependencies
            ? generatedRecurrenceRule
                .getInstances(
                  start: generatedCreatedAt.toUtc(),
                  includeAfter: true,
                  includeBefore: true,
                )
                .map<Drive>((DateTime startDate) => DriveFactory().generateFake(
                      start: start,
                      startPosition: startPosition,
                      startTime: DateTime(
                        startDate.year,
                        startDate.month,
                        startDate.day,
                        generatedStartTime.hour,
                        generatedEndTime.hour,
                      ),
                      end: end,
                      endPosition: endPosition ?? Position(faker.geo.latitude(), faker.geo.longitude()),
                      endTime: DateTime(
                        startDate.year,
                        startDate.month,
                        generatedStartTime.isBefore(generatedEndTime) ? startDate.day : startDate.day + 1,
                        generatedEndTime.hour,
                        generatedEndTime.minute,
                      ),
                      seats: seats,
                      driverId: generatedDriverId,
                      driver: NullableParameter(generatedDriver),
                      createDependencies: false,
                    ))
                .toList()
            : null);

    return RecurringDrive(
      id: id ?? randomId,
      createdAt: generatedCreatedAt,
      start: start ?? faker.address.city(),
      startPosition: startPosition ?? Position(faker.geo.latitude(), faker.geo.longitude()),
      startTime: generatedStartTime,
      end: end ?? faker.address.city(),
      endPosition: endPosition ?? Position(faker.geo.latitude(), faker.geo.longitude()),
      endTime: generatedEndTime,
      seats: seats ?? random.nextInt(5) + 1,
      startedAt: startedAt ?? generatedCreatedAt,
      recurrenceRule: generatedRecurrenceRule,
      stoppedAt: stoppedAt,
      driverId: generatedDriverId,
      driver: generatedDriver,
      drives: generatedDrives,
    );
  }
}

extension TimeOfDayComparison on TimeOfDay {
  bool isBefore(TimeOfDay other) {
    return hour < other.hour || (hour == other.hour && minute < other.minute);
  }

  bool isAfter(TimeOfDay other) {
    return hour > other.hour || (hour == other.hour && minute > other.minute);
  }

  bool isAtSameMomentAs(TimeOfDay other) {
    return hour == other.hour && minute == other.minute;
  }
}
