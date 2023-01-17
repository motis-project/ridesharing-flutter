import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../account/models/profile.dart';
import '../../profiles/profile_widget.dart';
import '../../supabase.dart';
import '../chat_bubble.dart';
import '../message_bar.dart';
import '../models/message.dart';

class ChatPage extends StatefulWidget {
  final int rideId;
  final Profile profile;
  final bool chatExists;

  const ChatPage({
    rideId,
    required this.profile,
    this.chatExists = true,
    super.key,
  }) : rideId = rideId ?? -1;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late Stream<List<Message>> _messagesStream;

  @override
  void initState() {
    if (widget.chatExists) {
      _messagesStream = SupabaseManager.supabaseClient
          .from('messages')
          .stream(primaryKey: ['id'])
          .eq('ride_id', widget.rideId)
          .order('created_at')
          .map((messages) => Message.fromJsonList(messages));
    } else {
      _messagesStream = Stream.value([]);
    }
    super.initState();
  }

  @override
  void dispose() {
    _messagesStream.drain();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.chatExists) {}
    return Scaffold(
      appBar: AppBar(
        title: ProfileWidget(
          widget.profile,
          isTappable: true,
        ),
      ),
      body: widget.chatExists
          ? StreamBuilder<List<Message>>(
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
                    S.of(context).pageChatNoChatMessage,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
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
        ChatBubble.fromMessage(
          messages[i],
          tail: i == 0 ? true : messages[i].senderId != messages[i - 1].senderId,
        ),
      );
    }
    return chatBubbles;
  }
}
