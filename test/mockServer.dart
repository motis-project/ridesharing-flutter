import 'dart:async';
import 'dart:io';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';

class MockServer {
  static const customApiKey = 'customApiKey';
  static const apiKey = 'supabaseKey';

  static late SupabaseClient client;
  static late HttpServer mockServer;
  static final Set<String> listeners = {};
  static WebSocket? webSocket;
  static StreamSubscription<dynamic>? listener;

  static Future<void> handleRequests(UrlProccessor proccessor, {String? expectedFilter}) async {
    await for (final HttpRequest request in mockServer) {
      final headers = request.headers;
      if (headers.value('X-Client-Info') != 'supabase-flutter/0.0.0') {
        throw 'Proper header not set';
      }
      final url = request.uri.toString();
      //print(url);
      if (url.startsWith("/rest")) {
        final foundApiKey = headers.value('apikey');
        expect(foundApiKey, apiKey);
        if (foundApiKey == customApiKey) {
          expect(headers.value('customfield'), 'customvalue');
        }

        if (expectedFilter != null) {
          expect(url.contains(expectedFilter), isTrue);
        }
        proccessor.processUrl(url, request);
      }
    }
  }

  static initialize() async {
    mockServer = await HttpServer.bind('localhost', 0);
    client = SupabaseClient(
      'http://${mockServer.address.host}:${mockServer.port}',
      apiKey,
      headers: {
        'X-Client-Info': 'supabase-flutter/0.0.0',
      },
    );
  }

  static void tearDown() async {
    listener?.cancel();
    listeners.clear();

    // Wait for the realtime updates to come through
    await Future.delayed(const Duration(milliseconds: 100));

    await webSocket?.close();
    await mockServer.close();
  }
}

abstract class UrlProccessor {
  void processUrl(String url, HttpRequest request);
}
