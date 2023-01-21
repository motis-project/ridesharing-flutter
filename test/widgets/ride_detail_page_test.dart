import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/account/widgets/features_column.dart';
import 'package:motis_mitfahr_app/account/widgets/reviews_preview.dart';
import 'package:motis_mitfahr_app/drives/models/drive.dart';
import 'package:motis_mitfahr_app/rides/models/ride.dart';
import 'package:motis_mitfahr_app/rides/pages/ride_detail_page.dart';
import 'package:motis_mitfahr_app/util/profiles/profile_widget.dart';
import 'package:motis_mitfahr_app/util/profiles/profile_wrap_list.dart';
import 'package:motis_mitfahr_app/util/trip/trip_overview.dart';

import '../util/factories/drive_factory.dart';
import '../util/factories/model_factory.dart';
import '../util/factories/profile_factory.dart';
import '../util/factories/review_factory.dart';
import '../util/factories/ride_factory.dart';
import '../util/mock_server.dart';
import '../util/mock_server.mocks.dart';
import '../util/pump_material.dart';

void main() {
  late Profile driver;
  late Drive drive;
  late Ride ride;
  MockUrlProcessor processor = MockUrlProcessor();

  setUpAll(() async {
    MockServer.setProcessor(processor);
  });

  setUp(() {
    driver = ProfileFactory().generateFake(
      reviewsReceived: ReviewFactory().generateFakeList(),
    );

    drive = DriveFactory().generateFake(
      driver: NullableParameter(driver),
    );

    ride = RideFactory().generateFake(
      start: 'Start',
      end: 'End',
      endTime: DateTime.now().add(const Duration(hours: 1)),
      status: RideStatus.approved,
      drive: NullableParameter(drive),
    );

    when(processor.processUrl(any)).thenReturn(jsonEncode(ride.toJsonForApi()));
  });

  group('RideDetailPage', () {
    group('constructors', () {
      testWidgets('Works with id parameter', (WidgetTester tester) async {
        await pumpMaterial(tester, RideDetailPage(id: ride.id!));

        expect(find.byType(TripOverview), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Wait for the ride to be fully loaded
        await tester.pump();

        expect(find.text(ride.start), findsOneWidget);
      });

      testWidgets('Works with object parameter', (WidgetTester tester) async {
        await pumpMaterial(tester, RideDetailPage.fromRide(ride));

        expect(find.byType(TripOverview), findsOneWidget);
        expect(find.text(driver.username), findsNothing);

        // Wait for the ride to be fully loaded
        await tester.pump();

        expect(find.text(driver.username), findsOneWidget);
      });
    });

    testWidgets('Shows the driver profile', (WidgetTester tester) async {
      await pumpMaterial(tester, RideDetailPage.fromRide(ride));
      await tester.pump();

      expect(find.byType(ProfileWidget), findsOneWidget);
      expect(find.byType(ReviewsPreview), findsOneWidget);
      expect(find.byType(FeaturesColumn), findsOneWidget);
      expect(find.text(driver.username), findsOneWidget);
    });

    group('Riders', () {
      testWidgets('Does not show riders when ride is not approved', (WidgetTester tester) async {
        Ride notApprovedRide = RideFactory().generateFake(status: RideStatus.pending);
        when(processor.processUrl(any)).thenReturn(jsonEncode(notApprovedRide.toJsonForApi()));

        await pumpMaterial(tester, RideDetailPage.fromRide(notApprovedRide));
        await tester.pump();

        expect(find.text('Riders'), findsNothing);
        expect(find.byType(ProfileWrapList), findsNothing);
      });

      testWidgets('Shows riders when ride is approved', (WidgetTester tester) async {
        await pumpMaterial(tester, RideDetailPage.fromRide(ride));
        await tester.pump();

        expect(find.text('Riders'), findsOneWidget);
        expect(find.byType(ProfileWrapList), findsOneWidget);
      });

      testWidgets('Shows riders when ride is cancelledByDriver', (WidgetTester tester) async {
        Ride cancelledRide = RideFactory().generateFake(status: RideStatus.cancelledByDriver);
        when(processor.processUrl(any)).thenReturn(jsonEncode(cancelledRide.toJsonForApi()));

        await pumpMaterial(tester, RideDetailPage.fromRide(cancelledRide));
        await tester.pump();

        expect(find.text('Riders'), findsOneWidget);
        expect(find.byType(ProfileWrapList), findsOneWidget);
      });
    });

    // group('Shows primary button depending on circumstances', () {
    //   testWidgets('Shows cancel when ride is upcoming and approved', (WidgetTester tester) async {
    //     await pumpMaterial(tester, RideDetailPage.fromRide(ride));
    //     await tester.pump();

    //     expect(find.byKey(const Key('cancelDriveButton')), findsOneWidget);
    //     expect(find.byKey(const Key('hideDriveButton')), findsNothing);
    //   });
    //   testWidgets('Shows rate when drive is finished and approved', (WidgetTester tester) async {
    //     Ride finishedRide = RideFactory().generateFake(
    //       startTime: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
    //       endTime: DateTime.now().subtract(const Duration(days: 1)),
    //     );
    //     when(processor.processUrl(any)).thenReturn(jsonEncode(finishedDrive.toJsonForApi()));
    //     await pumpMaterial(tester, RideDetailPage.fromRide(finishedDrive));
    //     await tester.pump();
    //     expect(find.byKey(const Key('cancelDriveButton')), findsNothing);
    //     expect(find.byKey(const Key('hideDriveButton')), findsOneWidget);
    //   });
    //   testWidgets('Shows hide when drive is cancelled', (WidgetTester tester) async {
    //     Drive cancelledDrive = RideFactory().generateFake(cancelled: true);
    //     when(processor.processUrl(any)).thenReturn(jsonEncode(cancelledDrive.toJsonForApi()));
    //     await pumpMaterial(tester, RideDetailPage.fromRide(cancelledDrive));
    //     await tester.pump();
    //     expect(find.byKey(const Key('cancelDriveButton')), findsNothing);
    //     expect(find.byKey(const Key('hideDriveButton')), findsOneWidget);
    //   });
    // });

    //   group('Cancelling drive', () {
    //     Future<void> openCancelDialog(WidgetTester tester) async {
    //       await pumpMaterial(tester, RideDetailPage.fromRide(ride));

    //       await tester.pump();

    //       final Finder cancelDriveButton = find.byKey(const Key('cancelDriveButton'));
    //       await tester.scrollUntilVisible(cancelDriveButton, 500.0);
    //       await tester.tap(cancelDriveButton);
    //       await tester.pumpAndSettle();
    //     }

    //     testWidgets('Can cancel drive', (WidgetTester tester) async {
    //       await openCancelDialog(tester);

    //       final Finder cancelDriveYesButton = find.byKey(const Key('cancelDriveYesButton'));
    //       expect(cancelDriveYesButton, findsOneWidget);
    //       await tester.tap(cancelDriveYesButton);
    //       await tester.pumpAndSettle();

    //       // Verify that the drive was cancelled (but no way to verify body right now)
    //       verify(processor.processUrl('/rest/v1/drives?id=eq.${ride.id}')).called(1);

    //       expect(find.byKey(const Key("cancelledDriveBanner")), findsOneWidget);
    //     });

    //     testWidgets('Can abort cancelling drive', (WidgetTester tester) async {
    //       await openCancelDialog(tester);

    //       final Finder cancelDriveNoButton = find.byKey(const Key('cancelDriveNoButton'));
    //       expect(cancelDriveNoButton, findsOneWidget);
    //       await tester.tap(cancelDriveNoButton);
    //       await tester.pumpAndSettle();

    //       verifyNever(processor.processUrl('/rest/v1/drives?id=eq.${ride.id}'));

    //       expect(find.byKey(const Key("cancelledDriveBanner")), findsNothing);
    //     });
    //   });

    //   group('Hiding drive', () {
    //     setUp(() {
    //       ride = RideFactory().generateFake(cancelled: true);
    //       when(processor.processUrl(any)).thenReturn(jsonEncode(ride.toJsonForApi()));
    //     });

    //     Future<void> openHideDialog(WidgetTester tester) async {
    //       await pumpMaterial(tester, RideDetailPage.fromRide(ride));

    //       await tester.pump();

    //       final Finder cancelDriveButton = find.byKey(const Key('hideDriveButton'));
    //       await tester.scrollUntilVisible(cancelDriveButton, 500.0);
    //       await tester.tap(cancelDriveButton);
    //       await tester.pumpAndSettle();
    //     }

    //     testWidgets('Can hide drive', (WidgetTester tester) async {
    //       await openHideDialog(tester);

    //       final Finder hideDriveYesButton = find.byKey(const Key('hideDriveYesButton'));
    //       expect(hideDriveYesButton, findsOneWidget);
    //       await tester.tap(hideDriveYesButton);
    //       await tester.pumpAndSettle();

    //       // Verify that the drive was hidden (but no way to verify body right now)
    //       verify(processor.processUrl('/rest/v1/drives?id=eq.${ride.id}')).called(1);
    //     });

    //     testWidgets('Can abort hiding drive', (WidgetTester tester) async {
    //       await openHideDialog(tester);

    //       final Finder hideDriveNoButton = find.byKey(const Key('hideDriveNoButton'));
    //       expect(hideDriveNoButton, findsOneWidget);
    //       await tester.tap(hideDriveNoButton);
    //       await tester.pumpAndSettle();

    //       verifyNever(processor.processUrl('/rest/v1/drives?id=eq.${ride.id}'));
    //     });
    //   });

    //   testWidgets('Can navigate to drive chat page', (WidgetTester tester) async {
    //     await pumpMaterial(tester, RideDetailPage.fromRide(ride));
    //     await tester.pump();

    //     await tester.tap(find.byKey(const Key('driveChatButton')));
    //     await tester.pumpAndSettle();

    //     expect(find.byType(DriveChatPage), findsOneWidget);
    //   });
  });
}
