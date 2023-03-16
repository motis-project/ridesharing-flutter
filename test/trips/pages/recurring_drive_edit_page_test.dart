import 'package:clock/clock.dart';
import 'package:faker/faker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:motis_mitfahr_app/trips/models/recurring_drive.dart';
import 'package:motis_mitfahr_app/trips/models/trip.dart';
import 'package:motis_mitfahr_app/trips/pages/recurring_drive_detail_page.dart';
import 'package:motis_mitfahr_app/trips/pages/recurring_drive_edit_page.dart';
import 'package:motis_mitfahr_app/trips/util/recurrence/edit_recurrence_options.dart';
import 'package:motis_mitfahr_app/trips/util/recurrence/recurrence.dart';
import 'package:motis_mitfahr_app/trips/util/recurrence/week_day.dart';
import 'package:motis_mitfahr_app/util/extensions/time_of_day_extension.dart';
import 'package:rrule/rrule.dart';

import '../../test_util/factories/recurring_drive_factory.dart';
import '../../test_util/mocks/mock_server.dart';
import '../../test_util/mocks/request_processor.dart';
import '../../test_util/mocks/request_processor.mocks.dart';
import '../../test_util/pump_material.dart';

void main() {
  final MockRequestProcessor processor = MockRequestProcessor();

  final Finder pageFinder = find.byType(RecurringDriveEditPage);

  late RecurringDrive recurringDrive;

  setUpAll(() {
    MockServer.setProcessor(processor);
  });

  setUp(() {
    recurringDrive = RecurringDriveFactory().generateFake();
    reset(processor);
  });

  Future<void> scrollAndTap(WidgetTester tester, Finder finder, {Finder? scrollable}) async {
    scrollable ??= find.byType(Scrollable).hitTestable().first;
    await tester.scrollUntilVisible(finder, 50, scrollable: scrollable);
    await tester.tap(finder);
    await tester.pump();
  }

  Future<void> enterDate(WidgetTester tester, DateTime dateTime, {required Finder finder}) async {
    await tester.tap(finder, warnIfMissed: false);
    await tester.pump();
    await tester.tap(find.byIcon(Icons.edit), warnIfMissed: false);
    await tester.pump();
    await tester.enterText(find.byType(InputDatePickerFormField), '${dateTime.month}/${dateTime.day}/${dateTime.year}');
    await tester.tap(find.text('OK'), warnIfMissed: false);
    await tester.pump();
  }

  Future<void> selectWeekdays(WidgetTester tester, List<WeekDay> weekdays,
      {required List<WeekDay> selectedWeekdays}) async {
    final List<WeekDay> removedWeekdays = [...weekdays]
      ..removeWhere((WeekDay weekday) => selectedWeekdays.contains(weekday));
    final List<WeekDay> newWeekdays = [...selectedWeekdays]
      ..removeWhere((WeekDay weekday) => weekdays.contains(weekday));
    for (final WeekDay weekday in [...removedWeekdays, ...newWeekdays]) {
      await tester.tap(find.byKey(Key('weekDayButton${weekday.name}')));
      await tester.pump();
    }
  }

  Future<void> enterInterval(WidgetTester tester, int size) async {
    await tester.enterText(find.byKey(const Key('intervalSizeField')), size.toString());
  }

  Future<void> enterUntil(WidgetTester tester, DateTime dateTime, {bool tapEndChoice = false}) async {
    await scrollAndTap(tester, find.byKey(const Key('untilField')));

    if (tapEndChoice) {
      await scrollAndTap(tester, find.byKey(const Key('recurrenceEndChoice0')));
    }

    await tester.scrollUntilVisible(find.byKey(const Key('customEndDateField')), 50,
        scrollable: find.byType(Scrollable).hitTestable().last);

    await enterDate(tester, dateTime, finder: find.byKey(const Key('customEndDateField')));
    await tester.tap(find.byKey(const Key('okButtonRecurrenceEndDialog')));
    await tester.pumpAndSettle();
  }

  group('RecurringDriveEditPage', () {
    testWidgets('EditRecurrenceOptions', (WidgetTester tester) async {
      final List<WeekDay> shuffledWeekdays = [...WeekDay.values]..shuffle();
      final List<WeekDay> weekdays = shuffledWeekdays.take(random.integer(WeekDay.values.length, min: 1)).toList();
      final int intervalSize = random.integer(10, min: 1);
      final DateTime untilDate = faker.date.dateTimeBetween(DateTime.now(), DateTime.now().add(Trip.creationInterval));

      await pumpMaterial(tester, RecurringDriveEditPage(recurringDrive));
      await tester.pump();

      expect(find.byType(EditRecurrenceOptions), findsOneWidget);

      await selectWeekdays(tester, weekdays, selectedWeekdays: recurringDrive.weekDays);
      await enterInterval(tester, intervalSize);
      await enterUntil(tester, untilDate);

      final RecurringDriveEditPageState pageState = tester.state(pageFinder);

      expect(pageState.recurrenceOptions.weekDays.toSet(), weekdays.toSet());
      expect(pageState.recurrenceOptions.recurrenceIntervalSize, intervalSize);
      expect(pageState.recurrenceOptions.endChoice.isCustom, isTrue);
      expect(pageState.recurrenceOptions.endChoice.type, RecurrenceEndType.date);
      expect(
        (pageState.recurrenceOptions.endChoice as RecurrenceEndChoiceDate).date,
        DateTime(untilDate.year, untilDate.month, untilDate.day),
      );
    });

    testWidgets('Interval Size empty', (WidgetTester tester) async {
      await pumpMaterial(tester, RecurringDriveEditPage(recurringDrive));

      await tester.enterText(find.byKey(const Key('intervalSizeField')), '');
      await tester.pump();

      await scrollAndTap(tester, find.byKey(const Key('saveRecurringDriveButton')));
      await tester.pump();

      final FormFieldState intervalSizeField = tester.state(find.byKey(const Key('intervalSizeField')));
      expect(intervalSizeField.hasError, isTrue);
    });

    group('Back button', () {
      setUp(() {
        recurringDrive = RecurringDriveFactory().generateFake(
          startedAt: DateTime.now(),
          recurrenceRule: RecurrenceRule(
            frequency: Frequency.weekly,
            interval: 1,
            byWeekDays: {WeekDay.monday.toByWeekDayEntry()},
            until: DateTime.now().add(Trip.creationInterval).toUtc(),
          ),
        );

        whenRequest(processor).thenReturnJson(recurringDrive.toJsonForApi());
      });

      Future<void> goToEditFromDetailPage(WidgetTester tester) async {
        await pumpMaterial(tester, RecurringDriveDetailPage(id: recurringDrive.id!));
        await tester.pump();

        await tester.tap(find.byIcon(Icons.edit));
        await tester.pumpAndSettle();
      }

      Future<void> makeChanges(WidgetTester tester) async {
        await enterUntil(tester, DateTime.now().add(Trip.creationInterval * 10), tapEndChoice: true);

        await tester.pageBack();
        await tester.pump();

        expect(find.byType(AlertDialog), findsOneWidget);
      }

      testWidgets('Shows no dialog when no changes made', (WidgetTester tester) async {
        await goToEditFromDetailPage(tester);

        await tester.pageBack();
        await tester.pump();

        expect(find.byType(AlertDialog), findsNothing);
        expect(find.byType(RecurringDriveDetailPage), findsOneWidget);
      });

      testWidgets('Can leave dialog when changes were made', (WidgetTester tester) async {
        await goToEditFromDetailPage(tester);

        await makeChanges(tester);

        await tester.tap(find.byKey(const Key('saveChangesLeaveButton')));

        await tester.pumpAndSettle();

        expect(find.byType(RecurringDriveDetailPage), findsOneWidget);
      });

      testWidgets('Can stay on page from dialog when changes were made', (WidgetTester tester) async {
        await goToEditFromDetailPage(tester);

        await makeChanges(tester);

        await tester.tap(find.byKey(const Key('saveChangesStayButton')));

        await tester.pumpAndSettle();

        expect(find.byType(RecurringDriveEditPage), findsOneWidget);
      });
    });

    group('Edit Recurring Drive', () {
      testWidgets('Without cancelled drives', (WidgetTester tester) async {
        final WeekDay addedWeekday = WeekDay.values[random.integer(WeekDay.values.length)];
        final List<WeekDay> weekdaysWithoutAdded = [...WeekDay.values]..remove(addedWeekday);
        weekdaysWithoutAdded.shuffle();
        final List<WeekDay> oldWeekdays =
            weekdaysWithoutAdded.take(random.integer(weekdaysWithoutAdded.length, min: 1)).toList();
        final List<WeekDay> newWeekdays = [...oldWeekdays, addedWeekday];
        final int newIntervalSize = random.integer(5, min: 1);
        final int oldIntervalSize = newIntervalSize * 2;
        final DateTime oldUntilDate =
            faker.date.dateTimeBetween(DateTime.now(), DateTime.now().add(Trip.creationInterval));
        final DateTime oldUntilTime = DateTime(oldUntilDate.year, oldUntilDate.month, oldUntilDate.day, 23, 59).toUtc();
        final DateTime newUntilDate = oldUntilDate.add(Duration(days: random.integer(30)));
        final DateTime newUntilTime = DateTime(newUntilDate.year, newUntilDate.month, newUntilDate.day, 23, 59).toUtc();

        final RecurringDrive recurringDrive = RecurringDriveFactory().generateFake(
          recurrenceRule: RecurrenceRule(
              frequency: Frequency.weekly,
              interval: oldIntervalSize,
              byWeekDays: oldWeekdays.map((WeekDay weekDay) => weekDay.toByWeekDayEntry()).toSet(),
              until: oldUntilTime),
          recurrenceEndType: RecurrenceEndType.date,
        );

        whenRequest(processor).thenReturnJson(recurringDrive.toJsonForApi());

        await pumpMaterial(tester, RecurringDriveEditPage(recurringDrive));
        await tester.pump();

        await selectWeekdays(tester, newWeekdays, selectedWeekdays: oldWeekdays);
        await enterInterval(tester, newIntervalSize);
        await enterUntil(tester, newUntilTime);

        await scrollAndTap(tester, find.byKey(const Key('saveRecurringDriveButton')));
        await tester.pumpAndSettle();

        verifyRequest(processor,
            urlMatcher: equals('/rest/v1/recurring_drives?id=eq.${recurringDrive.id}'),
            methodMatcher: equals('PATCH'),
            bodyMatcher: equals({
              'start': recurringDrive.start,
              'start_lat': recurringDrive.startPosition.lat,
              'start_lng': recurringDrive.startPosition.lng,
              'destination': recurringDrive.destination,
              'destination_lat': recurringDrive.destinationPosition.lat,
              'destination_lng': recurringDrive.destinationPosition.lng,
              'seats': recurringDrive.seats,
              'start_time': recurringDrive.startTime.formatted,
              'destination_time': recurringDrive.destinationTime.formatted,
              'recurrence_rule': PostgresRecurrenceRule(
                      RecurrenceRule(
                          frequency: Frequency.weekly,
                          interval: newIntervalSize,
                          byWeekDays: newWeekdays.map((WeekDay weekDay) => weekDay.toByWeekDayEntry()).toSet(),
                          until: newUntilTime),
                      recurringDrive.startedAt)
                  .toString(),
              'until_field_entered_as_date': true,
              'stopped_at': recurringDrive.stoppedAt,
              'driver_id': recurringDrive.driverId,
            }));
      });

      testWidgets('With cancelled drives', (WidgetTester tester) async {
        final WeekDay addedWeekday = WeekDay.values[random.integer(WeekDay.values.length)];
        final List<WeekDay> weekdaysWithoutAdded = [...WeekDay.values]..remove(addedWeekday);
        weekdaysWithoutAdded.shuffle();
        final List<WeekDay> oldWeekdays =
            weekdaysWithoutAdded.take(random.integer(weekdaysWithoutAdded.length, min: 1)).toList();
        final WeekDay removedWeekday = oldWeekdays[random.integer(oldWeekdays.length)];
        final List<WeekDay> newWeekdays = [...oldWeekdays..remove(removedWeekday), addedWeekday];
        final int oldIntervalSize = random.integer(2, min: 1);
        final int newIntervalSize = oldIntervalSize + 1;
        final DateTime newUntilDate = faker.date
            .dateTimeBetween(DateTime.now().add(Trip.creationInterval), DateTime.now().add(Trip.creationInterval * 2));
        final DateTime newUntilTime = DateTime(newUntilDate.year, newUntilDate.month, newUntilDate.day, 23, 59).toUtc();
        final DateTime oldUntilDate = newUntilDate.add(Duration(days: random.integer(30)));
        final DateTime oldUntilTime = DateTime(oldUntilDate.year, oldUntilDate.month, oldUntilDate.day, 23, 59).toUtc();

        final RecurringDrive recurringDrive = RecurringDriveFactory().generateFake(
          recurrenceRule: RecurrenceRule(
              frequency: Frequency.weekly,
              interval: oldIntervalSize,
              byWeekDays: oldWeekdays.map((WeekDay weekDay) => weekDay.toByWeekDayEntry()).toSet(),
              until: oldUntilTime),
          recurrenceEndType: RecurrenceEndType.date,
        );

        final RecurrenceRule newRecurrenceRule = RecurrenceRule(
            frequency: Frequency.weekly,
            interval: newIntervalSize,
            byWeekDays: newWeekdays.map((WeekDay weekDay) => weekDay.toByWeekDayEntry()).toSet(),
            until: newUntilTime);

        whenRequest(processor).thenReturnJson(recurringDrive.toJsonForApi());

        await pumpMaterial(tester, RecurringDriveEditPage(recurringDrive));
        await tester.pump();

        await selectWeekdays(tester, newWeekdays, selectedWeekdays: oldWeekdays);
        await enterInterval(tester, newIntervalSize);
        await enterUntil(tester, newUntilTime);

        await scrollAndTap(tester, find.byKey(const Key('saveRecurringDriveButton')));
        await tester.pumpAndSettle();

        final List<DateTime> previousInstances =
            recurringDrive.recurrenceRule.getAllInstances(start: DateTime.now().toUtc());
        final List<DateTime> newInstances = newRecurrenceRule.getAllInstances(start: DateTime.now().toUtc());
        final int cancelledDriveCount = previousInstances
            .where((DateTime instance) => instance.isAfter(DateTime.now()) && !newInstances.contains(instance))
            .length;

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.textContaining(RegExp('^.* $cancelledDriveCount .*\$')), findsOneWidget);
        await tester.tap(find.byKey(const Key('changeRecurringDriveNoButton')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('saveRecurringDriveButton')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('changeRecurringDriveYesButton')));
        await tester.pumpAndSettle();

        verifyRequest(processor,
            urlMatcher: equals('/rest/v1/recurring_drives?id=eq.${recurringDrive.id}'),
            methodMatcher: equals('PATCH'),
            bodyMatcher: equals({
              'start': recurringDrive.start,
              'start_lat': recurringDrive.startPosition.lat,
              'start_lng': recurringDrive.startPosition.lng,
              'destination': recurringDrive.destination,
              'destination_lat': recurringDrive.destinationPosition.lat,
              'destination_lng': recurringDrive.destinationPosition.lng,
              'seats': recurringDrive.seats,
              'start_time': recurringDrive.startTime.formatted,
              'destination_time': recurringDrive.destinationTime.formatted,
              'recurrence_rule': PostgresRecurrenceRule(newRecurrenceRule, recurringDrive.startedAt).toString(),
              'until_field_entered_as_date': true,
              'stopped_at': recurringDrive.stoppedAt,
              'driver_id': recurringDrive.driverId,
            }));
      });

      testWidgets('Stop', (WidgetTester tester) async {
        //This is needed in order to know the exact stopped_at time
        final Clock mockTime = Clock.fixed(DateTime.now());

        whenRequest(processor).thenReturnJson(recurringDrive.toJsonForApi());

        await pumpMaterial(tester, RecurringDriveEditPage(recurringDrive, clock: mockTime));
        await tester.pump();

        await scrollAndTap(tester, find.byKey(const Key('stopRecurringDriveButton')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('stopRecurringDriveNoButton')));
        await tester.pumpAndSettle();

        await scrollAndTap(tester, find.byKey(const Key('stopRecurringDriveButton')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('stopRecurringDriveYesButton')));
        await tester.pumpAndSettle();

        verifyRequest(processor,
            urlMatcher: equals('/rest/v1/recurring_drives?id=eq.${recurringDrive.id}'),
            methodMatcher: equals('PATCH'),
            bodyMatcher: equals({
              'stopped_at': mockTime.now().toUtc().toString(),
            }));
      });
    });

    testWidgets('Accessibility', (WidgetTester tester) async {
      await expectMeetsAccessibilityGuidelines(tester, RecurringDriveEditPage(recurringDrive));
    });
  });
}
