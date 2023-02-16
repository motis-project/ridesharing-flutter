import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:motis_mitfahr_app/drives/models/recurring_drive.dart';
import 'package:motis_mitfahr_app/drives/pages/recurring_drive_detail_page.dart';
import 'package:motis_mitfahr_app/drives/pages/recurring_drive_edit_page.dart';
import 'package:motis_mitfahr_app/drives/util/week_day.dart';
import 'package:motis_mitfahr_app/util/trip/drive_card.dart';
import 'package:motis_mitfahr_app/util/trip/trip_overview.dart';
import 'package:rrule/rrule.dart';

import '../util/factories/recurring_drive_factory.dart';
import '../util/mocks/mock_server.dart';
import '../util/mocks/request_processor.dart';
import '../util/mocks/request_processor.mocks.dart';
import '../util/pump_material.dart';

void main() {
  late RecurringDrive recurringDrive;
  final MockRequestProcessor processor = MockRequestProcessor();

  setUpAll(() {
    MockServer.setProcessor(processor);
  });

  setUp(() {
    reset(processor);

    recurringDrive = RecurringDriveFactory().generateFake(
      start: 'Start',
      end: 'End',
      recurrenceRule: RecurrenceRule(
        frequency: Frequency.weekly,
        interval: 1,
        byWeekDays: {ByWeekDayEntry(WeekDay.monday.index + 1), ByWeekDayEntry(WeekDay.tuesday.index + 1)},
        until: DateTime.now().add(const Duration(days: 30)).toUtc(),
      ),
    );
    whenRequest(processor).thenReturnJson(recurringDrive.toJsonForApi());
  });

  group('RecurringDriveDetailPage', () {
    group('constructors', () {
      testWidgets('Works with id parameter', (WidgetTester tester) async {
        await pumpMaterial(tester, RecurringDriveDetailPage(id: recurringDrive.id!));
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Wait for the recurring drive to be fully loaded
        await tester.pump();

        expect(find.byType(TripOverview), findsOneWidget);
        expect(find.byType(WeekDayPicker), findsOneWidget);

        expect(find.byType(DriveCard, skipOffstage: false),
            findsNWidgets(RecurringDriveDetailPageState.shownDrivesCountDefault));
      });

      testWidgets('Works with object parameter', (WidgetTester tester) async {
        await pumpMaterial(tester, RecurringDriveDetailPage.fromRecurringDrive(recurringDrive));

        expect(find.byType(TripOverview), findsOneWidget);
        expect(find.byType(WeekDayPicker), findsOneWidget);

        expect(find.text(recurringDrive.start), findsOneWidget);

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Wait for the recurring drive to be fully loaded
        await tester.pump();

        expect(find.byType(DriveCard, skipOffstage: false),
            findsNWidgets(RecurringDriveDetailPageState.shownDrivesCountDefault));
      });
    });

    group('Upcoming drives', () {
      final showLessButtonFinder = find.byKey(const Key('showLessButton'));
      final showMoreButtonFinder = find.byKey(const Key('showMoreButton'));

      Future<void> tapShowLessButton(WidgetTester tester, {double scrollDelta = 1}) async {
        await tester.scrollUntilVisible(showLessButtonFinder, 50 * scrollDelta);
        await tester.tap(showLessButtonFinder);
        await tester.pump();
      }

      Future<void> tapShowMoreButton(WidgetTester tester, {double scrollDelta = 1}) async {
        await tester.scrollUntilVisible(showMoreButtonFinder, 50 * scrollDelta);
        await tester.tap(showMoreButtonFinder);
        await tester.pump();
      }

      testWidgets('Shows upcoming drives', (WidgetTester tester) async {
        await pumpMaterial(tester, RecurringDriveDetailPage.fromRecurringDrive(recurringDrive));
        await tester.pump();

        final driveCardFinder = find.byType(DriveCard, skipOffstage: false);
        expect(driveCardFinder, findsNWidgets(RecurringDriveDetailPageState.shownDrivesCountDefault));
        final driveCardState = tester.state<DriveCardState>(driveCardFinder.first);
        expect(driveCardState.trip.id, equals(recurringDrive.drives!.first.id));
      });

      testWidgets('Can show less and more upcoming drives', (WidgetTester tester) async {
        await pumpMaterial(tester, RecurringDriveDetailPage.fromRecurringDrive(recurringDrive));
        await tester.pump();

        final driveCardFinder = find.byType(DriveCard, skipOffstage: false);
        // Shows shownDrivesCountDefault upcoming drives
        expect(driveCardFinder, findsNWidgets(5));

        await tapShowLessButton(tester);
        // Shows only the first upcoming drive (but at least one if it exists)
        expect(driveCardFinder, findsNWidgets(1));
        expect(showLessButtonFinder, findsNothing);

        await tapShowMoreButton(tester);
        // Shows 1 + shownDrivesCountDefault upcoming drives
        expect(driveCardFinder, findsNWidgets(6));

        await tapShowMoreButton(tester);
        // Shows all upcoming drives
        expect(driveCardFinder, findsNWidgets(8));
        expect(showMoreButtonFinder, findsNothing);

        await tapShowLessButton(tester, scrollDelta: -1);
        // Shows all upcoming drives minus shownDrivesCountDefault (8-5 = 3)
        expect(driveCardFinder, findsNWidgets(3));
      });

      testWidgets('Shows message when no upcoming drives', (WidgetTester tester) async {
        // This recurring drive is old and thus has no upcoming drives (factory only generates for 30 days)
        recurringDrive = RecurringDriveFactory().generateFake(
          start: 'Start',
          end: 'End',
          startedAt: DateTime.now().subtract(const Duration(days: 365)),
        );
        whenRequest(processor).thenReturnJson(recurringDrive.toJsonForApi());

        await pumpMaterial(tester, RecurringDriveDetailPage.fromRecurringDrive(recurringDrive));
        await tester.pump();

        final driveCardFinder = find.byType(DriveCard, skipOffstage: false);
        expect(driveCardFinder, findsNWidgets(0));
        expect(showLessButtonFinder, findsNothing);
        expect(showMoreButtonFinder, findsNothing);

        expect(find.byKey(const Key('noUpcomingDrives')), findsOneWidget);
      });
    });

    testWidgets('Can navigate via the edit button', (WidgetTester tester) async {
      await pumpMaterial(tester, RecurringDriveDetailPage.fromRecurringDrive(recurringDrive));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      expect(find.byType(RecurringDriveEditPage), findsOneWidget);
    });
  });
}
