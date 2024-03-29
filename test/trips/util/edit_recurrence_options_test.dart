import 'package:faker/faker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:motis_mitfahr_app/trips/models/trip.dart';
import 'package:motis_mitfahr_app/trips/pages/create_drive_page.dart';
import 'package:motis_mitfahr_app/trips/util/recurrence/edit_recurrence_options.dart';
import 'package:motis_mitfahr_app/trips/util/recurrence/recurrence.dart';
import 'package:motis_mitfahr_app/trips/util/recurrence/week_day.dart';

import '../../test_util/mocks/mock_server.dart';
import '../../test_util/mocks/request_processor.mocks.dart';
import '../../test_util/pump_material.dart';

void main() {
  final MockRequestProcessor processor = MockRequestProcessor();

  final Finder widgetFinder = find.byType(EditRecurrenceOptions);

  final List<RecurrenceEndChoice> predefinedEndChoices = <RecurrenceEndChoice>[
    RecurrenceEndChoiceInterval(1, RecurrenceIntervalType.months),
    RecurrenceEndChoiceInterval(3, RecurrenceIntervalType.months),
    RecurrenceEndChoiceInterval(6, RecurrenceIntervalType.months),
    RecurrenceEndChoiceInterval(1, RecurrenceIntervalType.years),
  ];
  late RecurrenceOptions recurrenceOptions;

  setUpAll(() {
    MockServer.setProcessor(processor);
  });

  setUp(() {
    recurrenceOptions = RecurrenceOptions(
        startedAt: DateTime.now(),
        recurrenceIntervalSize: random.integer(4, min: 1),
        endChoice: predefinedEndChoices[random.integer(predefinedEndChoices.length)]);
    reset(processor);
  });

  Future<void> scrollAndTap(WidgetTester tester, Finder finder, {Finder? scrollable}) async {
    scrollable ??= find.byType(Scrollable).hitTestable().first;
    await tester.scrollUntilVisible(finder, 50, scrollable: scrollable);
    await tester.tap(finder);
    await tester.pump();
  }

  Future<void> enterDate(WidgetTester tester, DateTime dateTime, {required Finder finder}) async {
    await tester.tap(finder);
    await tester.pump();
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pump();
    await tester.enterText(find.byType(InputDatePickerFormField), '${dateTime.month}/${dateTime.day}/${dateTime.year}');
    await tester.tap(find.text('OK'));
    await tester.pump();
  }

  Future<void> selectWeekdays(WidgetTester tester, List<WeekDay> weekdays) async {
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

  group('EditRecurrenceOptions', () {
    group('Input', () {
      testWidgets('Week Days', (WidgetTester tester) async {
        final List<WeekDay> shuffledWeekdays = [...WeekDay.values]..shuffle();
        final List<WeekDay> weekdays = shuffledWeekdays.take(random.integer(WeekDay.values.length, min: 1)).toList();

        await pumpScaffold(tester,
            EditRecurrenceOptions(recurrenceOptions: recurrenceOptions, predefinedEndChoices: predefinedEndChoices));
        await tester.pump();

        final EditRecurrenceOptionsState pageState = tester.state(widgetFinder);

        await selectWeekdays(tester, weekdays);

        expect(pageState.recurrenceOptions.weekDays, weekdays);
      });

      testWidgets('Interval', (WidgetTester tester) async {
        await pumpScaffold(
          tester,
          EditRecurrenceOptions(recurrenceOptions: recurrenceOptions, predefinedEndChoices: predefinedEndChoices),
        );
        await tester.pump();

        final EditRecurrenceOptionsState pageState = tester.state(widgetFinder);

        final int intervalSize = random.integer(10, min: 1);
        await enterInterval(tester, intervalSize);

        expect(pageState.recurrenceIntervalSizeController.text, intervalSize.toString());
        expect(pageState.recurrenceOptions.recurrenceIntervalSize, intervalSize);
      });

      group('Until', () {
        testWidgets('Predefined End Choices', (WidgetTester tester) async {
          await pumpScaffold(
            tester,
            EditRecurrenceOptions(recurrenceOptions: recurrenceOptions, predefinedEndChoices: predefinedEndChoices),
          );
          await tester.pump();

          final EditRecurrenceOptionsState pageState = tester.state(widgetFinder);

          final Finder scrollable = find.descendant(of: find.byType(Dialog), matching: find.byType(Scrollable));

          for (int i = 0; i < 4; i++) {
            await tester.tap(find.byKey(const Key('untilField')));
            await tester.pumpAndSettle();

            await scrollAndTap(tester, find.byKey(Key('predefinedEndChoice$i')), scrollable: scrollable.first);
            await tester.tap(find.byKey(const Key('okButtonRecurrenceEndDialog')));
            await tester.pumpAndSettle();
            expect(pageState.recurrenceOptions.endChoice.isCustom, isFalse);
            expect(pageState.recurrenceOptions.endChoice.type, RecurrenceEndType.interval);
            expect((pageState.recurrenceOptions.endChoice as RecurrenceEndChoiceInterval).intervalSize,
                (CreateDriveFormState.predefinedRecurrenceEndChoices[i] as RecurrenceEndChoiceInterval).intervalSize);
            expect((pageState.recurrenceOptions.endChoice as RecurrenceEndChoiceInterval).intervalType,
                (CreateDriveFormState.predefinedRecurrenceEndChoices[i] as RecurrenceEndChoiceInterval).intervalType);
          }
        });

        testWidgets('Date', (WidgetTester tester) async {
          await pumpScaffold(
            tester,
            EditRecurrenceOptions(recurrenceOptions: recurrenceOptions, predefinedEndChoices: predefinedEndChoices),
          );
          await tester.pump();

          final EditRecurrenceOptionsState pageState = tester.state(widgetFinder);

          final DateTime dateTime =
              faker.date.dateTimeBetween(DateTime.now(), DateTime.now().add(Trip.creationInterval));
          await enterUntil(tester, dateTime);
          expect(pageState.recurrenceOptions.endChoice.isCustom, isTrue);
          expect(pageState.recurrenceOptions.endChoice.type, RecurrenceEndType.date);
          expect(
            (pageState.recurrenceOptions.endChoice as RecurrenceEndChoiceDate).date,
            DateTime(dateTime.year, dateTime.month, dateTime.day),
          );
        });

        testWidgets('Interval', (WidgetTester tester) async {
          await pumpScaffold(
            tester,
            EditRecurrenceOptions(recurrenceOptions: recurrenceOptions, predefinedEndChoices: predefinedEndChoices),
          );
          await tester.pump();

          final EditRecurrenceOptionsState pageState = tester.state(widgetFinder);

          final Finder scrollable = find.descendant(of: find.byType(Dialog), matching: find.byType(Scrollable));

          for (final RecurrenceIntervalType endIntervalType in RecurrenceIntervalType.values) {
            final int endIntervalSize = random.integer(16, min: 1);
            await tester.tap(find.byKey(const Key('untilField')));
            await tester.pumpAndSettle();
            await scrollAndTap(tester, find.byKey(const Key('recurrenceEndChoice5')), scrollable: scrollable.first);
            await tester.pump();
            await tester.enterText(find.byKey(const Key('customEndIntervalSizeField')), endIntervalSize.toString());
            await tester.tap(find.byKey(const Key('customEndIntervalTypeField')));
            await tester.pumpAndSettle();
            await tester.tap(find.byKey(Key('customEndIntervalType${endIntervalType.name}')));
            await tester.pumpAndSettle();
            await tester.tap(find.byKey(const Key('okButtonRecurrenceEndDialog')));
            await tester.pumpAndSettle();
            expect(pageState.recurrenceOptions.endChoice.isCustom, isTrue);
            expect(pageState.recurrenceOptions.endChoice.type, RecurrenceEndType.interval);
            expect(
                (pageState.recurrenceOptions.endChoice as RecurrenceEndChoiceInterval).intervalSize, endIntervalSize);
            expect(
                (pageState.recurrenceOptions.endChoice as RecurrenceEndChoiceInterval).intervalType, endIntervalType);
          }
        });

        testWidgets('Occurences', (WidgetTester tester) async {
          await pumpScaffold(
            tester,
            EditRecurrenceOptions(recurrenceOptions: recurrenceOptions, predefinedEndChoices: predefinedEndChoices),
          );
          await tester.pump();

          final EditRecurrenceOptionsState pageState = tester.state(widgetFinder);

          final Finder scrollable = find.descendant(of: find.byType(Dialog), matching: find.byType(Scrollable));

          final int occurenceCount = random.integer(16, min: 1);
          await tester.tap(find.byKey(const Key('untilField')));
          await tester.pumpAndSettle();
          await scrollAndTap(tester, find.byKey(const Key('recurrenceEndChoice6')), scrollable: scrollable.first);
          await tester.pump();
          await tester.enterText(find.byKey(const Key('customEndOccurenceField')), occurenceCount.toString());
          await tester.tap(find.byKey(const Key('okButtonRecurrenceEndDialog')));
          await tester.pumpAndSettle();
          expect(pageState.recurrenceOptions.endChoice.isCustom, isTrue);
          expect(pageState.recurrenceOptions.endChoice.type, RecurrenceEndType.occurrence);
          expect((pageState.recurrenceOptions.endChoice as RecurrenceEndChoiceOccurrence).occurrences, occurenceCount);
        });

        group('Until Validators', () {
          testWidgets('Nothing entered', (WidgetTester tester) async {
            await pumpScaffold(
              tester,
              EditRecurrenceOptions(
                recurrenceOptions: recurrenceOptions,
                predefinedEndChoices: const <RecurrenceEndChoice>[],
              ),
            );
            await tester.pump();

            final EditRecurrenceOptionsState pageState = tester.state(widgetFinder);

            await tester.tap(find.byKey(const Key('untilField')));
            await tester.pumpAndSettle();

            for (int i = 0; i < 3; i++) {
              await tester.tap(find.byKey(Key('recurrenceEndChoice$i')));
              await tester.pump();
              await tester.tap(find.byKey(const Key('okButtonRecurrenceEndDialog')));
              await tester.pump();
              expect(find.byKey(const Key('recurrenceEndError')), findsOneWidget);
              expect(pageState.recurrenceOptions.endChoice, recurrenceOptions.endChoice);
            }

            await tester.tap(find.byKey(const Key('recurrenceEndChoice1')));
            await tester.pump();
            await tester.tap(find.byKey(const Key('okButtonRecurrenceEndDialog')));
            await tester.pump();
            expect(find.byKey(const Key('recurrenceEndError')), findsOneWidget);
            expect(pageState.recurrenceOptions.endChoice, recurrenceOptions.endChoice);
          });

          testWidgets('Interval too large', (WidgetTester tester) async {
            await pumpScaffold(
              tester,
              EditRecurrenceOptions(
                recurrenceOptions: recurrenceOptions,
                predefinedEndChoices: const <RecurrenceEndChoice>[],
              ),
            );
            await tester.pump();

            final EditRecurrenceOptionsState pageState = tester.state(widgetFinder);

            await tester.tap(find.byKey(const Key('untilField')));
            await tester.pumpAndSettle();
            await tester.tap(find.byKey(const Key('recurrenceEndChoice1')));
            await tester.pump();
            for (final RecurrenceIntervalType endIntervalType in RecurrenceIntervalType.values) {
              await tester.enterText(find.byKey(const Key('customEndIntervalSizeField')),
                  (endIntervalType == RecurrenceIntervalType.years ? 10 : 100).toString());
              await tester.tap(find.byKey(const Key('customEndIntervalTypeField')));
              await tester.pumpAndSettle();
              await tester.tap(find.byKey(Key('customEndIntervalType${endIntervalType.name}')));
              await tester.pumpAndSettle();
              await tester.tap(find.byKey(const Key('okButtonRecurrenceEndDialog')));
              await tester.pump();
              expect(find.byKey(const Key('recurrenceEndError')), findsOneWidget);
              expect(pageState.recurrenceOptions.endChoice, recurrenceOptions.endChoice);
            }
          });

          testWidgets('Too many occurences', (WidgetTester tester) async {
            await pumpScaffold(
              tester,
              EditRecurrenceOptions(
                recurrenceOptions: recurrenceOptions,
                predefinedEndChoices: const <RecurrenceEndChoice>[],
              ),
            );
            await tester.pump();

            final EditRecurrenceOptionsState pageState = tester.state(widgetFinder);

            await tester.tap(find.byKey(const Key('untilField')));
            await tester.pumpAndSettle();

            await tester.tap(find.byKey(const Key('recurrenceEndChoice2')));
            await tester.pump();
            await tester.enterText(find.byKey(const Key('customEndOccurenceField')), 100.toString());
            await tester.tap(find.byKey(const Key('okButtonRecurrenceEndDialog')));
            await tester.pump();
            expect(find.byKey(const Key('recurrenceEndError')), findsOneWidget);
            expect(pageState.recurrenceOptions.endChoice, recurrenceOptions.endChoice);
          });
        });
      });
    });
  });
}
