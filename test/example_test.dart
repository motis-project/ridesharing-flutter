import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:motis_mitfahr_app/drives/models/drive.dart';
import 'package:motis_mitfahr_app/util/supabase.dart';

import 'util/mock_server.dart';
import 'util/mock_server.mocks.dart';

// Die Klasse UrlProcessor muss zu Beginn jeder Testdatei implementiert werden und die Methode processUrl überschrieben werden
// Wird die Methode ProcessUrl aufgrufen, wird für den dort definierten Fall (in dem Beispiel client.from('drives').select('driver_id,seats')) die Antwort definiert
// Die Datenbankabfrage an den Client wird so abgefangen und das gewünschte Ergebnis zurückgegeben.
// Um herauszufinden welche URL durch die jeweilige Datenbankabfrage generiert wird, einfach den auskommentierten Print-Aufruf in der mockServer.Dart Datei aktivieren

void main() {
  MockUrlProcessor driveProcessor = MockUrlProcessor();
  //setup muss in jeder Testklasse einmal aufgerufen werden
  setUp(() async {
    MockServer.setProcessor(driveProcessor);
  });

  group('basic test', () {
    test('test with explicit URL', () async {
      when(driveProcessor.processUrl('/rest/v1/drives?select=driver_id%2Cseats&driver_id=eq.1')).thenReturn(jsonEncode([
        {
          'id': 1,
          'driver_id': 1,
          'created_at': DateTime(2022, 09, 12, 12).toString(),
          'start': 'Darmstadt',
          'start_lat': 49.222,
          'start_lng': 49.222,
          'start_time': DateTime(2022, 09, 12, 16).toString(),
          'end': 'Frankfurt',
          'end_lat': 50.110,
          'end_lng': 49.222,
          'end_time': DateTime(2022, 09, 12, 20).toString(),
          'seats': 2,
          'cancelled': false,
          'hide_in_list_view': false,
        }
      ]));
      final List<dynamic> data =
          await SupabaseManager.supabaseClient.from('drives').select('driver_id, seats').eq('driver_id', '1');
      Drive drive = Drive.fromJson(data[0]);
      expect(drive.driverId, 1);
    });

    test('test without explicit URL', () async {
      when(driveProcessor.processUrl(any)).thenReturn(jsonEncode([
        {
          'id': 1,
          'driver_id': 1,
          'created_at': DateTime(2022, 09, 12, 12).toString(),
          'start': 'Darmstadt',
          'start_lat': 49.222,
          'start_lng': 49.222,
          'start_time': DateTime(2022, 09, 12, 16).toString(),
          'end': 'Frankfurt',
          'end_lat': 50.110,
          'end_lng': 49.222,
          'end_time': DateTime(2022, 09, 12, 20).toString(),
          'seats': 2,
          'cancelled': false,
          'hide_in_list_view': false,
        }
      ]));
    });
  });
}
