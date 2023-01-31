import '../../../account/models/profile.dart';
import '../../model.dart';
import '../../supabase_manager.dart';
import 'chat.dart';

class Message extends Model {
  final int chatId;
  final Chat? chat;

  final String content;

  final int senderId;
  final Profile? sender;

  bool read;

  Message({
    super.id,
    super.createdAt,
    required this.chatId,
    required this.senderId,
    required this.content,
    this.read = false,
    this.chat,
    this.sender,
  });

  @override
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      chatId: json['chat_id'] as int,
      senderId: json['sender_id'] as int,
      content: json['content'] as String,
      read: json['read'] as bool,
      chat: json.containsKey('chat') ? Chat.fromJson(json['chat'] as Map<String, dynamic>) : null,
      sender: json.containsKey('sender') ? Profile.fromJson(json['sender'] as Map<String, dynamic>) : null,
    );
  }

  static List<Message> fromJsonList(List<Map<String, dynamic>> jsonList) {
    return jsonList.map((Map<String, dynamic> json) => Message.fromJson(json)).toList();
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'chat_id': chatId,
      'sender_id': senderId,
      'content': content,
      'read': read,
    };
  }

  bool get isFromCurrentUser => senderId == supabaseManager.currentProfile?.id;

  Future<void> markAsRead() async {
    read = true;
    //custom rpc call to mark message as read, so the user does not need the write permission on the messages table
    await supabaseManager.supabaseClient.rpc('mark_message_as_read', params: <String, dynamic>{'message_id': id});
  }

  @override
  String toString() {
    return 'Message{id: $id, createdAt: $createdAt, chatId: $chatId, senderId: $senderId, content: $content, read: $read}';
  }
}
