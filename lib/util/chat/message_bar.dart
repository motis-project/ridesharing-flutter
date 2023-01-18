import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../supabase.dart';

class MessageBar extends StatefulWidget {
  const MessageBar(this.chatId, {super.key});
  final int chatId;

  @override
  State<MessageBar> createState() => _MessageBarState();
}

class _MessageBarState extends State<MessageBar> {
  late final TextEditingController _textController;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
      child: Material(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
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
    final String text = _textController.text;
    if (text.isEmpty) {
      return;
    }
    _textController.clear();
    try {
      await SupabaseManager.supabaseClient.from('messages').insert({
        'sender_id': SupabaseManager.getCurrentProfile()!.id!,
        'content': text,
        'chat_id': widget.chatId,
      });
    } on Exception {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).failureSnackBar),
        ),
      );
    }
  }
}
