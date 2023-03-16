import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:timelines/timelines.dart';

import '../../account/models/profile.dart';
import '../../account/widgets/profile_widget.dart';
import '../../account/widgets/profile_wrap_list.dart';
import '../../chat/pages/chat_page.dart';
import '../../managers/locale_manager.dart';
import '../../managers/supabase_manager.dart';
import '../../trips/cards/pending_ride_card.dart';
import '../../trips/models/trip.dart';
import '../../trips/util/custom_timeline_theme.dart';
import '../../trips/util/trip_overview.dart';
import '../../util/buttons/button.dart';
import '../../util/buttons/custom_banner.dart';
import '../../util/icon_widget.dart';
import '../../util/own_theme_fields.dart';
import '../../util/snackbar.dart';
import '../models/drive.dart';
import '../models/ride.dart';
import 'drive_chat_page.dart';

class DriveDetailPage extends StatefulWidget {
  final int? id;
  final Drive? drive;

  const DriveDetailPage({super.key, required this.id}) : drive = null;
  DriveDetailPage.fromDrive(this.drive, {super.key}) : id = drive!.id;

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
    if (_drive?.status != DriveStatus.preview) {
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
      _drive = Drive.fromJson(data);
    }

    setState(() {
      _fullyLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> widgets = <Widget>[];

    if (_drive != null) {
      widgets.add(TripOverview(_drive!));
    }

    if (_fullyLoaded) {
      final Drive drive = _drive!;

      final List<Waypoint> stops = <Waypoint>[];
      stops.add(
        Waypoint(
          actions: <WaypointAction>[],
          place: drive.start,
          time: drive.startDateTime,
        ),
      );
      stops.add(
        Waypoint(
          actions: <WaypointAction>[],
          place: drive.destination,
          time: drive.destinationDateTime,
        ),
      );
      final List<Ride> visibleRides = drive.status == DriveStatus.plannedOrFinished
          ? drive.approvedRides
          : drive.rides!.where((Ride ride) => ride.status == RideStatus.cancelledByDriver).toList();
      for (final Ride ride in visibleRides) {
        bool startSaved = false;
        bool destinationSaved = false;

        final WaypointAction rideStartAction = WaypointAction(ride, isStart: true);
        final WaypointAction rideDestinationAction = WaypointAction(ride, isStart: false);
        for (final Waypoint stop in stops) {
          if (ride.start == stop.place) {
            startSaved = true;
            stop.actions.add(rideStartAction);
          } else if (ride.destination == stop.place) {
            destinationSaved = true;
            stop.actions.add(rideDestinationAction);
          }
        }

        if (!startSaved) {
          stops.add(
            Waypoint(
              actions: <WaypointAction>[rideStartAction],
              place: ride.start,
              time: ride.startDateTime,
            ),
          );
        }

        if (!destinationSaved) {
          stops.add(
            Waypoint(
              actions: <WaypointAction>[rideDestinationAction],
              place: ride.destination,
              time: ride.destinationDateTime,
            ),
          );
        }
      }

      stops.sort((Waypoint a, Waypoint b) {
        final int timeDiff = a.time.compareTo(b.time);
        if (timeDiff != 0) return timeDiff;
        if (a.place == drive.start || b.place == drive.destination) return -1;
        if (a.place == drive.destination || b.place == drive.start) return 1;

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
                children: <Widget>[Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: buildCard(stop))],
              ),
            );
          },
          itemCount: stops.length,
        ),
      );

      final List<Ride> pendingRides = _drive!.pendingRides.toList();

      if (visibleRides.isNotEmpty || pendingRides.isNotEmpty) {
        widgets.add(const Divider());
      }

      if (visibleRides.isNotEmpty) {
        final Set<Profile> riders = visibleRides.map((Ride ride) => ride.rider!).toSet();
        widgets.addAll(<Widget>[
          const SizedBox(height: 5),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(S.of(context).pageDriveDetailRoute, style: Theme.of(context).textTheme.titleLarge),
          ),
          const SizedBox(height: 10),
          timeline,
          const Divider(),
          ProfileWrapList(riders, title: S.of(context).riders),
        ]);
      }

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

      if (drive.status != DriveStatus.preview) {
        widgets.add(const SizedBox(height: 20));

        Widget primaryButton;
        if (drive.isFinished || drive.status.isCancelled()) {
          primaryButton = Button.error(
            S.of(context).pageDriveDetailButtonHide,
            onPressed: _showHideDialog,
            key: const Key('hideDriveButton'),
          );
        } else {
          primaryButton = Button.error(
            S.of(context).pageDriveDetailButtonCancel,
            onPressed: _showCancelDialog,
            key: const Key('cancelDriveButton'),
          );
        }
        widgets.add(primaryButton);
        widgets.add(const SizedBox(height: 5));
      }
    } else {
      widgets.add(const SizedBox(height: 10));
      widgets.add(const Center(child: CircularProgressIndicator()));
    }

    final Widget content = Column(
      children: <Widget>[
        if (_drive?.status == DriveStatus.cancelledByDriver)
          CustomBanner.error(
            S.of(context).pageDriveDetailBannerCancelledByDriver,
            key: const Key('cancelledByDriverDriveBanner'),
          )
        else if (_drive?.status == DriveStatus.cancelledByRecurrenceRule)
          CustomBanner.error(
            S.of(context).pageDriveDetailBannerCancelledByRecurrenceRule,
            key: const Key('cancelledByRecurrenceRuleDriveBanner'),
          )
        else if (_drive?.status == DriveStatus.preview)
          CustomBanner.primary(
            S.of(context).pageDriveDetailBannerPreview(Trip.creationInterval.inDays),
            key: const Key('previewDriveBanner'),
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
        actions: buildActions(),
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

  List<Widget> buildActions() {
    if (_drive?.status == DriveStatus.preview) {
      return <Widget>[];
    }

    final String tooltip = S.of(context).openChat;
    const Icon icon = Icon(Icons.chat);

    if (!_fullyLoaded) {
      return <Widget>[
        IconButton(
          onPressed: null,
          icon: icon,
          tooltip: tooltip,
        )
      ];
    }

    return <Widget>[
      IconButton(
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
      ),
    ];
  }

  Widget buildCard(Waypoint waypoint) {
    final List<Widget> cardWidgets = <Widget>[];
    cardWidgets.add(
      MergeSemantics(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                localeManager.formatTime(waypoint.time),
                style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.normal),
              ),
              const SizedBox(width: 6),
              Flexible(child: Text(waypoint.place, style: Theme.of(context).textTheme.titleMedium)),
              if (waypoint.place == _drive!.start)
                Semantics(label: S.of(context).pageDriveDetailLabelStartDrive)
              else if (waypoint.place == _drive!.destination)
                Semantics(label: S.of(context).pageDriveDetailLabelDestinationDrive),
            ],
          ),
        ),
      ),
    );

    final Icon startIcon = Icon(Icons.north_east_rounded, color: Theme.of(context).own().success);
    final Icon destinationIcon = Icon(Icons.south_west_rounded, color: Theme.of(context).colorScheme.error);
    final int actionsLength = waypoint.actions.length;
    for (int index = 0; index < actionsLength; index++) {
      final WaypointAction action = waypoint.actions[index];
      final Icon icon = action.isStart ? startIcon : destinationIcon;
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
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
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
                padding: const EdgeInsets.all(10),
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
      if (index < actionsLength) {
        cardWidgets.add(const SizedBox(height: 6.0));
      }

      cardWidgets.add(container);
    }

    return Card(
      key: const Key('waypointCard'),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: SizedBox(width: double.infinity, child: Column(children: cardWidgets)),
      ),
    );
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
