import 'package:flutter/material.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/util/chat/message_bar.dart';
import 'package:motis_mitfahr_app/util/chat/models/message.dart';
import 'package:motis_mitfahr_app/util/chat/chat_bubble.dart';
import 'package:motis_mitfahr_app/util/profiles/profile_widget.dart';
import 'package:motis_mitfahr_app/util/supabase.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({required this.rideId, required this.profile, super.key});
  final int rideId;
  final Profile profile;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late Stream<List<Message>> _messagesStream;

  @override
  void initState() {
    _messagesStream = SupabaseManager.supabaseClient
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('ride_id', widget.rideId)
        .order('created_at')
        .map((messages) => Message.fromJsonList(messages));
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
        title: ProfileWidget(
          widget.profile,
          isTappable: true,
        ),
      ),
      body: StreamBuilder<List<Message>>(
        stream: _messagesStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<Message> messages = snapshot.data!;
            return Column(
              children: [
                Expanded(
                  child: messages.isEmpty
                      ? Column(
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
                            Text(
                              S.of(context).pageChatEmptyMessage,
                            ),
                          ],
                        )
                      : ListView(
                          reverse: true,
                          children: _buildChatBubbles(messages),
                        ),
                ),
                MessageBar(widget.rideId),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  List<Widget> _buildChatBubbles(List<Message> messages) {
    List<Widget> chatBubbles = [];
    for (int i = 0; i < messages.length; i++) {
      if (!messages[i].read && messages[i].senderId != SupabaseManager.getCurrentProfile()!.id) {
        messages[i].markAsRead();
      }
      chatBubbles.add(
        ChatBubble.fromMessage(messages[i], tail: i == 0 ? true : messages[i].senderId != messages[i - 1].senderId),
      );
    }
    return chatBubbles;
  }
}
