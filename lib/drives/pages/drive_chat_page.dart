import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:supabase/src/supabase_stream_builder.dart';

import '../../account/widgets/avatar.dart';
import '../../util/chat/models/chat.dart';
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
    final List<int> ids = widget.drive.chats!.map((Chat chat) => chat.id!).toList();
    _messagesStream =
        SupabaseManager.supabaseClient.from('messages').stream(primaryKey: ['id']).order('created_at').map(
              (SupabaseStreamEvent messages) => Message.fromJsonList(
                messages.where((Map<String, dynamic> element) => ids.contains(element['chat_id'])).toList(),
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
    final List<Chat> chats = widget.drive.chats!.toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).pageDriveChatTitle),
      ),
      body: chats.isNotEmpty
          ? StreamBuilder<List<Message>>(
              stream: _messagesStream,
              builder: (BuildContext context, AsyncSnapshot<List<Message>> snapshot) {
                if (snapshot.hasData) {
                  for (final Message message in snapshot.data!) {
                    final Chat chat = chats.firstWhere((Chat chat) => chat.id == message.chatId);
                    if (chat.messages!.contains(message)) {
                      chat.messages!.remove(message);
                    }
                    chat.messages!.add(message);
                  }
                  final List<Card> widgets = chats.map((Chat chat) => _buildChatWidget(chat)).toList();
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
              children: <Widget>[
                Image.asset('assets/chat_shrug.png', scale: 8),
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

  Card _buildChatWidget(Chat chat) {
    chat.messages!.sort((Message a, Message b) => b.createdAt!.compareTo(a.createdAt!));
    final Message? lastMessage = chat.messages!.isEmpty ? null : chat.messages!.first;
    return Card(
      child: InkWell(
        child: ListTile(
          leading: Avatar(chat.ride!.rider!),
          title: Text(chat.ride!.rider!.username),
          subtitle: lastMessage == null ? null : Text(lastMessage.content, maxLines: 1),
          trailing: chat.getUnreadMessagesCount() == 0
              ? null
              : Container(
                  decoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      chat.getUnreadMessagesCount().toString(),
                    ),
                  ),
                ),
          onTap: () {
            Navigator.of(context)
                .push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => ChatPage(
                      chatId: chat.id!,
                      profile: chat.ride!.rider!,
                    ),
                  ),
                )
                .then((_) => setState(() {}));
          },
        ),
      ),
    );
  }
}
