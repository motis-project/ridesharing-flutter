import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/managers/storage_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('storageManager', () {
    const String storageKey = 'test';

    group('saveData', () {
      test('can save int', () async {
        await storageManager.saveData(storageKey, 1);
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt(storageKey), 1);
        expect(() => prefs.getDouble(storageKey), throwsA(isA<TypeError>()));
      });

      test('can save double', () async {
        await storageManager.saveData(storageKey, 1.2);
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        expect(prefs.getDouble(storageKey), 1.2);
        expect(() => prefs.getInt(storageKey), throwsA(isA<TypeError>()));
      });

      test('can save String', () async {
        await storageManager.saveData(storageKey, 'some string');
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        expect(prefs.getString(storageKey), 'some string');
        expect(() => prefs.getInt(storageKey), throwsA(isA<TypeError>()));
      });

      test('can save bool', () async {
        await storageManager.saveData(storageKey, true);
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool(storageKey), true);
        expect(() => prefs.getString(storageKey), throwsA(isA<TypeError>()));
      });

      test('can save List<String>', () async {
        await storageManager.saveData(storageKey, ['some string', 'another string']);
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        expect(prefs.get(storageKey), ['some string', 'another string']);
        expect(() => prefs.getString(storageKey), throwsA(isA<TypeError>()));
      });

      test('throws type error otherwise', () async {
        expect(() => storageManager.saveData(storageKey, {'some string', 'another string'}), throwsException);
        expect(() => storageManager.saveData(storageKey, {'some string': 'another string'}), throwsException);
        expect(() => storageManager.saveData(storageKey, Object()), throwsException);
      });
    });

    group('readData', () {
      test('can read int', () async {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setInt(storageKey, 1);
        expect(await storageManager.readData<int>(storageKey), 1);
        expect(await storageManager.readData<int>('test2'), null);
      });

      test('can read double', () async {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setDouble(storageKey, 1.2);
        expect(await storageManager.readData<double>(storageKey), 1.2);
        expect(await storageManager.readData<double>('test2'), null);
      });

      test('can read String', () async {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(storageKey, 'some string');
        expect(await storageManager.readData<String>(storageKey), 'some string');
        expect(await storageManager.readData<String>('test2'), null);
      });

      test('can read bool', () async {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool(storageKey, true);
        expect(await storageManager.readData<bool>(storageKey), true);
        expect(await storageManager.readData<bool>('test2'), null);
      });

      test('can read List<String>', () async {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(storageKey, ['some string', 'another string']);
        expect(await storageManager.readData<List<String>>(storageKey), ['some string', 'another string']);
        expect(await storageManager.readData<List<String>>('test2'), null);
      });
    });

    group('deleteData', () {
      test('deletes any object', () async {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setInt(storageKey, 1);
        await storageManager.deleteData(storageKey);
        expect(await storageManager.readData<int>(storageKey), null);

        await prefs.setDouble(storageKey, 1.2);
        await storageManager.deleteData(storageKey);
        expect(await storageManager.readData<double>(storageKey), null);

        await prefs.setString(storageKey, 'some string');
        await storageManager.deleteData(storageKey);
        expect(await storageManager.readData<String>(storageKey), null);

        await prefs.setBool(storageKey, true);
        await storageManager.deleteData(storageKey);
        expect(await storageManager.readData<bool>(storageKey), null);

        await prefs.setStringList(storageKey, ['some string', 'another string']);
        await storageManager.deleteData(storageKey);
        expect(await storageManager.readData<List<String>>(storageKey), null);
      });
    });
  });
}
