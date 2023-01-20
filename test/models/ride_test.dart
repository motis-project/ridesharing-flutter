import 'package:flutter_test/flutter_test.dart';

import '../util/mock_server.dart';
import '../util/mock_server.mocks.dart';

void main() {
  MockUrlProcessor rideProcessor = MockUrlProcessor();
  setUp(() async {
    MockServer.setProcessor(rideProcessor);
  });
}
