import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../account/models/profile.dart';
import '../../account/pages/write_review_page.dart';
import '../../account/widgets/features_column.dart';
import '../../account/widgets/reviews_preview.dart';
import '../../drives/models/drive.dart';
import '../../util/buttons/button.dart';
import '../../util/buttons/custom_banner.dart';
import '../../util/profiles/profile_widget.dart';
import '../../util/profiles/profile_wrap_list.dart';
import '../../util/supabase.dart';
import '../../util/trip/trip_overview.dart';
import '../../welcome/pages/login_page.dart';
import '../../welcome/pages/register_page.dart';
import '../models/ride.dart';

class RideDetailPage extends StatefulWidget {
  // One of these two must be set
  final int? id;
  final Ride? ride;

  const RideDetailPage({super.key, required this.id}) : ride = null;
  RideDetailPage.fromRide(this.ride, {super.key}) : id = ride!.id;

  @override
  State<RideDetailPage> createState() => _RideDetailPageState();
}

class _RideDetailPageState extends State<RideDetailPage> {
  static const String _driveQuery = '''
    *,
    driver: driver_id(
      *,
      reviews_received: reviews!reviews_receiver_id_fkey(
        *,
        writer: writer_id(*)
      ),
      profile_features(*)
    ),
    rides(
      *,
      rider: rider_id(*)
    )
  ''';
  static const String _rideQuery = '''
        *,
        drive: drive_id(
          $_driveQuery
        )
      ''';

  Ride? _ride;
  bool _fullyLoaded = false;

  @override
  void initState() {
    super.initState();

    setState(() {
      _ride = widget.ride;
    });

    loadRide();
  }

