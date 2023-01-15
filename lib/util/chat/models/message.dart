import 'package:motis_mitfahr_app/util/model.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/util/supabase.dart';

class Message extends Model {
  final int rideId;
  final String content;

  final int senderId;
  final Profile? sender;

  bool read;

  Message({
    super.id,
    super.createdAt,
    required this.senderId,
    required this.content,
    required this.rideId,
    this.sender,
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
      sender: json.containsKey('user') ? Profile.fromJson(json['user']) : null,
      read: json['read'],
    );
  }

  static List<Message> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => Message.fromJson(json as Map<String, dynamic>)).toList();
  }

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
    await SupabaseManager.supabaseClient.from('messages').update({'read': true}).eq('id', id);
  }

  @override
  String toString() {
    return 'Message{id: $id, createdAt: $createdAt, userId: $senderId, content: $content, chatId: $rideId, user: $sender}';
  }
}
