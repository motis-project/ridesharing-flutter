import '../../../rides/models/ride.dart';
import '../../model.dart';
import '../../parse_helper.dart';
import '../../supabase.dart';
import 'message.dart';

class Chat extends Model {
  final Ride? ride;

  final List<Message>? messages;

  Chat({
    super.id,
    super.createdAt,
    this.ride,
    this.messages,
  });

  @override
  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      ride: json.containsKey('ride') ? Ride.fromJson(json['ride']) : null,
      messages:
          json.containsKey('messages') ? Message.fromJsonList(parseHelper.parseListOfMaps(json['messages'])) : null,
    );
  }

  static List<Chat> fromJsonList(List<Map<String, dynamic>> jsonList) {
    return jsonList.map((Map<String, dynamic> json) => Chat.fromJson(json)).toList();
  }

  int getUnreadMessagesCount() {
    return messages!
        .where((Message message) => message.senderId != SupabaseManager.getCurrentProfile()!.id && !message.read)
        .length;
  }

  @override
  String toString() {
    return 'Chat{id: $id, createdAt: $createdAt}';
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{};
  }
}
