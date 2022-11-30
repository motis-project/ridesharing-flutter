import 'package:flutter_app/util/supabase.dart';

import '../../drives/models/drive.dart';
import '../../util/model.dart';

class SearchRequest extends Model {
  final String start;
  final DateTime startTime;
  final String end;

  final int seats;

  SearchRequest({
    super.id,
    super.createdAt,
    required this.start,
    required this.startTime,
    required this.end,
    required this.seats,
  });

  @override
  factory SearchRequest.fromJson(Map<String, dynamic> json) {
    return SearchRequest(
      id: json['id'],
      start: json['start'],
      startTime: DateTime.parse(json['start_time']),
      end: json['end'],
      seats: json['seats'],
    );
  }

  static List<SearchRequest> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((json) => SearchRequest.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'start': start,
      'start_time': startTime.toString(),
      'end': end,
      'seats': seats,
    };
  }

  List<Map<String, dynamic>> toJsonList(List<SearchRequest> searchrequests) {
    return searchrequests.map((searchrequest) => searchrequest.toJson()).toList();
  }

  @override
  String toString() {
    return 'SearchRequest{id: $id, from: $start at $startTime, to: $end}';
  }

}