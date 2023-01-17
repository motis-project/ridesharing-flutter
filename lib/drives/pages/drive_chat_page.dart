import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:supabase/src/supabase_stream_builder.dart';

import '../../account/widgets/avatar.dart';
import '../../rides/models/ride.dart';
import '../../util/chat/models/message.dart';
import '../../util/chat/pages/chat_page.dart';
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
    final List<int> ids = widget.drive.ridesWithChat!.map((Ride ride) => ride.id!).toList();
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
    final Set<Ride> ridesWithChat = widget.drive.ridesWithChat!.toSet();
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).pageDriveChatTitle),
      ),
      body: ridesWithChat.isNotEmpty
          ? StreamBuilder<List<Message>>(
              stream: _messagesStream,
              builder: (BuildContext context, AsyncSnapshot<List> snapshot) {
                if (snapshot.hasData) {
                  for (final Message message in snapshot.data!) {
                    final Ride ride = ridesWithChat.firstWhere((Ride element) => element.id == message.rideId);
                    if (ride.messages!.contains(message)) {
                      ride.messages!.remove(message);
                    }
                    ride.messages!.add(message);
                  }
                  final List<Widget> widgets = ridesWithChat.map((Ride ride) => _buildChatWidget(ride)).toList();
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
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/chat_shrug.png',
                  scale: 8,
                ),
                const SizedBox(height: 16),
                Text(
                  S.of(context).pageChatEmptyTitle,
                  style: Theme.of(context).textTheme.headline6,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    S.of(context).pageDriveChatEmptyMessage,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
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
          subtitle: lastMessage == null ? null : Text(_truncate(lastMessage.content)),
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
                    ),
                  ),
                )
                .then((value) => setState(() {}));
          },
        ),
      ),
    );
  }

  String _truncate(String text) {
    final int length = 30;
    if (text.length > length) {
      return text.replaceRange(length, text.length, '...');
    } else {
      return text;
    }
  }
}
