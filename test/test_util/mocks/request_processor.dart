import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'request_processor.mocks.dart';

class ProcessorResult {
  final String body;
  final int statusCode;

  ProcessorResult(this.body, {required this.statusCode});
}

class ProcessorPostExpectation {
  final PostExpectation expectation;

  ProcessorPostExpectation(this.expectation);

  void thenReturnJson(dynamic json, {int statusCode = 200}) {
    expectation.thenReturn(
      ProcessorResult(jsonEncode(json), statusCode: statusCode),
    );
  }
}

@GenerateMocks([RequestProcessor])
class RequestProcessor {
  ProcessorResult process(String url, {String? method, Map<String, dynamic>? body}) {
    throw UnimplementedError();
  }
}

ProcessorPostExpectation whenRequest(
  MockRequestProcessor processor, {
  Matcher? urlMatcher,
  Matcher? methodMatcher,
  Matcher? bodyMatcher,
}) {
  return ProcessorPostExpectation(
    when(processor.process(
      argThat(urlMatcher ?? anything),
      method: argThat(methodMatcher ?? anything, named: 'method'),
      body: argThat(bodyMatcher ?? anything, named: 'body'),
    )),
  );
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
