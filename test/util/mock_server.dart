import 'dart:async';

import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:mockito/annotations.dart';
import 'package:motis_mitfahr_app/util/supabase.dart';
import 'package:supabase/supabase.dart';

class MockServer {
  static void setProcessor(UrlProcessor processor) {
    SupabaseManager.setClient(
      SupabaseClient(
        '',
        '',
        httpClient: MockClient(
          ((request) {
            // Uncomment this to see the requests
            // print("Request: ${request.url}");
            // print("Body: ${request.body}");
            return Future.value(
              Response(
                processor.processUrl(request.url.toString()),
                200,
                headers: {
                  'content-type': 'application/json',
                },
                request: request,
              ),
            );
          }),
        ),
      ),
    );
  }
}

@GenerateMocks([UrlProcessor])
class UrlProcessor {
  String processUrl(String url) {
    return "";
  }
}
