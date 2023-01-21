import '../../../drives/models/drive.dart';
import '../../../rides/models/ride.dart';
import '../../model.dart';
import '../../parse_helper.dart';
import '../../supabase.dart';
import 'message.dart';

class Chat extends Model {
  final int rideId;
  final Ride? ride;

  final int driveId;
  final Drive? drive;

  final List<Message>? messages;

  Chat({
    super.id,
    super.createdAt,
    required this.rideId,
    required this.driveId,
    this.ride,
    this.drive,
    this.messages,
  });

  @override
  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      rideId: json['ride_id'],
      ride: json.containsKey('ride') ? Ride.fromJson(json['ride']) : null,
      driveId: json['drive_id'],
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
      'ride_id': rideId,
      'drive_id': driveId,
    };
  }

  int getUnreadMessagesCount() {
    return messages!
        .where((Message message) => message.senderId != SupabaseManager.getCurrentProfile()!.id && !message.read)
        .length;
  }

  @override
  String toString() {
    return 'Chat{id: $id, createdAt: $createdAt, rideId: $rideId, driveId: $driveId}';
  }
}
