import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:motis_mitfahr_app/util/supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'request_processor.dart';

class MockServer {
  static void setProcessor(RequestProcessor processor) {
    SupabaseManager.setClient(
      SupabaseClient(
        '',
        '',
        httpClient: MockClient(
          (request) {
            // Uncomment this to see the requests
            // print('Request: ${request.url}');
            // print('Body: ${request.body}');
            // print('Method: ${request.method}');

            final ProcessorResult result = processor.process(
              request.url.toString(),
              method: request.method,
              body: request.body.isEmpty ? null : jsonDecode(request.body),
            );

            return Future.value(
              Response(
                result.body,
                result.statusCode,
                headers: {
                  'content-type': 'application/json',
                },
                request: request,
              ),
            );
          },
        ),
      ),
    );
  }
}
