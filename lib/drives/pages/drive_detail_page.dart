import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:timelines/timelines.dart';

import '../../account/models/profile.dart';
import '../../rides/models/ride.dart';
import '../../util/buttons/button.dart';
import '../../util/buttons/custom_banner.dart';
import '../../util/custom_timeline_theme.dart';
import '../../util/icon_widget.dart';
import '../../util/locale_manager.dart';
import '../../util/own_theme_fields.dart';
import '../../util/profiles/profile_widget.dart';
import '../../util/profiles/profile_wrap_list.dart';
import '../../util/supabase.dart';
import '../../util/trip/pending_ride_card.dart';
import '../../util/trip/trip_overview.dart';
import '../models/drive.dart';
import 'drive_chat_page.dart';

class DriveDetailPage extends StatefulWidget {
  final int id;
  final Drive? drive;

  const DriveDetailPage({super.key, required this.id}) : drive = null;
  DriveDetailPage.fromDrive(this.drive, {super.key}) : id = drive!.id!;

  @override
  State<DriveDetailPage> createState() => _DriveDetailPageState();
}

class _DriveDetailPageState extends State<DriveDetailPage> {
  Drive? _drive;
  bool _fullyLoaded = false;

  @override
  void initState() {
    super.initState();

    setState(() {
      _drive = widget.drive;
    });

    loadDrive();
  }

  Future<void> loadDrive() async {
    Map<String, dynamic> data = await SupabaseManager.supabaseClient.from('drives').select('''
      *,
      rides(
        *,
        rider: rider_id(*)
      )
    ''').eq('id', widget.id).single();

    setState(() {
      _drive = Drive.fromJson(data);
      _fullyLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [];

    if (_drive != null) {
      widgets.add(TripOverview(_drive!));
      widgets.add(const Divider(thickness: 1));
    }

    if (_fullyLoaded) {
      Drive drive = _drive!;

      List<Waypoint> stops = [];
      stops.add(Waypoint(
        actions: [],
        place: drive.start,
        time: drive.startTime,
      ));
      stops.add(Waypoint(
        actions: [],
        place: drive.end,
        time: drive.endTime,
      ));
      List<Ride> approvedRides = drive.approvedRides!;
      for (Ride ride in approvedRides) {
        bool startSaved = false;
        bool endSaved = false;

        WaypointAction rideStartAction = WaypointAction(profile: ride.rider!, isStart: true, seats: ride.seats);
        WaypointAction rideEndAction = WaypointAction(profile: ride.rider!, isStart: false, seats: ride.seats);
        for (Waypoint stop in stops) {
          if (ride.start == stop.place) {
            startSaved = true;
            stop.actions.add(rideStartAction);
          } else if (ride.end == stop.place) {
            endSaved = true;
            stop.actions.add(rideEndAction);
          }
        }

        if (!startSaved) {
          stops.add(Waypoint(
            actions: [rideStartAction],
            place: ride.start,
            time: ride.startTime,
          ));
        }

        if (!endSaved) {
          stops.add(Waypoint(
            actions: [rideEndAction],
            place: ride.end,
            time: ride.endTime,
          ));
        }
      }

      stops.sort((a, b) => a.time.compareTo(b.time));
      for (Waypoint stop in stops) {
        stop.actions.sort((a, b) => a.isStart ? 1 : -1);
      }

      Widget timeline = FixedTimeline.tileBuilder(
        theme: CustomTimelineThemeForBuilder.of(context),
        builder: TimelineTileBuilder.connected(
          connectionDirection: ConnectionDirection.before,
          indicatorBuilder: (context, index) => const CustomOutlinedDotIndicator(),
          connectorBuilder: (context, index, type) => const CustomSolidLineConnector(),
          contentsBuilder: (context, index) {
            final stop = stops[index];
            return Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Column(
                children: [
                  const SizedBox(height: 10.0),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(width: 1.0, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    padding: const EdgeInsets.all(8.0),
                    width: double.infinity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: buildCard(stop),
                    ),
                  ),
                  const SizedBox(height: 10.0)
                ],
              ),
            );
          },
          itemCount: stops.length,
        ),
      );
      widgets.add(timeline);

      if (approvedRides.isNotEmpty) {
        widgets.add(const Divider(thickness: 1));
        Set<Profile> riders = approvedRides.map((ride) => ride.rider!).toSet();
        widgets.add(ProfileWrapList(riders, title: S.of(context).riders));
      }

      List<Ride> pendingRides = _drive!.pendingRides!.toList();
      if (pendingRides.isNotEmpty) {
        List<Widget> pendingRidesColumn = [
          const SizedBox(height: 5.0),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              S.of(context).pageDriveChatRequestsHeadline,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 10.0),
          ..._pendingRidesList(pendingRides)
        ];
        widgets.addAll(pendingRidesColumn);
      }

      widgets.add(const SizedBox(height: 10));
      Widget bottomButton;
      if (_drive!.isFinished || _drive!.cancelled) {
        bottomButton = Button.error(
          S.of(context).pageDriveDetailButtonHide,
          onPressed: _showHideDialog,
        );
      } else {
        bottomButton = Button.error(
          S.of(context).pageDriveDetailButtonCancel,
          onPressed: _showCancelDialog,
          key: const Key('cancelDriveButton'),
        );
      }
      widgets.add(bottomButton);
      widgets.add(const SizedBox(height: 5));
    } else {
      widgets.add(const SizedBox(height: 10));
      widgets.add(const Center(child: CircularProgressIndicator()));
    }

