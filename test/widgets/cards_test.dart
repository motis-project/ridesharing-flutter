import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:motis_mitfahr_app/account/models/profile_feature.dart';
import 'package:motis_mitfahr_app/drives/models/drive.dart';
import 'package:motis_mitfahr_app/drives/pages/drive_detail_page.dart';
import 'package:motis_mitfahr_app/rides/models/ride.dart';
import 'package:motis_mitfahr_app/rides/pages/ride_detail_page.dart';
import 'package:motis_mitfahr_app/util/icon_widget.dart';
import 'package:motis_mitfahr_app/util/locale_manager.dart';
import 'package:motis_mitfahr_app/util/profiles/profile_widget.dart';
import 'package:motis_mitfahr_app/util/profiles/reviews/custom_rating_bar_indicator.dart';
import 'package:motis_mitfahr_app/util/trip/drive_card.dart';
import 'package:motis_mitfahr_app/util/trip/pending_ride_card.dart';
import 'package:motis_mitfahr_app/util/trip/ride_card.dart';
import 'package:motis_mitfahr_app/util/trip/seat_indicator.dart';

import '../util/factories/drive_factory.dart';
import '../util/factories/model_factory.dart';
import '../util/factories/profile_factory.dart';
import '../util/factories/profile_feature_factory.dart';
import '../util/factories/ride_factory.dart';
import '../util/mock_server.dart';
import '../util/pump_material.dart';
import '../util/request_processor.dart';
import '../util/request_processor.mocks.dart';

