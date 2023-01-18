import '../../../account/models/profile.dart';
import '../../../drives/models/drive.dart';
import '../../model.dart';
import '../../parse_helper.dart';
import '../../supabase.dart';
import 'message.dart';

class Chat extends Model {
  final int riderId;
  final Profile? rider;

  final int driveId;
  final Drive? drive;

  final List<Message>? messages;

  Chat({
    super.id,
    super.createdAt,
    required this.riderId,
    required this.driveId,
    this.rider,
    this.drive,
    this.messages,
  });

  @override
  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      riderId: json['rider_id'],
      driveId: json['drive_id'],
      rider: json.containsKey('rider') ? Profile.fromJson(json['rider']) : null,
      drive: json.containsKey('drive') ? Drive.fromJson(json['drive']) : null,
      messages:
          json.containsKey('messages') ? Message.fromJsonList(parseHelper.parseListOfMaps(json['messages'])) : null,
    );
  }

  static List<Chat> fromJsonList(List<Map<String, dynamic>> jsonList) {
    return jsonList.map((Map<String, dynamic> json) => Chat.fromJson(json)).toList();
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'rider_id': riderId,
      'drive_id': driveId,
    };
  }

  int getUnreadMessagesCount() {
    if (messages == null) return 0;
    return messages!
        .where((Message message) => message.senderId != SupabaseManager.getCurrentProfile()!.id && !message.read)
        .length;
  }

  @override
  String toString() {
    return 'Chat{id: $id, createdAt: $createdAt, riderId: $riderId, driveId: $driveId}';
  }
}
