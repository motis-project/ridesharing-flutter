import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../account/models/profile.dart';
import '../../profiles/profile_widget.dart';
import '../../supabase.dart';
import '../chat_bubble.dart';
import '../message_bar.dart';
import '../models/message.dart';

class ChatPage extends StatefulWidget {
  final Profile profile;
  final int chatId;
  final bool active;

  const ChatPage({
    int? chatId,
    required this.profile,
    this.active = true,
    super.key,
  }) : chatId = chatId ?? -1;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late Stream<List<Message>> _messagesStream;

  @override
  void initState() {
    if (widget.active) {
      _messagesStream = SupabaseManager.supabaseClient
          .from('messages')
          .stream(primaryKey: <String>['id'])
          .eq('chat_id', widget.chatId)
          .order('created_at')
          .map((List<Map<String, dynamic>> messages) => Message.fromJsonList(messages));
    } else {
      _messagesStream = Stream<List<Message>>.value(<Message>[]);
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
    return Scaffold(
      appBar: AppBar(
        title: ProfileWidget(
          widget.profile,
        ),
      ),
      body: widget.active
          ? StreamBuilder<List<Message>>(
              stream: _messagesStream,
              builder: (BuildContext context, AsyncSnapshot<List<Message>> snapshot) {
                if (snapshot.hasData) {
                  final List<Message> messages = snapshot.data!;
                  return Column(
                    children: <Widget>[
                      Expanded(
                        child: messages.isEmpty
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
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
                      MessageBar(widget.chatId),
                    ],
                  );
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
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

  List<ChatBubble> _buildChatBubbles(List<Message> messages) {
    final List<ChatBubble> chatBubbles = <ChatBubble>[];
    for (int i = 0; i < messages.length; i++) {
      if (!messages[i].read && messages[i].senderId != SupabaseManager.getCurrentProfile()!.id) {
        messages[i].markAsRead();
      }
      chatBubbles.add(
        ChatBubble.fromMessage(
          messages[i],
          tail: i == 0 || messages[i].senderId != messages[i - 1].senderId,
        ),
      );
    }
    return chatBubbles;
  }
}
