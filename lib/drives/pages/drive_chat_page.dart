import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:supabase/src/supabase_stream_builder.dart';

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
  late Stream<List<Message>> _messagesStream;

  @override
  void initState() {
    final List<int> ids = widget.drive.approvedRides!.map((Ride ride) => ride.id!).toList();
    _messagesStream =
        SupabaseManager.supabaseClient.from('messages').stream(primaryKey: ['id']).order('created_at').map(
              (SupabaseStreamEvent messages) => Message.fromJsonList(
                messages.where((Map<String, dynamic> element) => ids.contains(element['ride_id'])).toList(),
              ),
            );
    super.initState();
  }

  @override
  void dispose() {
    _messagesStream.drain();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).pageDriveChatTitle),
      ),
      body: StreamBuilder<List<Message>>(
        stream: _messagesStream,
        builder: (BuildContext context, AsyncSnapshot<List> snapshot) {
          if (snapshot.hasData) {
            final Set<Ride> approvedRides = widget.drive.approvedRides!.toSet();
            for (final Message message in snapshot.data!) {
              final Ride ride = approvedRides.firstWhere((Ride element) => element.id == message.rideId);
              if (ride.messages!.contains(message)) {
                ride.messages!.remove(message);
              }
              ride.messages!.add(message);
            }
            final List<Widget> widgets = _buildChatWidgets(approvedRides);
            return ListView.separated(
              itemCount: widgets.length,
              itemBuilder: (BuildContext context, int index) {
                return widgets[index];
              },
              separatorBuilder: (BuildContext context, int index) {
                return const SizedBox(height: 10);
              },
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
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
          trailing: ride.getUnreadMessagesCount() == 0
              ? null
              : Container(
                  decoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      ride.getUnreadMessagesCount().toString(),
                    ),
                  ),
                ),
          onTap: () {
            Navigator.of(context)
                .push(
                  MaterialPageRoute(
                    builder: (BuildContext context) => ChatPage(
                      rideId: ride.id!,
                      profile: ride.rider!,
                      // ride.messages!,
                    ),
                  ),
                )
                .then((value) => setState(() {}));
          },
        ),
      ),
    );
  }

  List<Widget> _buildChatWidgets(Set<Ride> approvedRides) {
    if (approvedRides.isEmpty) {
      return [
        Center(
          child: Text(S.of(context).pageDriveChatEmptyMessage),
        )
      ];
    } else {
      return approvedRides.map((Ride ride) => _buildChatWidget(ride)).toList();
    }
  }
}
