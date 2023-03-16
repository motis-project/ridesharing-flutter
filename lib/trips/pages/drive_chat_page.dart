import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../account/widgets/avatar.dart';
import '../../chat/models/chat.dart';
import '../../chat/models/message.dart';
import '../../chat/pages/chat_page.dart';
import '../../managers/supabase_manager.dart';
import '../../util/empty_search_results.dart';
import '../models/drive.dart';
import '../models/ride.dart';

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
    _ridesWithChat = widget.drive.ridesWithChat;

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
          : EmptySearchResults(
              key: const Key('noChatsImage'),
              asset: EmptySearchResults.shrugAsset,
              title: S.of(context).pageChatEmptyTitle,
              subtitle: Text(
                S.of(context).pageDriveChatEmptyMessage,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
    );
  }

  Card _buildChatWidget(Ride ride) {
    final Chat chat = ride.chat!;

    chat.messages!.sort((Message a, Message b) => b.createdAt!.compareTo(a.createdAt!));
    final Message? lastMessage = chat.messages!.isEmpty ? null : chat.messages!.first;
    final Widget? subtitle = lastMessage == null
        ? null
        : RichText(
            key: Key('chatWidget${chat.id}Subtitle'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              children: <InlineSpan>[
                if (lastMessage.isFromCurrentUser)
                  WidgetSpan(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 5),
                      child: Icon(
                        Icons.done_all,
                        size: 18,
                        color: lastMessage.read
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ),
                TextSpan(text: lastMessage.content, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          );
    return Card(
      key: Key('chatWidget${chat.id}'),
      child: Semantics(
        label: S.of(context).openChat,
        child: InkWell(
          child: ListTile(
            leading: Avatar(ride.rider!),
            title: Text(ride.rider!.username),
            subtitle: subtitle,
            trailing: chat.getUnreadMessagesCount() == 0
                ? null
                : Container(
                    key: Key('chatWidget${chat.id}UnreadMessageCount'),
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        chat.getUnreadMessagesCount().toString(),
                        style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
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
      ),
    );
  }
}