void main() {
  final MockRequestProcessor processor = MockRequestProcessor();
  late Ride ride;
  late Drive drive;

  setUpAll(() {
    MockServer.setProcessor(processor);
  });

  setUp(() {
    reset(processor);
  });

  //since the code is the same for RideCard DriveCard and PendingRideCard, we only test DriveCard
  testWidgets('TripCard shows the correct information', (WidgetTester tester) async {
    drive = DriveFactory().generateFake();
    whenRequest(processor).thenReturnJson(drive.toJsonForApi());
    await pumpMaterial(tester, DriveCard(drive));

    //wait for card to load
    await tester.pump();

    //date is shown
    expect(find.text(localeManager.formatDate(ride.startTime)), findsOneWidget);

    //duration is shown
    expect(find.byIcon(Icons.access_time_outlined), findsOneWidget);

    //start location is shown
    expect(find.byKey(const Key('start')), findsOneWidget);

    //end location is shown
    expect(find.byKey(const Key('end')), findsOneWidget);
  });

  group('PendingRideCard', () {
    ride = RideFactory().generateFake(
      status: RideStatus.pending,
      rider: NullableParameter(ProfileFactory().generateFake(id: 1)),
      seats: 1,
    );
    drive = DriveFactory().generateFake(rides: [ride], seats: 2);

    setUp(() {
      whenRequest(processor).thenReturnJson([]);
    });

    testWidgets('shows the correct information', (WidgetTester tester) async {
      await pumpMaterial(tester, PendingRideCard(ride, reloadPage: () {}, drive: drive));

      //Profile Widget from rider is shown
      final Finder profileWidgetFinder = find.byType(ProfileWidget);
      expect(profileWidgetFinder, findsOneWidget);
      final ProfileWidget profileWidget = tester.widget(profileWidgetFinder);
      expect(profileWidget.profile, ride.rider);

      //Extra time is shown
      expect(find.byKey(const Key('extraTime')), findsOneWidget);

      //Seats indicator is shown
      final Finder seatsIndicator = find.byType(IconWidget);
      expect(seatsIndicator, findsOneWidget);
      expect(find.descendant(of: seatsIndicator, matching: find.byIcon(Icons.chair)), findsOneWidget);

      //Price is shown
      expect(find.byKey(const Key('price')), findsOneWidget);

      //Approve button is shown
      expect(find.byKey(const Key('approveButton')), findsOneWidget);

      //Reject button is shown
      expect(find.byKey(const Key('rejectButton')), findsOneWidget);
    });

    group('approve Ride', () {
      Future<void> openApproveDialog(WidgetTester tester) async {
        //need scaffold for dialog
        await pumpMaterial(tester, Scaffold(body: PendingRideCard(ride, reloadPage: () {}, drive: drive)));
        //open dialog
        final Finder approveButton = find.byKey(const Key('approveButton'));
        await tester.tap(approveButton);
        //load dialog
        await tester.pumpAndSettle();
      }

      testWidgets('can approve Ride if possible', (WidgetTester tester) async {
        await openApproveDialog(tester);

        //confirm dialog
        final Finder confirmButton = find.byKey(const Key('approveConfirmButton'));
        expect(confirmButton, findsOneWidget);
        await tester.tap(confirmButton);

        //load page
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('approveSuccessSnackbar')), findsOneWidget);
        verifyRequest(
          processor,
          urlMatcher: equals('/rest/v1/rpc/approve_ride'),
          methodMatcher: equals('POST'),
          bodyMatcher: equals({'ride_id': ride.id}),
        ).called(1);
      });

      testWidgets('can not approve Ride if drive has not enough seats', (WidgetTester tester) async {
        drive = DriveFactory().generateFake(rides: [ride], seats: 1);
        ride = RideFactory().generateFake(
          status: RideStatus.pending,
          seats: 3,
        );
        //need scaffold for dialog
        await pumpMaterial(tester, Scaffold(body: PendingRideCard(ride, reloadPage: () {}, drive: drive)));
        //open dialog
        final Finder approveButton = find.byKey(const Key('approveButton'));
        await tester.tap(approveButton);
        //load dialog
        await tester.pumpAndSettle();

        //confirm dialog
        final Finder confirmButton = find.byKey(const Key('approveConfirmButton'));
        expect(confirmButton, findsOneWidget);
        await tester.tap(confirmButton);

        //load page
        await tester.pumpAndSettle();

        verifyRequestNever(processor, urlMatcher: equals('/rest/v1/rpc/approve_ride'));
        expect(find.byKey(const Key('approveErrorSnackbar')), findsOneWidget);
      });

      testWidgets('can abort approving Ride', (WidgetTester tester) async {
        await openApproveDialog(tester);

        //abort dialog
        final Finder cancelButton = find.byKey(const Key('approveCancelButton'));
        expect(cancelButton, findsOneWidget);
        await tester.tap(cancelButton);

        //load page
        await tester.pumpAndSettle();

        expect(find.byType(SnackBar), findsNothing);
        verifyRequestNever(processor, urlMatcher: equals('/rest/v1/rpc/approve_ride'));
      });
    });

    group('reject Ride', () {
      Future<void> openRejectDialog(WidgetTester tester) async {
        //need scaffold for dialog
        await pumpMaterial(tester, Scaffold(body: PendingRideCard(ride, reloadPage: () {}, drive: drive)));
        //open dialog
        final Finder rejectButton = find.byKey(const Key('rejectButton'));
        await tester.tap(rejectButton);
        //load page
        await tester.pumpAndSettle();
      }

      testWidgets('can reject Ride', (WidgetTester tester) async {
        await openRejectDialog(tester);

        //confirm dialog
        final Finder confimrButton = find.byKey(const Key('rejectConfirmButton'));
        expect(confimrButton, findsOneWidget);
        await tester.tap(confimrButton);

        //load page
        await tester.pumpAndSettle();

        expect(find.byType(SnackBar), findsOneWidget);
        verifyRequest(
          processor,
          urlMatcher: equals('/rest/v1/rpc/reject_ride'),
          methodMatcher: equals('POST'),
          bodyMatcher: equals({'ride_id': ride.id}),
        ).called(1);
      });

      testWidgets('can abort rejecting Ride', (WidgetTester tester) async {
        await openRejectDialog(tester);

        //abort dialog
        final Finder cancelButton = find.byKey(const Key('rejectCancelButton'));
        expect(cancelButton, findsOneWidget);
        await tester.tap(cancelButton);

        //load page
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('rejectSuccessSnackbar')), findsNothing);
        verifyRequestNever(processor, urlMatcher: equals('/rest/v1/rpc/reject_ride'));
      });
    });
  });

  group('RideCard', () {
    Future<void> loadRideCard(WidgetTester tester, List<ProfileFeature>? features) async {
      ride = RideFactory().generateFake(
        drive: NullableParameter(
          DriveFactory().generateFake(
            driver: NullableParameter(
              ProfileFactory().generateFake(profileFeatures: features),
            ),
          ),
        ),
      );
      whenRequest(processor).thenReturnJson(ride.drive!.toJsonForApi());
      await pumpMaterial(tester, RideCard(ride));
      //wait for card to load
      await tester.pump();
    }

    testWidgets('shows the correct information', (WidgetTester tester) async {
      await loadRideCard(tester, null);

      //Profile Widget from driver is shown
      final Finder profileWidgetFinder = find.byType(ProfileWidget);
      expect(profileWidgetFinder, findsOneWidget);
      final ProfileWidget profileWidget = tester.widget(profileWidgetFinder);
      expect(profileWidget.profile, ride.drive!.driver);

      //Rating is shown
      expect(find.byType(CustomRatingBarIndicator), findsOneWidget);

      //Price is shown
      expect(find.byKey(const Key('price')), findsOneWidget);
    });

    group('Profile Features', () {
      testWidgets('shows only first 3 Features', (WidgetTester tester) async {
        await loadRideCard(tester, [
          ProfileFeatureFactory().generateFake(rank: 1, feature: Feature.accessible),
          ProfileFeatureFactory().generateFake(rank: 2, feature: Feature.noSmoking),
          ProfileFeatureFactory().generateFake(rank: 3, feature: Feature.noVaping),
          ProfileFeatureFactory().generateFake(rank: 4, feature: Feature.noPetsAllowed),
        ]);

        expect(find.byIcon(Icons.accessibility), findsOneWidget);
        expect(find.byIcon(Icons.smoke_free), findsOneWidget);
        expect(find.byIcon(Icons.vape_free), findsOneWidget);
        expect(find.byIcon(Icons.pets), findsNothing);

        ///7 Icons are always shown
        expect(find.byType(Icon), findsNWidgets(10));
      });

      testWidgets('can handle less than 3 Features', (WidgetTester tester) async {
        await loadRideCard(tester, [
          ProfileFeatureFactory().generateFake(rank: 1, feature: Feature.accessible),
          ProfileFeatureFactory().generateFake(rank: 2, feature: Feature.noSmoking),
        ]);

        expect(find.byIcon(Icons.accessibility), findsOneWidget);
        expect(find.byIcon(Icons.smoke_free), findsOneWidget);

        ///7 Icons are always shown
        expect(find.byType(Icon), findsNWidgets(9));
      });

      testWidgets('can handle no Features', (WidgetTester tester) async {
        await loadRideCard(tester, []);

        //7 Icons are always shown
        expect(find.byType(Icon), findsNWidgets(7));
      });
    });

    testWidgets('can Navigate to RideDetailPage', (WidgetTester tester) async {
      ride = RideFactory().generateFake();
      whenRequest(processor).thenReturnJson(ride.drive!.toJsonForApi());
      whenRequest(processor, urlMatcher: matches(RegExp('/rest/v1/rides.*'))).thenReturnJson(ride.toJsonForApi());
      await pumpMaterial(tester, RideCard(ride));
      //wait for card to load
      await tester.pump();

      //open RideDetailPage
      await tester.tap(find.byType(RideCard));

      //load page
      await tester.pump();
      await tester.pump();

      expect(find.byType(RideDetailPage), findsOneWidget);
    });
  });

  group('DriveCard', () {
    testWidgets('shows seat indicator', (WidgetTester tester) async {
      drive = DriveFactory().generateFake();
      whenRequest(processor).thenReturnJson(drive.toJsonForApi());
      await pumpMaterial(tester, DriveCard(drive));

      //wait for card to load
      await tester.pump();

      expect(find.byType(SeatIndicator), findsOneWidget);
    });

    testWidgets('can Navigate to Drive DetailPage', (WidgetTester tester) async {
      drive = DriveFactory().generateFake();
      whenRequest(processor).thenReturnJson(drive.toJsonForApi());
      await pumpMaterial(tester, DriveCard(drive));

      //wait for card to load
      await tester.pump();

      //open DriveDetailPage
      await tester.tap(find.byType(DriveCard));

      //load page
      await tester.pump();
      await tester.pump();

      expect(find.byType(DriveDetailPage), findsOneWidget);
    });
  });
}
