import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../account/widgets/avatar.dart';
import '../../rides/models/ride.dart';
import '../../util/chat/models/chat.dart';
import '../../util/chat/models/message.dart';
import '../../util/chat/pages/chat_page.dart';
import '../../util/supabase_manager.dart';
import '../models/drive.dart';

class DriveChatPage extends StatefulWidget {
  final Drive drive;
  const DriveChatPage({required this.drive, super.key});

  @override
  State<DriveChatPage> createState() => _DriveChatPageState();
}

class _DriveChatPageState extends State<DriveChatPage> {
  late Stream<List<Message>> _messagesStream;
  late List<Ride> _ridesWithChat;

  @override
  void initState() {
    _ridesWithChat = widget.drive.ridesWithChat!;

    final List<int> ids = _ridesWithChat.map((Ride ride) => ride.chatId!).toList();
    _messagesStream =
        supabaseManager.supabaseClient.from('messages').stream(primaryKey: <String>['id']).order('created_at').map(
              (List<Map<String, dynamic>> messages) => Message.fromJsonList(
                messages.where((Map<String, dynamic> element) => ids.contains(element['chat_id'])).toList(),
              ),
            );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).pageDriveChatTitle),
      ),
      body: _ridesWithChat.isNotEmpty
          ? StreamBuilder<List<Message>>(
              stream: _messagesStream,
              builder: (BuildContext context, AsyncSnapshot<List<Message>> snapshot) {
                if (snapshot.hasData) {
                  for (final Message message in snapshot.data!) {
                    final Chat chat = _ridesWithChat.firstWhere((Ride ride) => ride.chatId == message.chatId).chat!;
                    if (chat.messages!.contains(message)) {
                      chat.messages!.remove(message);
                    }
                    chat.messages!.add(message);
                  }
                  final List<Card> widgets = _ridesWithChat.map<Card>((Ride ride) => _buildChatWidget(ride)).toList();
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
                Image.asset(key: const Key('noChatsImage'), 'assets/chat_shrug.png', scale: 8),
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

  Card _buildChatWidget(Ride ride) {
    final Chat chat = ride.chat!;

    chat.messages!.sort((Message a, Message b) => b.createdAt!.compareTo(a.createdAt!));
    final Message? lastMessage = chat.messages!.isEmpty ? null : chat.messages!.first;
    final Widget? subtitle = lastMessage == null
        ? null
        : Wrap(
            key: Key('chatWidget${chat.id}Subtitle'),
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              if (lastMessage.isFromCurrentUser)
                Icon(
                  Icons.done_all,
                  size: 18,
                  color: lastMessage.read
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              Text(lastMessage.content),
            ],
          );
    return Card(
      key: Key('chatWidget${chat.id}'),
      child: InkWell(
        child: ListTile(
          leading: Avatar(ride.rider!),
          title: Text(ride.rider!.username),
          subtitle: subtitle,
          trailing: chat.getUnreadMessagesCount() == 0
              ? null
              : Container(
                  key: Key('chatWidget${chat.id}UnreadMessageCount'),
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
                      chatId: chat.id,
                      profile: ride.rider!,
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
