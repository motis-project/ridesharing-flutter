import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:motis_mitfahr_app/account/models/profile_feature.dart';
import 'package:motis_mitfahr_app/account/widgets/profile_widget.dart';
import 'package:motis_mitfahr_app/managers/locale_manager.dart';
import 'package:motis_mitfahr_app/reviews/util/custom_rating_bar_indicator.dart';
import 'package:motis_mitfahr_app/trips/cards/drive_card.dart';
import 'package:motis_mitfahr_app/trips/cards/pending_ride_card.dart';
import 'package:motis_mitfahr_app/trips/cards/ride_card.dart';
import 'package:motis_mitfahr_app/trips/models/drive.dart';
import 'package:motis_mitfahr_app/trips/models/ride.dart';
import 'package:motis_mitfahr_app/trips/pages/drive_detail_page.dart';
import 'package:motis_mitfahr_app/trips/pages/ride_detail_page.dart';
import 'package:motis_mitfahr_app/trips/util/seat_indicator.dart';
import 'package:motis_mitfahr_app/util/icon_widget.dart';
import 'package:motis_mitfahr_app/util/own_theme_fields.dart';

import '../test_util/factories/drive_factory.dart';
import '../test_util/factories/model_factory.dart';
import '../test_util/factories/profile_factory.dart';
import '../test_util/factories/profile_feature_factory.dart';
import '../test_util/factories/ride_factory.dart';
import '../test_util/mocks/mock_server.dart';
import '../test_util/mocks/request_processor.dart';
import '../test_util/mocks/request_processor.mocks.dart';
import '../test_util/pump_material.dart';

