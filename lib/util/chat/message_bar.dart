import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:motis_mitfahr_app/util/supabase.dart';

/// Set of widget that contains TextField and Button to submit message
class MessageBar extends StatefulWidget {
  const MessageBar(this.rideId, {super.key});
  final int rideId;

  @override
  State<MessageBar> createState() => _MessageBarState();
}

class _MessageBarState extends State<MessageBar> {
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
      await SupabaseManager.supabaseClient.from('messages').insert({
        'sender_id': myUserId,
        'content': text,
        'ride_id': widget.rideId,
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
