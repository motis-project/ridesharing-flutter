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

}