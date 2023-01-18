import '../../../account/models/profile.dart';
import '../../model.dart';
import '../../supabase.dart';
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
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      chatId: json['chat_id'],
      senderId: json['sender_id'],
      content: json['content'],
      read: json['read'],
      chat: json.containsKey('chat') ? Chat.fromJson(json['chat']) : null,
      sender: json.containsKey('sender') ? Profile.fromJson(json['sender']) : null,
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

  bool get isFromCurrentUser => senderId == SupabaseManager.getCurrentProfile()?.id;

  Future<void> markAsRead() async {
    read = true;
    //custom rpc call to mark message as read, so the user does not need the write permission on the messages table
    await SupabaseManager.supabaseClient.rpc('mark_message_as_read', params: {'message_id': id});
  }

  @override
  String toString() {
    return 'Message{id: $id, createdAt: $createdAt, chatId: $chatId, senderId: $senderId, content: $content, read: $read}';
  }
}
