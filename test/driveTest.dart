import 'dart:convert';
import 'dart:io';
import 'package:flutter_app/util/supabase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'mockServer.dart';

// DIe Klasse UrlProccessor muss zu begin jeder Testdatei implementiert werden und die Methode processUrl überschrieben werden
// Wird die Methode ProcessUrl aufgrufen, wird für den dort definierten Fall (in dem Beispiel client.from('drives').select('driver_id,seats')) die Antwort definiert
// Die Datenbankabfrage an den Client wird so abgefangen und das gefünschte ergebnis zurückgegeben.
// Um herauszifinden welche URL durch die jeweilige Datenbankabfrage generiert wird, einfach den auskommentierten Print-Aufruf in der mockServer.Dart Datei aktivieren
class DriveProccesor extends UrlProccessor {
  @override
  void processUrl(String url, HttpRequest request) {
    {
      if (url == '/rest/v1/drives?select=driver_id%2Cseats') {
        final jsonString = jsonEncode([
          {'drive_id': 1, 'seats': 2},
          {'drive_id': 2, 'seats': 1},
        ]);
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonString)
          ..close();
      }
    }
  }
}

void main() {
  //setup muss in jeder Testklasse einmal aufgerufen werden
  setUp(() async {
    await MockServer.initialize();
    MockServer.handleRequests(DriveProccesor());
    supabaseClient = MockServer.client;
  });
  //tearDown muss in jeder Testklasse einmal aufgerufen werden
  tearDown(() async {
    MockServer.tearDown();
  });

  group('basic test', () {
    test('test mock server', () async {
      final data = await supabaseClient.from('drives').select('driver_id, seats');
      expect((data as List).length, 2);
    });
  });
}
