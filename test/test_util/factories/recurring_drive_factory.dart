import 'package:flutter/material.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/search/position.dart';
import 'package:motis_mitfahr_app/trips/models/drive.dart';
import 'package:motis_mitfahr_app/trips/models/recurring_drive.dart';
import 'package:motis_mitfahr_app/trips/models/trip.dart';
import 'package:motis_mitfahr_app/trips/util/recurrence/recurrence.dart';
import 'package:motis_mitfahr_app/util/extensions/time_of_day_extension.dart';
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
    String? destination,
    Position? destinationPosition,
    TimeOfDay? destinationTime,
    int? seats,
    DateTime? startedAt,
    RecurrenceRule? recurrenceRule,
    RecurrenceEndType? recurrenceEndType,
    DateTime? stoppedAt,
    int? driverId,
    NullableParameter<Profile>? driver,
    List<Drive>? drives,
    bool createDependencies = true,
  }) {
    assert(driverId == null || driver?.value == null || driver!.value?.id == driverId);

    final int generatedId = id ?? randomId;

    final Profile? generatedDriver = getNullableParameterOr(
      driver,
      ProfileFactory().generateFake(
        id: driverId,
        createDependencies: false,
      ),
    );
    final generatedDriverId = generatedDriver?.id ?? driverId ?? randomId;

    final generatedCreatedAt = createdAt ?? DateTime.now();
    final generatedStartPosition = startPosition ?? Position(faker.geo.latitude(), faker.geo.longitude());
    final generatedDestinationPosition = destinationPosition ?? Position(faker.geo.latitude(), faker.geo.longitude());
    final generatedStartedAt = startedAt ?? generatedCreatedAt;
    final generatedStartTime = startTime ?? TimeOfDay.fromDateTime(faker.date.dateTime());
    final generatedDestinationTime = destinationTime ?? TimeOfDay.fromDateTime(faker.date.dateTime());
    final generatedRecurrenceEndType = recurrenceEndType ?? RecurrenceEndType.date;

    final RecurrenceRule generatedRecurrenceRule = recurrenceRule ??
        RecurrenceRule(
          frequency: Frequency.weekly,
          interval: 1,
          until: generatedRecurrenceEndType == RecurrenceEndType.occurrence
              ? null
              : generatedStartedAt.add(Trip.creationInterval).toUtc(),
          count: generatedRecurrenceEndType == RecurrenceEndType.occurrence ? 10 : null,
          byWeekDays: (List<int>.generate(7, (index) => index)..shuffle())
              .take(random.nextInt(7))
              .map((day) => ByWeekDayEntry(day + 1))
              .toSet(),
        );

    final List<Drive>? generatedDrives = drives ??
        (createDependencies
            ? generatedRecurrenceRule
                .getInstances(
                  start: generatedStartedAt.toUtc(),
                  before: DateTime.now().add(Trip.creationInterval).toUtc(),
                  includeAfter: true,
                  includeBefore: true,
                )
                .map<Drive>((DateTime startDate) => DriveFactory().generateFake(
                      start: start,
                      startPosition: generatedStartPosition,
                      startDateTime: DateTime(
                        startDate.year,
                        startDate.month,
                        startDate.day,
                        generatedStartTime.hour,
                        generatedStartTime.minute,
                      ),
                      destination: destination,
                      destinationPosition: generatedDestinationPosition,
                      destinationDateTime: DateTime(
                        startDate.year,
                        startDate.month,
                        generatedStartTime.isBefore(generatedDestinationTime) ? startDate.day : startDate.day + 1,
                        generatedDestinationTime.hour,
                        generatedDestinationTime.minute,
                      ),
                      seats: seats,
                      driverId: generatedDriverId,
                      driver: NullableParameter(generatedDriver),
                      // Setting to null to avoid infinite recursion
                      recurringDrive: NullableParameter(null),
                      recurringDriveId: NullableParameter(generatedId),
                      createDependencies: false,
                    ))
                .toList()
            : null);

    return RecurringDrive(
      id: generatedId,
      createdAt: generatedCreatedAt,
      start: start ?? faker.address.city(),
      startPosition: generatedStartPosition,
      startTime: generatedStartTime,
      destination: destination ?? faker.address.city(),
      destinationPosition: generatedDestinationPosition,
      destinationTime: generatedDestinationTime,
      seats: seats ?? random.nextInt(5) + 1,
      startedAt: generatedStartedAt,
      recurrenceRule: generatedRecurrenceRule,
      recurrenceEndType: generatedRecurrenceEndType,
      stoppedAt: stoppedAt,
      driverId: generatedDriverId,
      driver: generatedDriver,
      drives: generatedDrives,
    );
  }
}
