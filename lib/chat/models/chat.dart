import 'message.dart';

class Chat {
  Chat({
    required this.id,
    required this.passengerId,
    required this.driverId,
    required this.createdAt,
    this.lastMessage,
  });

  /// ID of the chat
  final int id;

  /// ID of the passenger
  final int passengerId;

  /// ID of the driver
  final int driverId;

  /// Date and time when the chat was created
  final DateTime createdAt;

  /// Last message in the chat (if any)
  Message? lastMessage;

  void setLastMessage(Message message) {
    lastMessage = message;
  }

  Message getLastMessage() {
    return lastMessage!;
  }

  Chat.fromMap({
    required Map<String, dynamic> map,
    required String myUserId,
  })  : id = map['id'],
        passengerId = map['passenger_id'],
        driverId = map['driver_id'],
        createdAt = DateTime.parse(map['created_at']);
  //todo: add last message
}
