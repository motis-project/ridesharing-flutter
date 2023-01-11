import 'package:flutter/material.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/account/pages/write_review_page.dart';
import 'package:motis_mitfahr_app/account/widgets/review_detail.dart';
import 'package:motis_mitfahr_app/drives/models/drive.dart';
import 'package:motis_mitfahr_app/rides/models/ride.dart';
import 'package:motis_mitfahr_app/util/buttons/button.dart';
import 'package:motis_mitfahr_app/util/buttons/custom_banner.dart';
import 'package:motis_mitfahr_app/util/profiles/reviews/custom_rating_bar_indicator.dart';
import 'package:motis_mitfahr_app/util/profiles/profile_widget.dart';
import 'package:motis_mitfahr_app/util/profiles/profile_wrap_list.dart';
import 'package:motis_mitfahr_app/util/profiles/reviews/custom_rating_bar_size.dart';
import 'package:motis_mitfahr_app/util/supabase.dart';
import 'package:motis_mitfahr_app/util/trip/trip_overview.dart';
import 'package:motis_mitfahr_app/account/widgets/features_column.dart';
import 'package:motis_mitfahr_app/account/widgets/reviews_preview.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../welcome/pages/login_page.dart';
import '../../welcome/pages/register_page.dart';

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
          await supabaseClient.from('drives').select(_driveQuery).eq('id', ride.driveId).single();

      ride.drive = Drive.fromJson(data);
    } else {
      Map<String, dynamic> data = await supabaseClient.from('rides').select(_rideQuery).eq('id', widget.id!).single();
      ride = Ride.fromJson(data);
    }

    setState(() {
      _ride = ride;
      _fullyLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [];

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

      if (ride.status != RideStatus.preview && ride.status != RideStatus.pending) {
        widgets.add(const Divider(thickness: 1));

        Set<Profile> riders =
            ride.drive!.rides!.where((otherRide) => ride.overlapsWith(otherRide)).map((ride) => ride.rider!).toSet();
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
      children: [
        if (_ride != null && _ride!.status == RideStatus.pending)
          CustomBanner.warning(S.of(context).pageRideDetailBannerRequested)
        else if (_ride != null && _ride!.status == RideStatus.rejected)
          CustomBanner.error(S.of(context).pageRideDetailBannerRejected)
        else if (_ride?.status.isCancelled() ?? false)
          CustomBanner.error(
            _ride!.status == RideStatus.cancelledByDriver
                ? S.of(context).pageRideDetailBannerCancelledByDriver
                : S.of(context).pageRideDetailBannerCancelledByYou,
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
        return Button(
          S.of(context).pageRideDetailButtonRequest,
          onPressed: SupabaseManager.getCurrentProfile() == null ? _showLoginDialog : _showRequestDialog,
        );
      case RideStatus.approved:
        return _ride!.isFinished
            ? Button(S.of(context).pageRideDetailButtonRate, onPressed: () => _navigateToRatePage(driver))
            : Button.error(S.of(context).pageRideDetailButtonCancel, onPressed: _showCancelDialog);
      case RideStatus.pending:
        return Button(
          S.of(context).pageRideDetailButtonRequested,
          backgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        );
      default:
        return null;
    }
  }

  void _navigateToRatePage(Profile driver) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(builder: (context) => WriteReviewPage(driver)),
        )
        .then((value) => loadRide());
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).pageRideDetailCancelDialogTitle),
        content: Text(S.of(context).pageRideDetailCancelDialogMessage),
        actions: <Widget>[
          TextButton(
            child: Text(S.of(context).no),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
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

  _showRequestDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(S.of(context).pageRideDetailRequestDialogTitle),
        content: Text(S.of(context).pageRideDetailRequestDialogMessage),
        actions: <Widget>[
          TextButton(
            child: Text(S.of(context).no),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          TextButton(
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

  void confirmRequest(Ride ride) async {
    ride.status = RideStatus.pending;
    final data = await supabaseClient.from('rides').insert(ride.toJson()).select(_rideQuery).single();
    setState(() {
      _ride = Ride.fromJson(data);
    });
    //todo: send notification to driver
  }

  _showLoginDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(S.of(context).pageRideDetailLoginDialogTitle),
        content: Text(S.of(context).pageRideDetailLoginDialogMessage),
        actions: <Widget>[
          TextButton(
            child: Text(S.of(context).cancel),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          TextButton(
              child: Text(S.of(context).pageWelcomeLogin),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.popUntil(context, (route) => route.isFirst);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
              }),
          TextButton(
            child: Text(S.of(context).pageWelcomeRegister),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.popUntil(context, (route) => route.isFirst);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage()));
            },
          ),
        ],
      ),
    );
  }
}
