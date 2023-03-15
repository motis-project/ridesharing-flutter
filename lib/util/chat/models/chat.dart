import '../../../rides/models/ride.dart';
import '../../model.dart';
import '../../parse_helper.dart';
import '../../supabase_manager.dart';
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
      id: json['id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      ride: json.containsKey('ride') ? Ride.fromJson(json['ride'] as Map<String, dynamic>) : null,
      messages:
          json.containsKey('messages') ? Message.fromJsonList(parseHelper.parseListOfMaps(json['messages'])) : null,
    );
  }

  static List<Chat> fromJsonList(List<Map<String, dynamic>> jsonList) {
    return jsonList.map((Map<String, dynamic> json) => Chat.fromJson(json)).toList();
  }

  /// Returns the number of unread messages in this chat.
  ///
  /// Expects [messages] to be not null
  int getUnreadMessagesCount() {
    return messages!
        .where((Message message) => message.senderId != supabaseManager.currentProfile!.id && !message.read)
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

  @override
  Map<String, dynamic> toJsonForApi() {
    return super.toJsonForApi()
      ..addAll(<String, dynamic>{
        'messages': messages!.map((Message message) => message.toJsonForApi()).toList(),
      });
  }
}
