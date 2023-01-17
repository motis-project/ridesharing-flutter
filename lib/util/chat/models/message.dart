import '../../model.dart';
import '../../supabase.dart';

class Message extends Model {
  final int rideId;
  final String content;

  final int senderId;

  bool read;

  Message({
    super.id,
    super.createdAt,
    required this.senderId,
    required this.content,
    required this.rideId,
    this.read = false,
  });

  @override
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      senderId: json['sender_id'],
      content: json['content'],
      rideId: json['ride_id'],
      read: json['read'],
    );
  }

  static List<Message> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => Message.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'sender_id': senderId,
      'content': content,
      'ride_id': rideId,
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
    return 'Message{id: $id, createdAt: $createdAt, rideId: $rideId, senderId: $senderId, content: $content, read: $read}';
  }
}
