class Message {
  Message({
    required this.id,
    required this.userId,
    required this.content,
    required this.createdAt,
    required this.chatId,
    required this.isMine,
  });

  /// ID of the message
  final int id;

  /// ID of the user who posted the message
  final int userId;

  /// Text content of the message
  final String content;

  /// Date and time when the message was created
  final DateTime createdAt;

  final int chatId;

  final bool isMine;

  Message.fromMap({
    required Map<String, dynamic> map,
  })  : id = map['id'],
        userId = map['user_id'],
        content = map['content'],
        createdAt = DateTime.parse(map['created_at']),
        chatId = map['chat_id'],
        //todo: change back to currentUser when database is set up
        isMine = 2 == map['user_id'];
}
