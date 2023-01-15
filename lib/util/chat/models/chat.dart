import 'package:motis_mitfahr_app/util/model.dart';
import 'package:motis_mitfahr_app/rides/models/ride.dart';

import 'message.dart';

class Chat extends Model {
  Chat({
    super.id,
    super.createdAt,
    required this.rideId,
    this.lastMessage,
    this.ride,
  });

  final int rideId;
  final Ride? ride;

  Message? lastMessage;

  void setLastMessage(Message message) {
    lastMessage = message;
  }

  Message getLastMessage() {
    return lastMessage!;
  }

  @override
  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      rideId: json['ride_id'],
      lastMessage: json.containsKey('last_message') ? Message.fromJson(json['last_message']) : null,
      ride: json.containsKey('ride') ? Ride.fromJson(json['ride']) : null,
    );
  }

  static List<Chat> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => Chat.fromJson(json as Map<String, dynamic>)).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'ride_id': rideId,
    };
  }

  @override
  String toString() {
    return 'Chat{id: $id, createdAt: $createdAt, rideId: $rideId, lastMessage: $lastMessage}';
  }
}
