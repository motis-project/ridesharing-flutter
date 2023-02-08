import 'package:shared_preferences/shared_preferences.dart';

StorageManager storageManager = StorageManager();

class StorageManager {
  Future<void> saveData(String key, dynamic value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is List<String>) {
      await prefs.setStringList(key, value);
    } else {
      throw Exception('Unsupported type');
    }
  }

  Future<T?> readData<T>(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    if (T == List<String>) {
      return prefs.getStringList(key) as T?;
    }

    return prefs.get(key) as T?;
  }

  Future<bool> deleteData(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.remove(key);
  }
}
