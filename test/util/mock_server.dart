import 'dart:async';
import 'dart:io';

import 'package:mockito/annotations.dart';
import 'package:supabase/supabase.dart';

import 'package:motis_mitfahr_app/util/supabase.dart';

class MockServer {
  static const apiKey = 'supabaseKey';
  static late HttpServer mockServer;

  static Future<void> handleRequests(UrlProcessor processor) async {
    await for (final HttpRequest request in mockServer) {
      final url = request.uri.toString();
      if (url.startsWith("/rest")) {
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(processor.processUrl(url))
          ..close();
      }
    }
  }

  static initialize() async {
    mockServer = await HttpServer.bind('localhost', 0);
    SupabaseClient client = SupabaseClient(
      'http://${mockServer.address.host}:${mockServer.port}',
      apiKey,
      headers: {
        'X-Client-Info': 'supabase-flutter/0.0.0',
      },
    );
    SupabaseManager.setClient(client);
  }
}

@GenerateMocks([UrlProcessor])
class UrlProcessor {
  String processUrl(String url) {
    return "";
  }
}