  Future<void> loadRide() async {
    Ride ride;
    if (_ride?.status == RideStatus.preview) {
      ride = _ride!;

      Map<String, dynamic> data =
          await SupabaseManager.supabaseClient.from('drives').select(_driveQuery).eq('id', ride.driveId).single();

      ride.drive = Drive.fromJson(data);
    } else {
      int id = _ride?.id ?? widget.id!;
      Map<String, dynamic> data =
          await SupabaseManager.supabaseClient.from('rides').select(_rideQuery).eq('id', id).single();
      ride = Ride.fromJson(data);
    }

    setState(() {
      _ride = ride;
      _fullyLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = <Widget>[];

    if (_ride != null) {
      widgets.add(TripOverview(_ride!));
      widgets.add(const Divider(thickness: 1));
    }

    if (_fullyLoaded) {
      Ride ride = _ride!;

      Profile driver = ride.drive!.driver!;
      widgets.add(ProfileWidget(driver, showDescription: true));
      widgets.add(const Divider(thickness: 1));

      widgets.add(ReviewsPreview(driver));

      if (driver.profileFeatures!.isNotEmpty) widgets.add(const Divider(thickness: 1));
      widgets.add(FeaturesColumn(driver.profileFeatures!));

      if (ride.status == RideStatus.approved || ride.status == RideStatus.cancelledByDriver) {
        widgets.add(const Divider(thickness: 1));

        Set<Profile> riders = ride.drive!.rides!
            .where((Ride otherRide) => ride.overlapsWith(otherRide))
            .map((Ride ride) => ride.rider!)
            .toSet();
        widgets.add(ProfileWrapList(riders, title: S.of(context).riders));
      }

      Widget? primaryButton = _buildPrimaryButton(driver);
      if (primaryButton != null) {
        widgets.add(const SizedBox(height: 10));
        widgets.add(primaryButton);
        widgets.add(const SizedBox(height: 5));
      }
    } else {
      widgets.add(const SizedBox(height: 10));
      widgets.add(const Center(child: CircularProgressIndicator()));
    }

    Widget content = Column(
      children: <Widget>[
        if (_ride != null && _ride!.status == RideStatus.pending)
          CustomBanner.warning(S.of(context).pageRideDetailBannerRequested, key: const Key('rideRequestedBanner'))
        else if (_ride != null && _ride!.status == RideStatus.rejected)
          CustomBanner.error(S.of(context).pageRideDetailBannerRejected, key: const Key('rideRejectedBanner'))
        else if (_ride?.status.isCancelled() ?? false)
          _ride!.status == RideStatus.cancelledByDriver
              ? CustomBanner.error(
                  S.of(context).pageRideDetailBannerCancelledByDriver,
                  key: const Key('rideCancelledByDriverBanner'),
                )
              : CustomBanner.error(
                  S.of(context).pageRideDetailBannerCancelledByYou,
                  key: const Key('rideCancelledByYouBanner'),
                ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: widgets,
          ),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).pageRideDetailTitle),
        actions: <Widget>[
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.chat),
            tooltip: S.of(context).openChat,
            key: const Key('chatButton'),
          )
        ],
      ),
      body: _ride == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadRide,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: content,
              ),
            ),
    );
  }

  Widget? _buildPrimaryButton(Profile driver) {
    switch (_ride!.status) {
      case RideStatus.preview:
      case RideStatus.withdrawnByRider:
        return Button(
          S.of(context).pageRideDetailButtonRequest,
          onPressed: SupabaseManager.getCurrentProfile() == null ? _showLoginDialog : _showRequestDialog,
          key: const Key('requestRideButton'),
        );
      case RideStatus.approved:
        return _ride!.isFinished
            ? Button(
                S.of(context).pageRideDetailButtonRate,
                onPressed: () => _navigateToRatePage(driver),
                key: const Key('rateDriverButton'),
              )
            : Button.error(
                S.of(context).pageRideDetailButtonCancel,
                onPressed: _showCancelDialog,
                key: const Key('cancelRideButton'),
              );
      case RideStatus.pending:
        return Button.error(
          S.of(context).pageRideDetailButtonWithdraw,
          onPressed: _showWithdrawDialog,
          key: const Key('withdrawRideButton'),
        );
      case RideStatus.cancelledByDriver:
      case RideStatus.rejected:
      case RideStatus.cancelledByRider:
        return Button.error(
          S.of(context).pageRideDetailButtonHide,
          onPressed: _showHideDialog,
          key: const Key('hideRideButton'),
        );
    }
  }

  void _navigateToRatePage(Profile driver) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (BuildContext context) => WriteReviewPage(driver)))
        .then((_) => loadRide());
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(S.of(context).pageRideDetailCancelDialogTitle),
        content: Text(S.of(context).pageRideDetailCancelDialogMessage),
        actions: <Widget>[
          TextButton(
            key: const Key('cancelRideNoButton'),
            child: Text(S.of(context).no),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            key: const Key('cancelRideYesButton'),
            child: Text(S.of(context).yes),
            onPressed: () {
              _cancelRide();

              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(S.of(context).pageRideDetailCancelDialogToast),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _cancelRide() async {
    await _ride?.cancel();
    setState(() {});
  }

  void _showRequestDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(S.of(context).pageRideDetailRequestDialogTitle),
        content: Text(S.of(context).pageRideDetailRequestDialogMessage),
        actions: <Widget>[
          TextButton(
            key: const Key('requestRideNoButton'),
            child: Text(S.of(context).no),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          TextButton(
            key: const Key('requestRideYesButton'),
            child: Text(S.of(context).yes),
            onPressed: () {
              confirmRequest(_ride!);
              Navigator.of(dialogContext).pop();
            },
          ),
        ],
      ),
    );
  }

  void hideRide() async {
    await SupabaseManager.supabaseClient
        .from('rides')
        .update(<String, dynamic>{'hide_in_list_view': true}).eq('id', widget.ride!.id);
  }

  void _showHideDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(S.of(context).pageRideDetailButtonHide),
        content: Text(S.of(context).pageRideDetailHideDialog),
        actions: <Widget>[
          TextButton(
            key: const Key('hideRideNoButton'),
            child: Text(S.of(context).no),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          TextButton(
            key: const Key('hideRideYesButton'),
            child: Text(S.of(context).yes),
            onPressed: () {
              hideRide();
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  void confirmRequest(Ride ride) async {
    ride.status = RideStatus.pending;
    Map<String, dynamic> data =
        await SupabaseManager.supabaseClient.from('rides').insert(ride.toJson()).select(_rideQuery).single();
    setState(() {
      _ride = Ride.fromJson(data);
    });
    //todo: send notification to driver
  }

  void _showWithdrawDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(S.of(context).pageRideDetailWithdrawDialogTitle),
        content: Text(S.of(context).pageRideDetailWithdrawDialogMessage),
        actions: <Widget>[
          TextButton(
            key: const Key('withdrawRideNoButton'),
            child: Text(S.of(context).no),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            key: const Key('withdrawRideYesButton'),
            child: Text(S.of(context).yes),
            onPressed: () {
              _withdrawRide();

              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(S.of(context).pageRideDetailWithdrawDialogToast),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _withdrawRide() async {
    await _ride?.withdraw();
    setState(() {});
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(S.of(context).pageRideDetailLoginDialogTitle),
        content: Text(S.of(context).pageRideDetailLoginDialogMessage),
        actions: <Widget>[
          TextButton(
            key: const Key('loginRideCancelButton'),
            child: Text(S.of(context).cancel),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          TextButton(
            key: const Key('loginRideLoginButton'),
            child: Text(S.of(context).pageWelcomeLogin),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.popUntil(context, (Route<void> route) => route.isFirst);
              Navigator.push(context, MaterialPageRoute<void>(builder: (BuildContext context) => const LoginPage()));
            },
          ),
          TextButton(
            key: const Key('loginRideRegisterButton'),
            child: Text(S.of(context).pageWelcomeRegister),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.popUntil(context, (Route<void> route) => route.isFirst);
              Navigator.push(context, MaterialPageRoute<void>(builder: (BuildContext context) => const RegisterPage()));
            },
          ),
        ],
      ),
    );
  }
}
