import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../rides/models/ride.dart';
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

  @override
  void initState() {
    super.initState();
    setState(() {
      _drive = widget.drive;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> widgets = [];
    final Set<Ride> approvedRides = _drive!.approvedRides!.toSet();
    final List<Ride> pendingRides = _drive!.pendingRides!.toList();
    if (approvedRides.isEmpty && pendingRides.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).pageDriveChatTitle),
        ),
        body: Center(
          child: Text(S.of(context).pageDriveChatEmptyMessage),
        ),
      );
    } else {
      if (approvedRides.isNotEmpty) {
        final List<Widget> riderColumn = approvedRides.map((Ride ride) => _buildChatWidget(ride)).toList();
        widgets.addAll(riderColumn);
      }
      widgets.add(const SizedBox(height: 10.0));
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

  Future<void> loadDrive() async {
    final Map<String, dynamic> data = await SupabaseManager.supabaseClient.from('drives').select('''
      *,
      rides(
        *,
        rider: rider_id(*),
        messages(*)
      )
    ''').eq('id', widget.drive.id).single();
    setState(() {
      _drive = Drive.fromJson(data);
    });
  }

  Widget _buildChatWidget(Ride ride) {
    ride.messages!.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
    final Message? lastMessage = ride.messages!.isEmpty ? null : ride.messages!.first;
    return Card(
      child: InkWell(
        child: ListTile(
          leading: Avatar(ride.rider!),
          title: Text(ride.rider!.username),
          subtitle: lastMessage == null ? null : Text(lastMessage.content),
          trailing: lastMessage == null ? null : Text(localeManager.formatTime(lastMessage.createdAt!)),
          onTap: () {
            Navigator.of(context)
                .push(
                  MaterialPageRoute(
                    builder: (BuildContext context) => ChatPage(
                      ride.id!,
                      ride.rider!,
                      // ride.messages!,
                    ),
                  ),
                )
                .then((value) => loadDrive());
          },
        ),
      ),
    );
  }
}
