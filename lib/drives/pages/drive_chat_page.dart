import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../account/models/profile.dart';
import '../../rides/models/ride.dart';
import '../../util/profiles/profile_widget.dart';
import '../../util/supabase.dart';
import '../models/drive.dart';

class DriveChatPage extends StatefulWidget {
  final Drive drive;
  const DriveChatPage({required this.drive, super.key});

  @override
  State<DriveChatPage> createState() => _DriveChatPageState();
}

class _DriveChatPageState extends State<DriveChatPage> {
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

  @override
  Widget build(BuildContext context) {
    final List<Widget> widgets = <Widget>[];
    if (_fullyLoaded) {
      final Set<Profile> riders = _drive!.approvedRides!.map((Ride ride) => ride.rider!).toSet();
      final List<Ride> pendingRides = _drive!.pendingRides!.toList();
      if (riders.isEmpty && pendingRides.isEmpty) {
        return Scaffold(
          appBar: AppBar(
            title: Text(S.of(context).pageDriveChatTitle),
          ),
          body: Center(
            child: Text(S.of(context).pageDriveChatEmptyMessage),
          ),
        );
      } else {
        if (riders.isNotEmpty) {
          final List<Widget> riderColumn = <Widget>[
            const SizedBox(height: 5.0),
            Text(
              S.of(context).pageDriveChatRiderHeadline,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10.0),
            _riderList(riders),
          ];
          widgets.addAll(riderColumn);
        }
        widgets.add(const SizedBox(height: 10.0));
      }
    } else {
      widgets.add(const SizedBox(height: 10));
      widgets.add(const Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).pageDriveChatTitle),
      ),
      body: RefreshIndicator(
        onRefresh: loadDrive,
        child: ListView.separated(
          itemCount: widgets.length,
          itemBuilder: (BuildContext context, int index) {
            return widgets[index];
          },
          separatorBuilder: (BuildContext context, int index) {
            return const SizedBox(height: 10);
          },
        ),
      ),
    );
  }

  Widget _riderList(Set<Profile> riders) {
    Widget ridersColumn = Container();
    if (riders.isNotEmpty) {
      ridersColumn = Column(
        children: List<Padding>.generate(
          riders.length,
          (int index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
            child: ProfileWidget(
              riders.elementAt(index),
              //TODO go to chat
              onTap: () {},
              actionWidget: const Icon(
                Icons.chat,
                color: Colors.black,
                size: 36.0,
              ),
            ),
          ),
        ),
      );
    }
    return ridersColumn;
  }

  Future<void> loadDrive() async {
    final Map<String, dynamic> data = await SupabaseManager.supabaseClient.from('drives').select('''
      *,
      rides(
        *,
        rider: rider_id(*)
      )
    ''').eq('id', widget.drive.id).single();
    setState(() {
      _drive = Drive.fromJson(data);
      _fullyLoaded = true;
    });
  }
}
