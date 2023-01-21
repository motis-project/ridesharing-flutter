./scripts/coverage_helper.sh
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html