void main() {
  final MockRequestProcessor processor = MockRequestProcessor();
  late Ride ride;
  late Drive drive;

  setUpAll(() {
    ride = RideFactory().generateFake();
    drive = DriveFactory().generateFake(rides: [ride]);
    MockServer.setProcessor(processor);
  });

  setUp(() {
    reset(processor);
  });

  //since the code is the same for RideCard DriveCard and PendingRideCard, we only test DriveCard
  testWidgets('TripCard shows the correct information', (WidgetTester tester) async {
    whenRequest(processor).thenReturnJson(drive.toJsonForApi());
    await pumpMaterial(tester, DriveCard(drive));

    //wait for card to load
    await tester.pump();

    //date is shown
    expect(find.text(localeManager.formatDate(ride.startDateTime)), findsOneWidget);

    //duration is shown
    expect(find.byKey(const Key('duration')), findsOneWidget);

    //start location is shown
    expect(find.byKey(const Key('start')), findsOneWidget);

    //end location is shown
    expect(find.byKey(const Key('destination')), findsOneWidget);
  });

  group('PendingRideCard', () {
    setUpAll(() {
      ride = RideFactory().generateFake(
        status: RideStatus.pending,
        rider: NullableParameter(ProfileFactory().generateFake(id: 1)),
        seats: 1,
      );
      drive = DriveFactory().generateFake(rides: [ride], seats: 2);
    });

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
        await pumpScaffold(tester, PendingRideCard(ride, reloadPage: () {}, drive: drive));
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
        await pumpScaffold(tester, PendingRideCard(ride, reloadPage: () {}, drive: drive));
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
        await pumpScaffold(tester, PendingRideCard(ride, reloadPage: () {}, drive: drive));
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
    Future<void> loadRideCard(
      WidgetTester tester, {
      List<ProfileFeature>? features,
      RideStatus? status,
      DateTime? destinationTime,
    }) async {
      ride = RideFactory().generateFake(
        status: status,
        destinationDateTime: destinationTime,
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
      await loadRideCard(tester);

      //Profile Widget from driver is shown
      final Finder profileWidgetFinder = find.byType(ProfileWidget);
      expect(profileWidgetFinder, findsOneWidget);
      final ProfileWidget profileWidget = tester.widget(profileWidgetFinder);
      expect(profileWidget.profile, ride.drive!.driver);

      //Rating is shown
      expect(find.byType(CustomRatingBarIndicator), findsOneWidget);
    });

    group('Profile Features', () {
      testWidgets('shows only first 3 Features', (WidgetTester tester) async {
        await loadRideCard(tester, features: [
          ProfileFeatureFactory().generateFake(rank: 1, feature: Feature.accessible),
          ProfileFeatureFactory().generateFake(rank: 2, feature: Feature.noSmoking),
          ProfileFeatureFactory().generateFake(rank: 3, feature: Feature.noVaping),
          ProfileFeatureFactory().generateFake(rank: 4, feature: Feature.noPetsAllowed),
        ]);

        final Finder profileFeatures = find.byKey(const Key('profileFeatures'));

        expect(find.descendant(of: profileFeatures, matching: find.byIcon(Icons.accessibility)), findsOneWidget);
        expect(find.descendant(of: profileFeatures, matching: find.byIcon(Icons.smoke_free)), findsOneWidget);
        expect(find.descendant(of: profileFeatures, matching: find.byIcon(Icons.vape_free)), findsOneWidget);
        expect(find.descendant(of: profileFeatures, matching: find.byType(Icon)), findsNWidgets(3));
      });

      testWidgets('can handle less than 3 Features', (WidgetTester tester) async {
        await loadRideCard(tester, features: [
          ProfileFeatureFactory().generateFake(rank: 1, feature: Feature.accessible),
          ProfileFeatureFactory().generateFake(rank: 2, feature: Feature.noSmoking),
        ]);

        final Finder profileFeatures = find.byKey(const Key('profileFeatures'));

        expect(find.descendant(of: profileFeatures, matching: find.byIcon(Icons.accessibility)), findsOneWidget);
        expect(find.descendant(of: profileFeatures, matching: find.byIcon(Icons.smoke_free)), findsOneWidget);
        expect(find.descendant(of: profileFeatures, matching: find.byType(Icon)), findsNWidgets(2));
      });

      testWidgets('can handle no Features', (WidgetTester tester) async {
        await loadRideCard(tester, features: []);

        final Finder profileFeatures = find.byKey(const Key('profileFeatures'));

        expect(find.descendant(of: profileFeatures, matching: find.byType(Icon)), findsNothing);
      });
    });

    group('shows the right status:', () {
      testWidgets('warning for pending Ride', (WidgetTester tester) async {
        await loadRideCard(tester,
            status: RideStatus.pending, destinationTime: DateTime.now().add(const Duration(minutes: 10)));

        expect(find.byKey(const Key('pendingIcon')), findsOneWidget);

        final BuildContext context = tester.element(find.byType(Container).first);
        expect(tester.widget<Card>(find.byType(Card)).color, Theme.of(context).own().warning);
      });

      testWidgets('success for approved Ride', (WidgetTester tester) async {
        await loadRideCard(tester,
            status: RideStatus.approved, destinationTime: DateTime.now().add(const Duration(minutes: 10)));

        expect(find.byKey(const Key('approvedIcon')), findsOneWidget);

        final BuildContext context = tester.element(find.byType(Container).first);
        expect(tester.widget<Card>(find.byType(Card)).color, Theme.of(context).own().success);
      });

      testWidgets('error for rejected Ride', (WidgetTester tester) async {
        await loadRideCard(tester,
            status: RideStatus.rejected, destinationTime: DateTime.now().add(const Duration(minutes: 10)));

        expect(find.byKey(const Key('cancelledOrRejectedIcon')), findsOneWidget);

        final BuildContext context = tester.element(find.byType(Container).first);
        expect(tester.widget<Card>(find.byType(Card)).color, Theme.of(context).colorScheme.error);
      });

      testWidgets('error for cancelledByDriver', (WidgetTester tester) async {
        await loadRideCard(tester,
            status: RideStatus.cancelledByDriver, destinationTime: DateTime.now().add(const Duration(minutes: 10)));

        expect(find.byKey(const Key('cancelledOrRejectedIcon')), findsOneWidget);

        final BuildContext context = tester.element(find.byType(Container).first);
        expect(tester.widget<Card>(find.byType(Card)).color, Theme.of(context).colorScheme.error);
      });

      testWidgets('disabled for cancelledByRider', (WidgetTester tester) async {
        await loadRideCard(tester,
            status: RideStatus.cancelledByRider, destinationTime: DateTime.now().add(const Duration(minutes: 10)));

        expect(find.byKey(const Key('cancelledOrRejectedIcon')), findsOneWidget);

        final BuildContext context = tester.element(find.byType(Container).first);
        expect(tester.widget<Card>(find.byType(Card)).color, Theme.of(context).disabledColor);
      });

      testWidgets('disabled for withdrawn', (WidgetTester tester) async {
        await loadRideCard(tester,
            status: RideStatus.cancelledByRider, destinationTime: DateTime.now().add(const Duration(minutes: 10)));

        expect(find.byKey(const Key('cancelledOrRejectedIcon')), findsOneWidget);

        final BuildContext context = tester.element(find.byType(Container).first);
        expect(tester.widget<Card>(find.byType(Card)).color, Theme.of(context).disabledColor);
      });

      testWidgets('primary and price for preview', (WidgetTester tester) async {
        await loadRideCard(tester,
            status: RideStatus.preview, destinationTime: DateTime.now().add(const Duration(minutes: 10)));

        expect(find.byKey(const Key('price')), findsOneWidget);

        final BuildContext context = tester.element(find.byType(Container).first);
        expect(tester.widget<Card>(find.byType(Card)).color, Theme.of(context).colorScheme.primary);
      });

      testWidgets('disabled for past Ride', (WidgetTester tester) async {
        await loadRideCard(tester, destinationTime: DateTime.now().subtract(const Duration(minutes: 10)));

        final BuildContext context = tester.element(find.byType(Container).first);
        expect(tester.widget<Card>(find.byType(Card)).color, Theme.of(context).disabledColor);
      });
    });

    testWidgets('can Navigate to RideDetailPage', (WidgetTester tester) async {
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
    Future<void> loadDriveCard(WidgetTester tester, Drive drive) async {
      whenRequest(processor).thenReturnJson(drive.toJsonForApi());
      await pumpMaterial(tester, DriveCard(drive));
      //wait for card to load
      await tester.pump();
    }

    testWidgets('shows seat indicator', (WidgetTester tester) async {
      drive = DriveFactory().generateFake();
      await loadDriveCard(tester, drive);

      expect(find.byType(SeatIndicator), findsOneWidget);
    });

    group('shows the right status', () {
      testWidgets('disabled status for past Drive', (WidgetTester tester) async {
        //drive in the past
        drive = DriveFactory().generateFake(
          destinationDateTime: DateTime.now().subtract(const Duration(hours: 1)),
        );
        await loadDriveCard(tester, drive);

        final BuildContext context = tester.element(find.byType(Container).first);
        expect(tester.widget<Card>(find.byType(Card)).color, Theme.of(context).disabledColor);
      });
      testWidgets('error status cancelled Drive', (WidgetTester tester) async {
        //cancelled drive in the future
        drive = DriveFactory().generateFake(
          destinationDateTime: DateTime.now().add(const Duration(hours: 1)),
          status: DriveStatus.cancelledByDriver,
        );
        await loadDriveCard(tester, drive);

        expect(find.byKey(const Key('cancelledIcon')), findsOneWidget);

        final BuildContext context = tester.element(find.byType(Container).first);
        expect(tester.widget<Card>(find.byType(Card)).color, Theme.of(context).colorScheme.error);
      });

      testWidgets('warning status for drive with ride requests', (WidgetTester tester) async {
        //drive in the future with ride requests
        drive = DriveFactory().generateFake(
          destinationDateTime: DateTime.now().add(const Duration(hours: 1)),
          rides: [RideFactory().generateFake(status: RideStatus.pending)],
        );
        await loadDriveCard(tester, drive);

        expect(find.byKey(const Key('pendingIcon')), findsOneWidget);

        final BuildContext context = tester.element(find.byType(Container).first);
        expect(tester.widget<Card>(find.byType(Card)).color, Theme.of(context).own().warning);
      });

      testWidgets('successColor for drive with only approved rides', (WidgetTester tester) async {
        //drive in the future with approved rides
        drive = DriveFactory().generateFake(
          destinationDateTime: DateTime.now().add(const Duration(hours: 1)),
          rides: [RideFactory().generateFake(status: RideStatus.approved)],
        );
        await loadDriveCard(tester, drive);

        final BuildContext context = tester.element(find.byType(Container).first);
        expect(tester.widget<Card>(find.byType(Card)).color, Theme.of(context).own().success);
      });

      testWidgets('disabledColor for drive with no rides', (WidgetTester tester) async {
        //drive in the future with no rides
        drive = DriveFactory().generateFake(
          destinationDateTime: DateTime.now().add(const Duration(hours: 1)),
          rides: [],
        );
        await loadDriveCard(tester, drive);

        final BuildContext context = tester.element(find.byType(Container).first);
        expect(tester.widget<Card>(find.byType(Card)).color, Theme.of(context).disabledColor);
      });
    });

    testWidgets('can Navigate to Drive DetailPage', (WidgetTester tester) async {
      drive = DriveFactory().generateFake();
      await loadDriveCard(tester, drive);

      //open DriveDetailPage
      await tester.tap(find.byType(DriveCard));

      //load page
      await tester.pump();
      await tester.pump();

      expect(find.byType(DriveDetailPage), findsOneWidget);
    });
  });
}
