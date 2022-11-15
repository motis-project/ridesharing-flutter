import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/chat.dart';

class ChatsOVerviewPage extends StatefulWidget {
  const ChatsOVerviewPage({Key? key}) : super(key: key);

  static Route<void> route() {
    return MaterialPageRoute(
      builder: (context) => const ChatsOVerviewPage(),
    );
  }

  @override
  State<ChatsOVerviewPage> createState() => _ChatsOVerviewPageState();
}

class _ChatsOVerviewPageState extends State<ChatsOVerviewPage> {
  late final Stream<List<Chat>> _chatsStream;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: const Center(
        child: Text('Chats'),
      ),
    );
  }
}

class chatOverview extends StatefulWidget {
  @override
  _chatOverviewState createState() => _chatOverviewState();
}

class _chatOverviewState extends State<chatOverview> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Center(child: Text("Chat")),
      ),
    );
  }
}
