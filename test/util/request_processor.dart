import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'request_processor.mocks.dart';

@GenerateMocks([RequestProcessor])
class RequestProcessor {
  String process(String url, {String? method, Map<String, dynamic>? body}) {
    throw UnimplementedError();
  }
}

void whenRequest(
  MockRequestProcessor processor,
  dynamic response, {
  Matcher? urlMatcher,
  Matcher? methodMatcher,
  Matcher? bodyMatcher,
}) {
  when(
    processor.process(
      argThat(urlMatcher ?? anything),
      method: argThat(methodMatcher ?? anything, named: 'method'),
      body: argThat(bodyMatcher ?? anything, named: 'body'),
    ),
  ).thenReturn(jsonEncode(response));
}

VerificationResult verifyRequest(
  MockRequestProcessor processor, {
  Matcher? urlMatcher,
  Matcher? methodMatcher,
  Matcher? bodyMatcher,
}) {
  urlMatcher ??= anything;
  methodMatcher ??= anything;
  bodyMatcher ??= anything;

  return verify(
    processor.process(
      captureThat(urlMatcher),
      method: captureThat(methodMatcher, named: 'method'),
      body: captureThat(bodyMatcher, named: 'body'),
    ),
  );
}

VerificationResult verifyRequestNever(
  MockRequestProcessor processor, {
  Matcher? urlMatcher,
  Matcher? methodMatcher,
  Matcher? bodyMatcher,
}) {
  urlMatcher ??= anything;
  methodMatcher ??= anything;
  bodyMatcher ??= anything;

  return verifyNever(
    processor.process(
      argThat(urlMatcher),
      method: argThat(methodMatcher, named: 'method'),
      body: argThat(bodyMatcher, named: 'body'),
    ),
  );
}
