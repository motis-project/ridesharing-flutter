import 'package:clock/clock.dart';
import 'package:faker/faker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/managers/supabase_manager.dart';
import 'package:motis_mitfahr_app/search/position.dart';
import 'package:motis_mitfahr_app/trips/models/recurring_drive.dart';
import 'package:motis_mitfahr_app/trips/models/trip.dart';
import 'package:motis_mitfahr_app/trips/pages/create_drive_page.dart';
import 'package:motis_mitfahr_app/trips/util/recurrence/edit_recurrence_options.dart';
import 'package:motis_mitfahr_app/trips/util/recurrence/recurrence.dart';
import 'package:motis_mitfahr_app/trips/util/recurrence/week_day.dart';
import 'package:motis_mitfahr_app/trips/util/trip_timeline.dart';
import 'package:motis_mitfahr_app/util/extensions/time_of_day_extension.dart';
import 'package:rrule/rrule.dart';

import '../../test_util/factories/address_suggestion_factory.dart';
import '../../test_util/factories/drive_factory.dart';
import '../../test_util/factories/profile_factory.dart';
import '../../test_util/factories/recurring_drive_factory.dart';
import '../../test_util/mocks/mock_server.dart';
import '../../test_util/mocks/request_processor.dart';
import '../../test_util/mocks/request_processor.mocks.dart';
import '../../test_util/pump_material.dart';

