import 'dart:convert';
import 'package:mockito/mockito.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/drives/models/drive.dart';
import 'package:motis_mitfahr_app/util/supabase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'mock_server.dart';
import 'mock_server.mocks.dart';

// Die Klasse UrlProcessor muss zu Beginn jeder Testdatei implementiert werden und die Methode processUrl überschrieben werden
// Wird die Methode ProcessUrl aufgrufen, wird für den dort definierten Fall (in dem Beispiel client.from('drives').select('driver_id,seats')) die Antwort definiert
// Die Datenbankabfrage an den Client wird so abgefangen und das gewünschte Ergebnis zurückgegeben.
// Um herauszufinden welche URL durch die jeweilige Datenbankabfrage generiert wird, einfach den auskommentierten Print-Aufruf in der mockServer.Dart Datei aktivieren

void main() {
  MockUrlProcessor driveProcesor = MockUrlProcessor();
  //setup muss in jeder Testklasse einmal aufgerufen werden
  setUp(() async {
    await MockServer.initialize();
    MockServer.handleRequests(driveProcesor);
    SupabaseManager.setClient(MockServer.client);
  });
  //tearDown muss in jeder Testklasse einmal aufgerufen werden
  tearDown(() async {
    MockServer.tearDown();
  });

  group('basic test', () {
    test('test with explicit URL', () async {
      when(driveProcesor.processUrl('/rest/v1/drives?select=driver_id%2Cseats&driver_id=eq.1')).thenReturn(jsonEncode([
        {'drive_id': 1, 'seats': 2},
        {'drive_id': 2, 'seats': 1},
      ]));
      final data = await SupabaseManager.supabaseClient.from('drives').select('driver_id, seats').eq('driver_id', '1');
      print(data);
    });
    test('test without explicit URL', () async {
      when(driveProcesor.processUrl(any)).thenReturn(jsonEncode([
        {
          'id': 1,
          'driver_id': 1,
          'created_at': DateTime(2022, 09, 12, 12).toString(),
          'start': 'Darmstadt',
          'start_time': DateTime(2022, 09, 12, 16).toString(),
          'end': 'Frankfurt',
          'end_time': DateTime(2022, 09, 12, 20).toString(),
          'seats': 2,
          'cancelled': false,
        }
      ]));
      final data = await Drive.getDrivesOfUser(1);
      print(data);
    });
  });
}
