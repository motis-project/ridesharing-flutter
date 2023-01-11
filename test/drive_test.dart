import 'dart:convert';
import 'package:mockito/mockito.dart';
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
    supabaseClient = MockServer.client;
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
      final data = await supabaseClient.from('drives').select('driver_id, seats').eq('driver_id', '1');
      print(data);
    });
    test('test without explicit URL', () async {
      when(driveProcesor.processUrl(any)).thenReturn(jsonEncode([
        {'drive_id': 1, 'seats': 2},
        {'drive_id': 2, 'seats': 1},
      ]));
      final data = await supabaseClient.from('drives').select('driver_id, seats').eq('driver_id', '1');
      print(data);
    });
  });
}
