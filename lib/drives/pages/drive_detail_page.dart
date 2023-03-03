import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:timelines/timelines.dart';

import '../../account/models/profile.dart';
import '../../rides/models/ride.dart';
import '../../util/buttons/button.dart';
import '../../util/buttons/custom_banner.dart';
import '../../util/chat/pages/chat_page.dart';
import '../../util/custom_timeline_theme.dart';
import '../../util/icon_widget.dart';
import '../../util/locale_manager.dart';
import '../../util/own_theme_fields.dart';
import '../../util/profiles/profile_widget.dart';
import '../../util/profiles/profile_wrap_list.dart';
import '../../util/snackbar.dart';
import '../../util/supabase_manager.dart';
import '../../util/trip/drive_overview.dart';
import '../../util/trip/pending_ride_card.dart';
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
    final Map<String, dynamic> data =
        await supabaseManager.supabaseClient.from('drives').select<Map<String, dynamic>>('''
      *,
      rides(
        *,
        rider: rider_id(*),
        chat: chat_id(
          *,
          messages: messages!messages_chat_id_fkey(*)
        )
      )
    ''').eq('id', widget.id).single();

    setState(() {
      _drive = Drive.fromJson(data);
      _fullyLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> widgets = <Widget>[];

    if (_drive != null) {
      widgets.add(DriveOverview(_drive!));
      widgets.add(const Divider(thickness: 1));
    }

    if (_fullyLoaded) {
      final Drive drive = _drive!;

      final List<Waypoint> stops = <Waypoint>[];
      stops.add(
        Waypoint(
          actions: <WaypointAction>[],
          place: drive.start,
          time: drive.startTime,
        ),
      );
      stops.add(
        Waypoint(
          actions: <WaypointAction>[],
          place: drive.end,
          time: drive.endTime,
        ),
      );
      final List<Ride> approvedRides = drive.approvedRides!;
      for (final Ride ride in approvedRides) {
        bool startSaved = false;
        bool endSaved = false;

        final WaypointAction rideStartAction = WaypointAction(ride, isStart: true);
        final WaypointAction rideEndAction = WaypointAction(ride, isStart: false);
        for (final Waypoint stop in stops) {
          if (ride.start == stop.place) {
            startSaved = true;
            stop.actions.add(rideStartAction);
          } else if (ride.end == stop.place) {
            endSaved = true;
            stop.actions.add(rideEndAction);
          }
        }

        if (!startSaved) {
          stops.add(
            Waypoint(
              actions: <WaypointAction>[rideStartAction],
              place: ride.start,
              time: ride.startTime,
            ),
          );
        }

        if (!endSaved) {
          stops.add(
            Waypoint(
              actions: <WaypointAction>[rideEndAction],
              place: ride.end,
              time: ride.endTime,
            ),
          );
        }
      }

      stops.sort((Waypoint a, Waypoint b) {
        final int timeDiff = a.time.compareTo(b.time);
        if (timeDiff != 0) return timeDiff;
        if (a.place == drive.start || b.place == drive.end) return -1;
        if (a.place == drive.end || b.place == drive.start) return 1;

        return 0;
      });
      for (final Waypoint stop in stops) {
        stop.actions.sort((WaypointAction a, WaypointAction b) => a.isStart ? 1 : -1);
      }

      final Widget timeline = FixedTimeline.tileBuilder(
        theme: CustomTimelineTheme.of(context, forBuilder: true),
        builder: TimelineTileBuilder.connected(
          connectionDirection: ConnectionDirection.before,
          indicatorBuilder: (BuildContext context, int index) => const CustomOutlinedDotIndicator(),
          connectorBuilder: (BuildContext context, int index, ConnectorType type) => const CustomSolidLineConnector(),
          contentsBuilder: (BuildContext context, int index) {
            final Waypoint stop = stops[index];
            return Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 10.0),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    padding: const EdgeInsets.all(8.0),
                    width: double.infinity,
                    child: Column(
                      key: const Key('waypointCard'),
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
        final Set<Profile> riders = approvedRides.map((Ride ride) => ride.rider!).toSet();
        widgets.add(ProfileWrapList(riders, title: S.of(context).riders));
      }

      final List<Ride> pendingRides = _drive!.pendingRides!.toList();
      if (pendingRides.isNotEmpty) {
        final List<Widget> pendingRidesColumn = <Widget>[
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
          key: const Key('hideDriveButton'),
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

    final Widget content = Column(
      children: <Widget>[
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
        actions: <Widget>[buildChatButton()],
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
    final String tooltip = S.of(context).openChat;
    const Icon icon = Icon(Icons.chat);

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
        MaterialPageRoute<void>(
          builder: (BuildContext context) => DriveChatPage(
            drive: _drive!,
          ),
        ),
      ).then((_) => loadDrive()),
      icon: badges.Badge(
        badgeContent: Text(
          _drive!.getUnreadMessagesCount().toString(),
          style: const TextStyle(color: Colors.white),
          textScaleFactor: 1.0,
        ),
        showBadge: _drive!.getUnreadMessagesCount() != 0,
        position: badges.BadgePosition.topEnd(top: -12),
        child: icon,
      ),
      tooltip: tooltip,
    );
  }

  List<Widget> buildCard(Waypoint waypoint) {
    final List<Widget> list = <Widget>[];
    list.add(
      MergeSemantics(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                localeManager.formatTime(waypoint.time),
                style: Theme.of(context).textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 4.0),
              Flexible(child: Text(waypoint.place)),
              if (waypoint.place == _drive!.start)
                Semantics(label: S.of(context).pageDriveDetailLabelStartDrive)
              else if (waypoint.place == _drive!.end)
                Semantics(label: S.of(context).pageDriveDetailLabelEndDrive),
            ],
          ),
        ),
      ),
    );

    final Icon startIcon = Icon(Icons.north_east_rounded, color: Theme.of(context).own().success);
    final Icon endIcon = Icon(Icons.south_west_rounded, color: Theme.of(context).colorScheme.error);
    final int actionsLength = waypoint.actions.length;
    for (int index = 0; index < actionsLength; index++) {
      final WaypointAction action = waypoint.actions[index];
      final Icon icon = action.isStart ? startIcon : endIcon;
      final Profile profile = action.ride.rider!;
      final Widget container = Semantics(
        button: true,
        label: action.isStart
            ? S.of(context).pageDriveDetailLabelPickup(action.ride.seats, profile.username)
            : S.of(context).pageDriveDetailLabelDropoff(action.ride.seats, profile.username),
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
              key: Key('chatPageButton${action.ride.id}${action.isStart ? 'Start' : 'End'}'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => ChatPage(
                    chatId: action.ride.chatId,
                    profile: profile,
                  ),
                ),
              ).then((_) => loadDrive()),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
                child: Row(
                  children: <Widget>[
                    IconWidget(icon: icon, count: action.ride.seats),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: ProfileWidget(profile, size: 15, isTappable: false),
                      ),
                    ),
                    badges.Badge(
                      badgeContent: Text(
                        action.ride.chat!.getUnreadMessagesCount().toString(),
                        style: const TextStyle(color: Colors.white),
                        textScaleFactor: 1.0,
                      ),
                      showBadge: action.ride.chat!.getUnreadMessagesCount() != 0,
                      position: badges.BadgePosition.topEnd(top: -12),
                      child: const Icon(Icons.chat),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      list.add(container);

      if (index < actionsLength - 1) {
        list.add(const SizedBox(height: 6.0));
      }
    }

    return list;
  }

  Future<void> hideDrive() async {
    await supabaseManager.supabaseClient
        .from('drives')
        .update(<String, dynamic>{'hide_in_list_view': true}).eq('id', widget.drive!.id);
  }

  void _showHideDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(S.of(context).pageDriveDetailButtonHide),
        content: Text(S.of(context).pageDriveDetailHideDialog),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            key: const Key('hideDriveNoButton'),
            child: Text(S.of(context).no),
          ),
          TextButton(
            onPressed: () {
              hideDrive();
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop();
            },
            key: const Key('hideDriveYesButton'),
            child: Text(S.of(context).yes),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelDrive() async {
    await _drive?.cancel();
    setState(() {});
  }

  void _showCancelDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
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
              showSnackBar(
                context,
                S.of(context).pageDriveDetailCancelDialogToast,
                durationType: SnackBarDurationType.medium,
              );
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _pendingRidesList(List<Ride> pendingRides) {
    List<Widget> pendingRidesColumn = <Widget>[];
    if (pendingRides.isNotEmpty) {
      pendingRidesColumn = List<PendingRideCard>.generate(
        pendingRides.length,
        (int index) => PendingRideCard(
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
  final Ride ride;
  final bool isStart;

  WaypointAction(this.ride, {required this.isStart});
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
