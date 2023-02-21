import 'package:clock/clock.dart';
import 'package:faker/faker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/drives/pages/create_drive_page.dart';
import 'package:motis_mitfahr_app/drives/util/recurrence.dart';
import 'package:motis_mitfahr_app/drives/util/week_day.dart';
import 'package:motis_mitfahr_app/util/search/position.dart';
import 'package:motis_mitfahr_app/util/search/start_destination_timeline.dart';
import 'package:motis_mitfahr_app/util/supabase_manager.dart';
import 'package:motis_mitfahr_app/util/trip/trip.dart';

import '../util/factories/address_suggestion_factory.dart';
import '../util/factories/drive_factory.dart';
import '../util/factories/profile_factory.dart';
import '../util/mocks/mock_server.dart';
import '../util/mocks/request_processor.dart';
import '../util/mocks/request_processor.mocks.dart';
import '../util/pump_material.dart';

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
    print(scrollable);
    await tester.scrollUntilVisible(finder.hitTestable(), 50, scrollable: scrollable);
    await tester.tap(finder.hitTestable());
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
    final StartDestinationTimeline timeline =
        find.byType(StartDestinationTimeline).evaluate().first.widget as StartDestinationTimeline;

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

  Future<void> selectWeekdays(WidgetTester tester, List<WeekDay> weekdays) async {
    await tester.tap(find.byKey(Key('weekDayButton${DateTime.now().toWeekDay().name}')));
    for (final WeekDay weekday in weekdays) {
      await tester.tap(find.byKey(Key('weekDayButton${weekday.name}')));
      await tester.pump();
    }
  }

  Future<void> enterInterval(WidgetTester tester, int size, RecurrenceIntervalType type) async {
    await tester.enterText(find.byKey(const Key('intervalSizeField')), size.toString());

    await scrollAndTap(tester, find.byKey(const Key('intervalTypeField')));
    await tester.pump();
    await scrollAndTap(tester, find.byKey(Key('intervalType${type.name}')), scrollable: find.byType(Scrollable).first);
    await tester.pump();
  }

  Future<void> enterUntil(WidgetTester tester, DateTime dateTime) async {
    await scrollAndTap(tester, find.byKey(const Key('untilField')));

    await scrollAndTap(tester, find.byKey(const Key('recurrenceEndChoice4')));

    await enterDate(tester, dateTime, finder: find.byKey(const Key('customEndDateField')));
    await tester.tap(find.byKey(const Key('okButtonRecurrenceEndDialog')));
    await tester.pump();
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
      testWidgets('Recurring', (WidgetTester tester) async {
        final List<WeekDay> weekdays = [...WeekDay.values]
          ..shuffle()
          ..sublist(random.integer(WeekDay.values.length, min: 1));
        final int intervalSize = random.integer(10, min: 1);
        final RecurrenceIntervalType intervalType =
            RecurrenceIntervalType.values[random.integer(RecurrenceIntervalType.values.length)];

        await pumpMaterial(tester, const CreateDrivePage());
        await tester.pump();

        final CreateDriveFormState formState = tester.state(formFinder);

        await tapRecurring(tester);

        await selectWeekdays(tester, weekdays);
        await enterInterval(tester, intervalSize, intervalType);

        expect(formState.recurrenceOptions.weekDays, weekdays);
        expect(formState.recurrenceOptions.recurrenceIntervalSizeController.text, intervalSize.toString());
        expect(formState.recurrenceOptions.recurrenceInterval.intervalSize, intervalSize);
        expect(formState.recurrenceOptions.recurrenceInterval.intervalType, intervalType);

        //for (int i = 0; i < 4; i++) {
        //  print(find.byKey(Key('predefinedEndChoice$i')));
        //}
        await tester.scrollUntilVisible(find.byKey(const Key('untilField')), 50,
            scrollable: find.byType(Scrollable).hitTestable().first);
        final Finder scrollable =
            find.descendant(of: find.byType(Dialog), matching: find.byType(Scrollable).hitTestable());
        for (int i = 0; i < 4; i++) {
          print(i);
          await tester.tap(find.byKey(const Key('untilField')));
          print(find.descendant(of: find.byType(Dialog), matching: find.byType(Scrollable).hitTestable()));

          print('A');

          await scrollAndTap(tester, find.byKey(Key('predefinedEndChoice$i')), scrollable: scrollable);

          print('B');
          await tester.tap(find.byKey(const Key('okButtonRecurrenceEndDialog')));
          await tester.pump();
          expect(formState.recurrenceOptions.endChoice.isCustom, isFalse);
          expect(formState.recurrenceOptions.endChoice.type, RecurrenceEndType.interval);
          expect((formState.recurrenceOptions.endChoice as RecurrenceEndChoiceInterval).intervalSize,
              (CreateDriveFormState.predefinedRecurrenceEndChoices[i] as RecurrenceEndChoiceInterval).intervalSize);
          expect((formState.recurrenceOptions.endChoice as RecurrenceEndChoiceInterval).intervalType,
              (CreateDriveFormState.predefinedRecurrenceEndChoices[i] as RecurrenceEndChoiceInterval).intervalType);
        }

        final DateTime dateTime =
            faker.date.dateTimeBetween(DateTime.now(), DateTime.now().add(const Duration(days: 30)));
        enterUntil(tester, dateTime);
        expect(formState.recurrenceOptions.endChoice.isCustom, isTrue);
        expect(formState.recurrenceOptions.endChoice.type, RecurrenceEndType.date);
        expect((formState.recurrenceOptions.endChoice as RecurrenceEndChoiceDate).date, dateTime);

        final int endIntervalSize = random.integer(16, min: 1);
        final RecurrenceIntervalType endIntervalType =
            RecurrenceIntervalType.values[random.integer(RecurrenceIntervalType.values.length)];
        await tester.tap(find.byKey(const Key('untilField')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('recurrenceEndChoice5')));
        await tester.pump();
        await tester.enterText(find.byKey(const Key('customEndIntervalSizeField')), endIntervalSize.toString());
        await tester.tap(find.byKey(const Key('customEndIntervalTypeField')));
        await tester.pump();
        await tester.tap(find.byKey(Key('customEndIntervalType${endIntervalType.name}')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('okButtonRecurrenceEndDialog')));
        await tester.pump();
        expect(formState.recurrenceOptions.endChoice.isCustom, isTrue);
        expect(formState.recurrenceOptions.endChoice.type, RecurrenceEndType.interval);
        expect((formState.recurrenceOptions.endChoice as RecurrenceEndChoiceInterval).intervalSize, endIntervalSize);
        expect((formState.recurrenceOptions.endChoice as RecurrenceEndChoiceInterval).intervalType, endIntervalType);

        final int occurenceCount = random.integer(16, min: 1);
        await tester.tap(find.byKey(const Key('untilField')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('recurrenceEndChoice6')));
        await tester.pump();
        await tester.enterText(find.byKey(const Key('customEndOccurenceField')), occurenceCount.toString());
        await tester.tap(find.byKey(const Key('okButtonRecurrenceEndDialog')));
        await tester.pump();
        expect(formState.recurrenceOptions.endChoice.isCustom, isTrue);
        expect(formState.recurrenceOptions.endChoice.type, RecurrenceEndType.occurrence);
        expect((formState.recurrenceOptions.endChoice as RecurrenceEndChoiceOccurrence).occurrences, occurenceCount);
      });
    });

    group('Create drive', () {
      testWidgets('Normal', (WidgetTester tester) async {
        final String startName = faker.address.city();
        final Position startPosition = Position(faker.geo.latitude(), faker.geo.longitude());
        final String destinationName = faker.address.city();
        final Position destinationPosition = Position(faker.geo.latitude(), faker.geo.longitude());
        final DateTime now = DateTime.now();
        final DateTime dateTime = DateTime(now.year, now.month, now.day, now.hour, now.minute);
        final int seats = faker.randomGenerator.integer(Trip.maxSelectableSeats, min: 1);

        whenRequest(processor).thenReturnJson(DriveFactory()
            .generateFake(
              driverId: driver.id,
              start: startName,
              startPosition: startPosition,
              end: destinationName,
              endPosition: destinationPosition,
              seats: seats,
              startDateTime: dateTime,
              endDateTime: dateTime.add(const Duration(hours: 2)),
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

        /*print({
          'start': startName,
          'start_lat': startPosition.lat,
          'start_lng': startPosition.lng,
          'end': destinationName,
          'end_lat': destinationPosition.lat,
          'end_lng': destinationPosition.lng,
          'seats': seats,
          'start_time': dateTime,
          'end_time': DateTime(dateTime.year, dateTime.month, dateTime.day, dateTime.hour + 2, dateTime.minute),
          'hide_in_list_view': false,
          'status': 0,
          'driver_id': driver.id,
          'recurring_drive_id': null,
        });*/

        /*{start: Lowellfurt, start_lat: -80.80548618832307, start_lng: 74.95284689119251, end: 
Lavernshire, end_lat: 50.23839973894488, end_lng: -47.14285526053624, seats: 7, start_time: 
2023-02-19 22:22:00.000, end_time: 2023-02-20 00:22:00.000, hide_in_list_view: false, status: 0, 
driver_id: 550822, recurring_drive_id: null}

        {start: Lowellfurt, start_lat: -80.80548618832307, start_lng: 74.95284689119251, end:
Lavernshire, end_lat: 50.23839973894488, end_lng: -47.14285526053624, seats: 7, start_time:
2023-02-19 22:22:00.000, end_time: 2023-02-20 00:22:00.000, hide_in_list_view: false, status: 0,
driver_id: 550822, recurring_drive_id: null}*/

        verifyRequest(
          processor,
          urlMatcher: equals('/rest/v1/drives?select=%2A'),
          methodMatcher: equals('POST'),
          bodyMatcher: equals({
            'start': startName,
            'start_lat': startPosition.lat,
            'start_lng': startPosition.lng,
            'end': destinationName,
            'end_lat': destinationPosition.lat,
            'end_lng': destinationPosition.lng,
            'seats': seats,
            'start_time': dateTime,
            'end_time': DateTime(dateTime.year, dateTime.month, dateTime.day, dateTime.hour + 2, dateTime.minute),
            'hide_in_list_view': false,
            'status': 0,
            'driver_id': driver.id,
            'recurring_drive_id': null,
          }),
        );
      });

      group('Recurring', () {});
    });
  });
}
