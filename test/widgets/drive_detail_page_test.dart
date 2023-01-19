import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:motis_mitfahr_app/drives/models/drive.dart';
import 'package:motis_mitfahr_app/drives/pages/drive_chat_page.dart';
import 'package:motis_mitfahr_app/drives/pages/drive_detail_page.dart';
import 'package:motis_mitfahr_app/rides/models/ride.dart';
import 'package:motis_mitfahr_app/util/trip/pending_ride_card.dart';

import '../util/factories/drive_factory.dart';
import '../util/factories/ride_factory.dart';
import '../util/mock_server.dart';
import '../util/mock_server.mocks.dart';
import '../util/pump_material.dart';

void main() {
  late Drive drive;
  MockUrlProcessor processor = MockUrlProcessor();

  setUpAll(() async {
    MockServer.setProcessor(processor);
  });

  setUp(() {
    drive = DriveFactory().generateFake(
      start: 'Start',
      end: 'End',
      endTime: DateTime.now().add(const Duration(hours: 1)),
      rides: [
        RideFactory().generateFake(status: RideStatus.pending),
      ],
    );
  });

  group('DriveDetailPage', () {
    testWidgets('Works with id parameter', (WidgetTester tester) async {
      when(processor.processUrl(any)).thenReturn(jsonEncode(drive.toJsonForApi()));

      await pumpMaterial(tester, DriveDetailPage(id: drive.id!));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for the drive to be fully loaded
      await tester.pump();

      expect(find.text(drive.start), findsNWidgets(2));
    });

    testWidgets('Works with object parameter', (WidgetTester tester) async {
      when(processor.processUrl(any)).thenReturn(jsonEncode(drive.toJsonForApi()));

      await pumpMaterial(tester, DriveDetailPage.fromDrive(drive));

      expect(find.text(drive.start), findsOneWidget);

      // Wait for the drive to be fully loaded
      await tester.pump();

      expect(find.text(drive.start), findsNWidgets(2));

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

      when(processor.processUrl(any)).thenReturn(jsonEncode(drive.toJsonForApi()));

      await pumpMaterial(tester, DriveDetailPage.fromDrive(drive));

      // Wait for the drive to be fully loaded
      await tester.pump();

      expect(find.text(drive.start), findsNWidgets(2));
      expect(find.text('Waypoint'), findsOneWidget);
      expect(find.text('Waypoint2'), findsNothing);
      expect(find.text('Waypoint3'), findsNothing);
    });

    testWidgets('Can handle duplicate waypoints', (WidgetTester tester) async {
      String waypoint = 'Waypoint';
      drive.rides!.addAll(List.generate(
        3,
        (index) => RideFactory().generateFake(
          start: index % 2 == 0 ? waypoint : null,
          end: index % 2 == 0 ? null : waypoint,
          status: RideStatus.approved,
        ),
      ));

      when(processor.processUrl(any)).thenReturn(jsonEncode(drive.toJsonForApi()));

      await pumpMaterial(tester, DriveDetailPage.fromDrive(drive));

      // Wait for the drive to be fully loaded
      await tester.pump();

      expect(find.text(drive.start), findsNWidgets(2));
      expect(find.text(waypoint), findsOneWidget);
    });

    testWidgets('Can cancel drive', (WidgetTester tester) async {
      when(processor.processUrl(any)).thenReturn(jsonEncode(drive.toJsonForApi()));

      await pumpMaterial(tester, DriveDetailPage.fromDrive(drive));

      // Wait for the drive to be fully loaded
      await tester.pump();

      final Finder cancelDriveButton = find.byKey(const Key('cancelDriveButton'));
      expect(cancelDriveButton, findsOneWidget);
      await tester.scrollUntilVisible(cancelDriveButton, 500.0);
      await tester.tap(cancelDriveButton);
      await tester.pumpAndSettle();

      final Finder cancelDriveYesButton = find.byKey(const Key('cancelDriveYesButton'));
      expect(cancelDriveYesButton, findsOneWidget);
      await tester.tap(cancelDriveYesButton);
      await tester.pumpAndSettle();

      // Verify that the drive was cancelled (but no way to verify body right now)
      verify(processor.processUrl('/rest/v1/drives?id=eq.${drive.id}')).called(1);

      expect(find.byKey(const Key("cancelledDriveBanner")), findsOneWidget);
    });

    testWidgets('Can abort cancelling drive', (WidgetTester tester) async {
      when(processor.processUrl(any)).thenReturn(jsonEncode(drive.toJsonForApi()));

      await pumpMaterial(tester, DriveDetailPage.fromDrive(drive));

      // Wait for the drive to be fully loaded
      await tester.pump();

      final Finder cancelDriveButton = find.byKey(const Key('cancelDriveButton'));
      expect(cancelDriveButton, findsOneWidget);
      await tester.scrollUntilVisible(cancelDriveButton, 500.0);
      await tester.tap(cancelDriveButton);
      await tester.pumpAndSettle();

      final Finder cancelDriveNoButton = find.byKey(const Key('cancelDriveNoButton'));
      expect(cancelDriveNoButton, findsOneWidget);
      await tester.tap(cancelDriveNoButton);
      await tester.pumpAndSettle();

      verifyNever(processor.processUrl('/rest/v1/drives?id=eq.${drive.id}'));

      expect(find.byKey(const Key("cancelledDriveBanner")), findsNothing);
    });

    testWidgets('can navigate to drive chat page', (WidgetTester tester) async {
      when(processor.processUrl(any)).thenReturn(jsonEncode(drive.toJsonForApi()));

      await pumpMaterial(tester, DriveDetailPage.fromDrive(drive));

      // Wait for the drive to be fully loaded
      await tester.pump();

      await tester.tap(find.byKey(const Key('driveChatButton')));
      await tester.pumpAndSettle();

      expect(find.byType(DriveChatPage), findsOneWidget);
    });
  });
}
