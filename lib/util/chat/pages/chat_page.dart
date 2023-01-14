import 'package:flutter/material.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/util/chat/models/message.dart';
import 'package:motis_mitfahr_app/util/chat_bubble.dart';
import 'package:motis_mitfahr_app/util/locale_manager.dart';
import 'package:motis_mitfahr_app/util/profiles/profile_widget.dart';
import 'package:motis_mitfahr_app/util/supabase.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ChatPage extends StatefulWidget {
  const ChatPage(this.rideId, this.profile, {super.key});
  final int rideId;
  final Profile profile;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late Stream<List<Message>> _messagesStream;

  @override
  void initState() {
    _messagesStream = supabaseClient
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('ride_id', widget.rideId)
        .order('created_at')
        .map((messages) => Message.fromJsonList(messages));
    super.initState();
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
                      ? Center(
                          child: Text(S.of(context).pageChatEmptyMessage),
                        )
                      : ListView(
                          reverse: true,
                          children: _buildChatBubbles(messages, widget.profile),
                        ),
                ),
                _MessageBar(widget.rideId),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  List<Widget> _buildChatBubbles(List<Message> messages, Profile? otherProfile) {
    List<Widget> chatBubbles = [];
    Profile ownProfile = SupabaseManager.getCurrentProfile()!;
    Message currentMessage = messages.first;
    bool isOwnMessage = currentMessage.senderId == ownProfile.id;
    if (isOwnMessage) currentMessage.markAsRead();
    chatBubbles.add(ChatBubble(
      text: currentMessage.content,
      isSender: isOwnMessage,
      tail: true,
      read: currentMessage.read && isOwnMessage,
      time: localeManager.formatTime(currentMessage.createdAt!),
    ));
    for (int i = 1; i < messages.length; i++) {
      currentMessage = messages[i];
      isOwnMessage = currentMessage.senderId == ownProfile.id;
      if (isOwnMessage) currentMessage.markAsRead();
      chatBubbles.add(ChatBubble(
        text: currentMessage.content,
        isSender: isOwnMessage,
        tail: currentMessage.senderId != messages[i - 1].senderId,
        read: (i % 2 == 0) && isOwnMessage,
        time: localeManager.formatTime(currentMessage.createdAt!),
      ));
    }
    return chatBubbles;
  }
}

/// Set of widget that contains TextField and Button to submit message
class _MessageBar extends StatefulWidget {
  const _MessageBar(this.rideId, {super.key});
  final int rideId;

  @override
  State<_MessageBar> createState() => _MessageBarState();
}

class _MessageBarState extends State<_MessageBar> {
  late final TextEditingController _textController;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  keyboardType: TextInputType.text,
                  maxLines: null,
                  autofocus: true,
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: S.of(context).pageChatMessageBarHint,
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.all(8),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _submitMessage(),
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    _textController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submitMessage() async {
    final text = _textController.text;
    int myUserId = SupabaseManager.getCurrentProfile()!.id!;
    // final myUserId = supabase.auth.currentUser!.id;
    if (text.isEmpty) {
      return;
    }
    _textController.clear();
    try {
      await supabaseClient.from('messages').insert({
        'sender_id': myUserId,
        'content': text,
        'ride_id': widget.rideId,
      });
    } catch (e) {
      print(e);
    }
  }
}
