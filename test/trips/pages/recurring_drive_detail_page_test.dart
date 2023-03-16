import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:motis_mitfahr_app/trips/cards/drive_card.dart';
import 'package:motis_mitfahr_app/trips/models/recurring_drive.dart';
import 'package:motis_mitfahr_app/trips/pages/recurring_drive_detail_page.dart';
import 'package:motis_mitfahr_app/trips/pages/recurring_drive_edit_page.dart';
import 'package:motis_mitfahr_app/trips/util/recurrence/recurrence.dart';
import 'package:motis_mitfahr_app/trips/util/recurrence/week_day.dart';
import 'package:motis_mitfahr_app/trips/util/trip_overview.dart';
import 'package:rrule/rrule.dart';

import '../../test_util/factories/recurring_drive_factory.dart';
import '../../test_util/mocks/mock_server.dart';
import '../../test_util/mocks/request_processor.dart';
import '../../test_util/mocks/request_processor.mocks.dart';
import '../../test_util/pump_material.dart';

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
      destination: 'End',
      recurrenceRule: RecurrenceRule(
        frequency: Frequency.weekly,
        interval: 1,
        byWeekDays: {WeekDay.monday.toByWeekDayEntry(), WeekDay.wednesday.toByWeekDayEntry()},
        // Drives here will be less than 28 days future (to avoid problems with the end date and drive generation)
        count: 6,
      ),
      recurrenceEndType: RecurrenceEndType.occurrence,
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

        expect(find.byType(DriveCard, skipOffstage: false), findsNWidgets(recurringDrive.drives!.length));
        expect(find.byIcon(Icons.edit), findsOneWidget);
      });

      testWidgets('Works with object parameter', (WidgetTester tester) async {
        await pumpMaterial(tester, RecurringDriveDetailPage.fromRecurringDrive(recurringDrive));

        expect(find.byType(TripOverview), findsOneWidget);
        expect(find.byType(WeekDayPicker), findsOneWidget);

        expect(find.text(recurringDrive.start), findsOneWidget);

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Wait for the recurring drive to be fully loaded
        await tester.pump();

        expect(find.byType(DriveCard, skipOffstage: false), findsNWidgets(recurringDrive.drives!.length));
        expect(find.byIcon(Icons.edit), findsOneWidget);
      });
    });

    testWidgets('Works with stopped drive', (WidgetTester tester) async {
      recurringDrive = RecurringDriveFactory().generateFake(stoppedAt: DateTime.now());
      whenRequest(processor).thenReturnJson(recurringDrive.toJsonForApi());

      await pumpMaterial(tester, RecurringDriveDetailPage.fromRecurringDrive(recurringDrive));

      await tester.pump();

      expect(find.byKey(const Key('stoppedRecurringDriveBanner')), findsOneWidget);
      expect(find.byType(DriveCard), findsNothing);
      expect(find.byIcon(Icons.edit), findsNothing);
    });

    testWidgets('Works when drive has no drives', (WidgetTester tester) async {
      recurringDrive = RecurringDriveFactory().generateFake(drives: []);
      whenRequest(processor).thenReturnJson(recurringDrive.toJsonForApi());

      await pumpMaterial(tester, RecurringDriveDetailPage.fromRecurringDrive(recurringDrive));

      await tester.pump();

      expect(find.byType(DriveCard), findsNothing);
      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('Can show previews of further upcoming drives', (WidgetTester tester) async {
      recurringDrive = RecurringDriveFactory().generateFake(
        start: 'Start',
        destination: 'End',
        recurrenceRule: RecurrenceRule(
          frequency: Frequency.weekly,
          interval: 1,
          byWeekDays: {WeekDay.monday.toByWeekDayEntry()},
          count: 8,
        ),
        recurrenceEndType: RecurrenceEndType.occurrence,
      );
      whenRequest(processor).thenReturnJson(recurringDrive.toJsonForApi());

      await pumpMaterial(tester, RecurringDriveDetailPage.fromRecurringDrive(recurringDrive));

      await tester.pump();

      expect(
        find.byType(DriveCard, skipOffstage: false),
        findsNWidgets(8),
      );
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