void main() {
  final MockRequestProcessor processor = MockRequestProcessor();

  final Finder formFinder = find.byType(CreateDriveForm);

  late Profile driver;

  setUpAll(() {
    MockServer.setProcessor(processor);
  });

  setUp(() {
    driver = ProfileFactory().generateFake();
    supabaseManager.currentProfile = driver;
    reset(processor);
  });

  Future<void> scrollAndTap(WidgetTester tester, Finder finder, {Finder? scrollable}) async {
    scrollable ??= find.byType(Scrollable).hitTestable().first;
    await tester.scrollUntilVisible(finder, 50, scrollable: scrollable);
    await tester.tap(finder);
    await tester.pump();
  }

  Future<void> enterStartAndDestination(
    WidgetTester tester, {
    String? startName,
    Position? startPosition,
    String? destinationName,
    Position? destinationPosition,
  }) async {
    final CreateDriveFormState formState = tester.state(formFinder);
    final TripTimeline timeline = find.byType(TripTimeline).evaluate().first.widget as TripTimeline;

    if (startName != null || startPosition != null) {
      startName ??= faker.address.city();
      formState.startController.text = startName;
      timeline.onStartSelected(AddressSuggestionFactory().generateFake(name: startName, position: startPosition));
    }
    if (destinationName != null || destinationPosition != null) {
      destinationName ??= faker.address.city();
      formState.destinationController.text = destinationName;
      timeline.onDestinationSelected(
          AddressSuggestionFactory().generateFake(name: destinationName, position: destinationPosition));
    }
    await tester.pump();
  }

  Future<void> enterDate(WidgetTester tester, DateTime dateTime, {Finder? finder}) async {
    finder ??= find.byKey(const Key('createDriveDatePicker'));
    await tester.tap(finder);
    await tester.pump();
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pump();
    await tester.enterText(find.byType(InputDatePickerFormField), '${dateTime.month}/${dateTime.day}/${dateTime.year}');
    await tester.tap(find.text('OK'));
    await tester.pump();
  }

  Future<void> enterTime(WidgetTester tester, DateTime dateTime) async {
    await tester.tap(find.byKey(const Key('createDriveTimePicker')));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.keyboard));
    await tester.pump();
    final Finder timePicker = find.descendant(of: find.byType(TimePickerDialog), matching: find.byType(TextFormField));
    await tester.enterText(timePicker.first, dateTime.hour.toString());
    await tester.enterText(timePicker.last, dateTime.minute.toString());
    await tester.tap(find.text('OK'));
    await tester.pump();
  }

  Future<void> enterDateAndTime(WidgetTester tester, DateTime dateTime) async {
    await enterDate(tester, dateTime);
    await enterTime(tester, dateTime);
  }

  Future<void> enterSeats(WidgetTester tester, int seats) async {
    for (int i = 1; i < seats; i++) {
      await tester.tap(find.byKey(const Key('increment')));
      await tester.pump();
    }
  }

  Future<void> tapRecurring(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('createDriveRecurringCheckbox')));
    await tester.pump();
  }

  Future<void> selectWeekdays(WidgetTester tester, List<WeekDay> weekdays, {required DateTime selectedDate}) async {
    await tester.tap(find.byKey(Key('weekDayButton${selectedDate.toWeekDay().name}')));
    for (final WeekDay weekday in weekdays) {
      await tester.tap(find.byKey(Key('weekDayButton${weekday.name}')));
      await tester.pump();
    }
  }

  Future<void> enterInterval(WidgetTester tester, int size) async {
    await tester.enterText(find.byKey(const Key('intervalSizeField')), size.toString());
  }

  Future<void> enterUntil(WidgetTester tester, DateTime dateTime) async {
    await scrollAndTap(tester, find.byKey(const Key('untilField')));

    await scrollAndTap(tester, find.byKey(const Key('recurrenceEndChoice4')));

    await enterDate(tester, dateTime, finder: find.byKey(const Key('customEndDateField')));
    await tester.tap(find.byKey(const Key('okButtonRecurrenceEndDialog')));
    await tester.pumpAndSettle();
  }

  group('CreateDrivePage', () {
    group('Input', () {
      group('Normal', () {
        testWidgets('Enter everything', (WidgetTester tester) async {
          final String start = faker.address.city();
          final String destination = faker.address.city();
          final DateTime dateTime = DateTime.now();
          final int seats = faker.randomGenerator.integer(Trip.maxSelectableSeats, min: 1);

          await pumpMaterial(tester, const CreateDrivePage());
          await tester.pump();

          final CreateDriveFormState formState = tester.state(formFinder);

          await enterStartAndDestination(tester, startName: start, destinationName: destination);
          await enterDateAndTime(tester, dateTime);
          await enterSeats(tester, seats);

          expect(formState.startController.text, start);
          expect(formState.destinationController.text, destination);
          expect(formState.selectedDate.year, dateTime.year);
          expect(formState.selectedDate.month, dateTime.month);
          expect(formState.selectedDate.day, dateTime.day);
          expect(formState.seats, seats);
        });

        testWidgets('Omit start or destination', (WidgetTester tester) async {
          final String start = faker.address.city();
          final String destination = faker.address.city();

          await pumpMaterial(tester, const CreateDrivePage());
          await tester.pump();

          final FormFieldState startField = tester.state(find.byKey(const Key('addressFieldStart')));
          final FormFieldState destinationField = tester.state(find.byKey(const Key('addressFieldDestination')));

          final CreateDriveFormState formState = tester.state(formFinder);

          await enterStartAndDestination(tester, startName: '', destinationName: '');

          await tester.tap(find.byKey(const Key('createDriveButton')));
          await tester.pump();

          expect(formState.startController.text, '');
          expect(formState.destinationController.text, '');
          expect(startField.hasError, isTrue);
          expect(destinationField.hasError, isTrue);

          await enterStartAndDestination(tester, startName: start, destinationName: '');

          await tester.tap(find.byKey(const Key('createDriveButton')));
          await tester.pump();

          expect(formState.startController.text, start);
          expect(formState.destinationController.text, '');
          expect(startField.hasError, isFalse);
          expect(destinationField.hasError, isTrue);

          await enterStartAndDestination(tester, startName: '', destinationName: destination);

          await tester.tap(find.byKey(const Key('createDriveButton')));
          await tester.pump();

          expect(formState.startController.text, '');
          expect(formState.destinationController.text, destination);
          expect(startField.hasError, isTrue);
          expect(destinationField.hasError, isFalse);
        });

        testWidgets('Impossible time', (WidgetTester tester) async {
          final DateTime now = DateTime.now();
          //This is needed because it's impossible to try to select an impossible time at 00:00
          final DateTime mockTime =
              DateTime(now.year, now.month, now.day + 1, random.integer(24, min: 1), random.integer(60));
          final DateTime dateTime = mockTime.subtract(const Duration(minutes: 1));

          await pumpMaterial(tester, CreateDrivePage(clock: Clock.fixed(mockTime)));
          await tester.pump();

          await enterDateAndTime(tester, dateTime);

          await tester.tap(find.byKey(const Key('createDriveButton')));
          await tester.pump();

          final FormFieldState timeField = tester.state(find.byKey(const Key('createDriveTimePicker')));
          expect(timeField.hasError, isTrue);
        });
      });

      testWidgets('EditRecurrenceOptions', (WidgetTester tester) async {
        final List<WeekDay> shuffledWeekdays = [...WeekDay.values]..shuffle();
        final List<WeekDay> weekdays = shuffledWeekdays.take(random.integer(WeekDay.values.length, min: 1)).toList();
        final int intervalSize = random.integer(10, min: 1);
        final DateTime dateTime = faker.date.dateTimeBetween(DateTime.now(), DateTime.now().add(Trip.creationInterval));

        await pumpMaterial(tester, const CreateDrivePage());
        await tester.pump();

        expect(find.byType(EditRecurrenceOptions), findsNothing);

        await tapRecurring(tester);

        expect(find.byType(EditRecurrenceOptions), findsOneWidget);

        await selectWeekdays(tester, weekdays, selectedDate: DateTime.now());
        await enterInterval(tester, intervalSize);
        await enterUntil(tester, dateTime);

        final CreateDriveFormState formState = tester.state(formFinder);

        expect(formState.recurrenceOptions.weekDays, weekdays);
        expect(formState.recurrenceOptions.recurrenceIntervalSize, intervalSize);
        expect(formState.recurrenceOptions.endChoice.isCustom, isTrue);
        expect(formState.recurrenceOptions.endChoice.type, RecurrenceEndType.date);
        expect(
          (formState.recurrenceOptions.endChoice as RecurrenceEndChoiceDate).date,
          DateTime(dateTime.year, dateTime.month, dateTime.day),
        );
      });

      testWidgets('Interval Size empty', (WidgetTester tester) async {
        await pumpMaterial(tester, const CreateDrivePage());

        await tapRecurring(tester);

        await tester.enterText(find.byKey(const Key('intervalSizeField')), '');
        await tester.pump();

        await scrollAndTap(tester, find.byKey(const Key('createDriveButton')));
        await tester.pump();

        final FormFieldState intervalSizeField = tester.state(find.byKey(const Key('intervalSizeField')));
        expect(intervalSizeField.hasError, isTrue);
      });
    });

    group('Create drive', () {
      testWidgets('Normal', (WidgetTester tester) async {
        final String startName = faker.address.city();
        final Position startPosition = Position(faker.geo.latitude(), faker.geo.longitude());
        final String destinationName = faker.address.city();
        final Position destinationPosition = Position(faker.geo.latitude(), faker.geo.longitude());
        final DateTime dateTime = DateTime.now().add(const Duration(minutes: 5));
        final int seats = faker.randomGenerator.integer(Trip.maxSelectableSeats, min: 1);

        whenRequest(processor).thenReturnJson(DriveFactory()
            .generateFake(
              driverId: driver.id,
              start: startName,
              startPosition: startPosition,
              destination: destinationName,
              destinationPosition: destinationPosition,
              seats: seats,
              startDateTime: dateTime,
              destinationDateTime: dateTime.add(const Duration(hours: 2)),
            )
            .toJsonForApi());

        await pumpMaterial(tester, const CreateDrivePage());
        await tester.pump();

        await enterStartAndDestination(
          tester,
          startName: startName,
          startPosition: startPosition,
          destinationName: destinationName,
          destinationPosition: destinationPosition,
        );
        await enterDateAndTime(tester, dateTime);
        await enterSeats(tester, seats);

        await tester.tap(find.byKey(const Key('createDriveButton')));
        await tester.pumpAndSettle();

        verifyRequest(
          processor,
          urlMatcher: equals('/rest/v1/drives?select=%2A'),
          methodMatcher: equals('POST'),
          bodyMatcher: equals({
            'start': startName,
            'start_lat': startPosition.lat,
            'start_lng': startPosition.lng,
            'destination': destinationName,
            'destination_lat': destinationPosition.lat,
            'destination_lng': destinationPosition.lng,
            'seats': seats,
            'start_date_time': isA<String>(),
            'destination_date_time': isA<String>(),
            'hide_in_list_view': false,
            'status': 1,
            'driver_id': driver.id,
            'recurring_drive_id': null,
          }),
        );
      });

      testWidgets('Recurring', (WidgetTester tester) async {
        final String startName = faker.address.city();
        final Position startPosition = Position(faker.geo.latitude(), faker.geo.longitude());
        final String destinationName = faker.address.city();
        final Position destinationPosition = Position(faker.geo.latitude(), faker.geo.longitude());
        final DateTime now = DateTime.now();
        final DateTime dateTime = DateTime(now.year, now.month, now.day, now.hour, now.minute);
        final int seats = faker.randomGenerator.integer(Trip.maxSelectableSeats, min: 1);

        final List<WeekDay> shuffledWeekdays = [...WeekDay.values]..shuffle();
        final List<WeekDay> weekdays = shuffledWeekdays.take(random.integer(WeekDay.values.length, min: 1)).toList();
        final int intervalSize = random.integer(10, min: 1);
        final DateTime untilDate =
            faker.date.dateTimeBetween(DateTime.now(), DateTime.now().add(Trip.creationInterval));
        final DateTime untilTime = DateTime(untilDate.year, untilDate.month, untilDate.day, 23, 59).toUtc();

        final RecurrenceRule recurrenceRule = RecurrenceRule(
          frequency: Frequency.weekly,
          interval: intervalSize,
          byWeekDays: weekdays.map((WeekDay weekDay) => weekDay.toByWeekDayEntry()).toSet(),
          until: untilTime,
        );

        whenRequest(processor).thenReturnJson(RecurringDriveFactory()
            .generateFake(
                driverId: driver.id,
                start: startName,
                startPosition: startPosition,
                destination: destinationName,
                destinationPosition: destinationPosition,
                seats: seats,
                startedAt: dateTime,
                startTime: TimeOfDay.fromDateTime(dateTime),
                destinationTime: TimeOfDay.fromDateTime(dateTime.add(const Duration(hours: 2))),
                recurrenceRule: recurrenceRule,
                recurrenceEndType: RecurrenceEndType.date)
            .toJsonForApi());

        await pumpMaterial(tester, const CreateDrivePage());
        await tester.pump();

        await enterStartAndDestination(
          tester,
          startName: startName,
          startPosition: startPosition,
          destinationName: destinationName,
          destinationPosition: destinationPosition,
        );
        await enterDateAndTime(tester, dateTime);
        await enterSeats(tester, seats);

        await tapRecurring(tester);

        await selectWeekdays(tester, weekdays, selectedDate: dateTime);
        await enterInterval(tester, intervalSize);
        await enterUntil(tester, untilTime);

        await tester.tap(find.byKey(const Key('createDriveButton')));
        await tester.pump();

        verifyRequest(processor,
            urlMatcher: equals('/rest/v1/recurring_drives?select=%2A'),
            methodMatcher: equals('POST'),
            bodyMatcher: equals({
              'start': startName,
              'start_lat': startPosition.lat,
              'start_lng': startPosition.lng,
              'destination': destinationName,
              'destination_lat': destinationPosition.lat,
              'destination_lng': destinationPosition.lng,
              'seats': seats,
              'start_time': TimeOfDay.fromDateTime(dateTime).formatted,
              'destination_time': TimeOfDay.fromDateTime(dateTime.add(const Duration(hours: 2))).formatted,
              'recurrence_rule': PostgresRecurrenceRule(recurrenceRule, dateTime).toString(),
              'until_field_entered_as_date': true,
              'stopped_at': null,
              'driver_id': driver.id,
            }));
      });
    });

    testWidgets('Accessibility', (WidgetTester tester) async {
      await expectMeetsAccessibilityGuidelines(tester, const CreateDrivePage());
    });
  });
}
