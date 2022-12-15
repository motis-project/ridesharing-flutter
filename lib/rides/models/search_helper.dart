import 'package:intl/intl.dart';

class SearchHelper {
  const SearchHelper();

  static String formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  static String formatTime(DateTime time) {
    return DateFormat.Hm().format(time);
  }

}