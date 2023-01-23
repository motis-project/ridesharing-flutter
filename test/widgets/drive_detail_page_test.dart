import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/drives/models/drive.dart';
import 'package:motis_mitfahr_app/drives/pages/drive_chat_page.dart';
import 'package:motis_mitfahr_app/drives/pages/drive_detail_page.dart';
import 'package:motis_mitfahr_app/rides/models/ride.dart';
import 'package:motis_mitfahr_app/util/profiles/profile_widget.dart';
import 'package:motis_mitfahr_app/util/trip/pending_ride_card.dart';
import 'package:motis_mitfahr_app/util/trip/trip_overview.dart';

import '../util/factories/drive_factory.dart';
import '../util/factories/ride_factory.dart';
import '../util/mock_server.dart';
import '../util/pump_material.dart';
import '../util/request_processor.dart';
import '../util/request_processor.mocks.dart';

void main() {
  late Drive drive;
  final MockRequestProcessor processor = MockRequestProcessor();

  setUpAll(() {
    MockServer.setProcessor(processor);
  });

  setUp(() {
    reset(processor);

    drive = DriveFactory().generateFake(
      start: 'Start',
      end: 'End',
      endTime: DateTime.now().add(const Duration(hours: 1)),
      rides: [RideFactory().generateFake(status: RideStatus.pending)],
    );
    whenRequest(processor).thenReturnJson(drive.toJsonForApi());
  });

  group('DriveDetailPage', () {
    group('constructors', () {
      testWidgets('Works with id parameter', (WidgetTester tester) async {
        await pumpMaterial(tester, DriveDetailPage(id: drive.id!));
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Wait for the drive to be fully loaded
        await tester.pump();

        expect(find.text(drive.start), findsNWidgets(2));
      });

      testWidgets('Works with object parameter', (WidgetTester tester) async {
        await pumpMaterial(tester, DriveDetailPage.fromDrive(drive));

        expect(find.byType(TripOverview), findsOneWidget);
        expect(find.text(drive.start), findsOneWidget);

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Wait for the drive to be fully loaded
        await tester.pump();

        expect(find.text(drive.start), findsNWidgets(2));
      });
    });

    testWidgets('Shows pending ride cards', (WidgetTester tester) async {
      await pumpMaterial(tester, DriveDetailPage.fromDrive(drive));
      await tester.pump();

      final pendingRideCard = find.byType(PendingRideCard);
      await tester.scrollUntilVisible(pendingRideCard, 100);
      expect(pendingRideCard, findsOneWidget);
      expect(
        find.descendant(of: pendingRideCard, matching: find.text(drive.rides!.first.rider!.username)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: pendingRideCard, matching: find.byType(ButtonBar)),
        findsOneWidget,
      );
    });

    group('Shows cancel/hide button depending on circumstances', () {
      testWidgets('Shows cancel when ride is upcoming', (WidgetTester tester) async {
        await pumpMaterial(tester, DriveDetailPage.fromDrive(drive));
        await tester.pump();

        expect(find.byKey(const Key('cancelDriveButton')), findsOneWidget);
        expect(find.byKey(const Key('hideDriveButton')), findsNothing);
      });
      testWidgets('Shows hide when drive is finished', (WidgetTester tester) async {
        final Drive finishedDrive = DriveFactory().generateFake(
          startTime: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
          endTime: DateTime.now().subtract(const Duration(days: 1)),
        );
        whenRequest(processor).thenReturnJson(finishedDrive.toJsonForApi());

        await pumpMaterial(tester, DriveDetailPage.fromDrive(finishedDrive));
        await tester.pump();
        expect(find.byKey(const Key('cancelDriveButton')), findsNothing);
        expect(find.byKey(const Key('hideDriveButton')), findsOneWidget);
      });
      testWidgets('Shows hide when drive is cancelled', (WidgetTester tester) async {
        final Drive cancelledDrive = DriveFactory().generateFake(cancelled: true);

        whenRequest(processor).thenReturnJson(cancelledDrive.toJsonForApi());

        await pumpMaterial(tester, DriveDetailPage.fromDrive(cancelledDrive));
        await tester.pump();
        expect(find.byKey(const Key('cancelDriveButton')), findsNothing);
        expect(find.byKey(const Key('hideDriveButton')), findsOneWidget);
      });
    });

    testWidgets('Can handle other types of rides', (WidgetTester tester) async {
      drive.rides!.add(RideFactory().generateFake(
        start: 'Waypoint',
        status: RideStatus.approved,
      ));

      drive.rides!.add(RideFactory().generateFake(
        start: 'Waypoint2',
        status: RideStatus.cancelledByRider,
      ));

      drive.rides!.add(RideFactory().generateFake(
        start: 'Waypoint3',
        status: RideStatus.cancelledByDriver,
      ));

      whenRequest(processor).thenReturnJson(drive.toJsonForApi());

      await pumpMaterial(tester, DriveDetailPage.fromDrive(drive));

      await tester.pump();

      expect(find.text(drive.start), findsNWidgets(2));
      expect(find.text('Waypoint'), findsOneWidget);
      expect(find.text('Waypoint2'), findsNothing);
      expect(find.text('Waypoint3'), findsNothing);

      final Finder profileWidget = find.byType(ProfileWidget);
      tester.tap(profileWidget.first);

      // Add navigating to chat here
    });

    testWidgets('Can handle duplicate waypoints', (WidgetTester tester) async {
      const String waypoint = 'Waypoint';
      drive.rides!.addAll(List.generate(
        3,
        (index) => RideFactory().generateFake(
          start: index.isEven ? waypoint : null,
          end: index.isEven ? null : waypoint,
          status: RideStatus.approved,
        ),
      ));

      whenRequest(processor).thenReturnJson(drive.toJsonForApi());

      await pumpMaterial(tester, DriveDetailPage.fromDrive(drive));

      await tester.pump();

      expect(find.text(drive.start), findsNWidgets(2));
      expect(find.text(waypoint), findsOneWidget);
    });

    group('Cancelling drive', () {
      Future<void> openCancelDialog(WidgetTester tester) async {
        await pumpMaterial(tester, DriveDetailPage.fromDrive(drive));

        await tester.pump();

        final Finder cancelDriveButton = find.byKey(const Key('cancelDriveButton'));
        await tester.scrollUntilVisible(cancelDriveButton, 500.0);
        await tester.tap(cancelDriveButton);
        await tester.pumpAndSettle();
      }

      testWidgets('Can cancel drive', (WidgetTester tester) async {
        await openCancelDialog(tester);

        final Finder cancelDriveYesButton = find.byKey(const Key('cancelDriveYesButton'));
        expect(cancelDriveYesButton, findsOneWidget);
        await tester.tap(cancelDriveYesButton);
        await tester.pumpAndSettle();

        verifyRequest(
          processor,
          urlMatcher: equals('/rest/v1/drives?id=eq.${drive.id}'),
          methodMatcher: equals('PATCH'),
          bodyMatcher: equals({'cancelled': true}),
        ).called(1);

        expect(find.byKey(const Key('cancelledDriveBanner')), findsOneWidget);
      });

      testWidgets('Can abort cancelling drive', (WidgetTester tester) async {
        await openCancelDialog(tester);

        final Finder cancelDriveNoButton = find.byKey(const Key('cancelDriveNoButton'));
        expect(cancelDriveNoButton, findsOneWidget);
        await tester.tap(cancelDriveNoButton);
        await tester.pumpAndSettle();

        verifyRequestNever(processor, urlMatcher: equals('/rest/v1/drives?id=eq.${drive.id}'));

        expect(find.byKey(const Key('cancelledDriveBanner')), findsNothing);
      });
    });

    group('Hiding drive', () {
      setUp(() {
        drive = DriveFactory().generateFake(cancelled: true);
        whenRequest(processor).thenReturnJson(drive.toJsonForApi());
      });

      Future<void> openHideDialog(WidgetTester tester) async {
        await pumpMaterial(tester, DriveDetailPage.fromDrive(drive));

        await tester.pump();

        final Finder hideDriveButton = find.byKey(const Key('hideDriveButton'));
        await tester.scrollUntilVisible(hideDriveButton, 500.0);
        await tester.tap(hideDriveButton);
        await tester.pumpAndSettle();
      }

      testWidgets('Can hide drive', (WidgetTester tester) async {
        await openHideDialog(tester);

        final Finder hideDriveYesButton = find.byKey(const Key('hideDriveYesButton'));
        expect(hideDriveYesButton, findsOneWidget);
        await tester.tap(hideDriveYesButton);
        await tester.pumpAndSettle();

        verifyRequest(
          processor,
          urlMatcher: equals('/rest/v1/drives?id=eq.${drive.id}'),
          methodMatcher: equals('PATCH'),
          bodyMatcher: equals({'hide_in_list_view': true}),
        ).called(1);
      });

      testWidgets('Can abort hiding drive', (WidgetTester tester) async {
        await openHideDialog(tester);

        final Finder hideDriveNoButton = find.byKey(const Key('hideDriveNoButton'));
        expect(hideDriveNoButton, findsOneWidget);
        await tester.tap(hideDriveNoButton);
        await tester.pumpAndSettle();

        verifyRequestNever(processor, urlMatcher: equals('/rest/v1/drives?id=eq.${drive.id}'));
      });
    });

    testWidgets('Can navigate to drive chat page', skip: true, (WidgetTester tester) async {
      await pumpMaterial(tester, DriveDetailPage.fromDrive(drive));
      await tester.pump();

      await tester.tap(find.byKey(const Key('driveChatButton')));
      await tester.pumpAndSettle();

      expect(find.byType(DriveChatPage), findsOneWidget);
    });
  });
}