    Widget content = Column(
      children: [
        if (_drive?.cancelled ?? false)
          CustomBanner.error(
            S.of(context).pageDriveDetailBannerCancelled,
            key: const Key('cancelledDriveBanner'),
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
        title: Text(S.of(context).pageDriveDetailTitle),
        actions: [buildChatButton()],
      ),
      body: _drive == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadDrive,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: content,
              ),
            ),
    );
  }

  Widget buildChatButton() {
    String tooltip = S.of(context).openChat;
    Icon icon = const Icon(Icons.chat);

    if (!_fullyLoaded) {
      return IconButton(
        onPressed: null,
        icon: icon,
        tooltip: tooltip,
      );
    }

    return IconButton(
      key: const Key('driveChatButton'),
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DriveChatPage(
            drive: _drive!,
          ),
        ),
      ).then((value) => loadDrive()),
      icon: Badge(
        badgeContent: Text(
          _getMessageCount(_drive!).toString(),
          style: const TextStyle(color: Colors.white),
          textScaleFactor: 1.0,
        ),
        showBadge: _getMessageCount(_drive!) != 0,
        position: BadgePosition.topEnd(top: -12),
        child: icon,
      ),
      tooltip: tooltip,
    );
  }

  List<Widget> buildCard(Waypoint stop) {
    List<Widget> list = [];
    list.add(
      MergeSemantics(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                localeManager.formatTime(stop.time),
                style: Theme.of(context).textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 4.0),
              Text(stop.place),
              if (stop.place == _drive!.start) Semantics(label: S.of(context).pageDriveDetailLabelStartDrive),
              if (stop.place == _drive!.end) Semantics(label: S.of(context).pageDriveDetailLabelEndDrive),
            ],
          ),
        ),
      ),
    );

    final startIcon = Icon(Icons.north_east_rounded, color: Theme.of(context).own().success);
    final endIcon = Icon(Icons.south_west_rounded, color: Theme.of(context).colorScheme.error);
    for (int index = 0, length = stop.actions.length; index < length; index++) {
      final action = stop.actions[index];
      final icon = action.isStart ? startIcon : endIcon;
      final profile = action.profile;

      Widget container = Semantics(
        button: true,
        label: action.isStart
            ? S.of(context).pageDriveDetailLabelPickup(action.seats, action.profile.username)
            : S.of(context).pageDriveDetailLabelDropoff(action.seats, action.profile.username),
        excludeSemantics: true,
        tooltip: S.of(context).openChat,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            borderRadius: const BorderRadius.all(Radius.circular(5.0)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              //TODO go to chat
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: IconWidget(icon: icon, count: action.seats),
                      ),
                    ),
                    ProfileWidget(profile, size: 15, isTappable: false),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Icon(
                          Icons.chat,
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 30.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      list.add(container);

      if (index < length - 1) {
        list.add(const SizedBox(height: 6.0));
      }
    }

    return list;
  }

  void hideDrive() async {
    await SupabaseManager.supabaseClient.from('drives').update({'hide_in_list_view': true}).eq('id', widget.drive!.id);
  }

  void _showHideDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(S.of(context).pageDriveDetailButtonHide),
        content: Text(S.of(context).pageDriveDetailHideDialog),
        actions: <Widget>[
          TextButton(
            child: Text(S.of(context).no),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          TextButton(
            child: Text(S.of(context).yes),
            onPressed: () {
              hideDrive();
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  void _cancelDrive() async {
    await _drive?.cancel();
    setState(() {});
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).pageDriveDetailCancelDialogTitle),
        content: Text(S.of(context).pageDriveDetailCancelDialogMessage),
        actions: <Widget>[
          TextButton(
            key: const Key('cancelDriveNoButton'),
            child: Text(S.of(context).no),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            key: const Key('cancelDriveYesButton'),
            child: Text(S.of(context).yes),
            onPressed: () {
              _cancelDrive();

              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(S.of(context).pageDriveDetailCancelDialogToast),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  int _getMessageCount(Drive drive) {
    return 0;
  }

  List<Widget> _pendingRidesList(List<Ride> pendingRides) {
    List<Widget> pendingRidesColumn = [];
    if (pendingRides.isNotEmpty) {
      pendingRidesColumn = List.generate(
        pendingRides.length,
        (index) => PendingRideCard(
          pendingRides.elementAt(index),
          reloadPage: loadDrive,
          drive: _drive!,
        ),
      );
    }
    return pendingRidesColumn;
  }
}

class WaypointAction {
  final Profile profile;
  final bool isStart;
  final int seats;

  WaypointAction({required this.profile, required this.isStart, required this.seats});
}

class Waypoint {
  List<WaypointAction> actions;
  final String place;
  final DateTime time;

  Waypoint({
    required this.actions,
    required this.place,
    required this.time,
  });
}
