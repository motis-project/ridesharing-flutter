./scripts/coverage_helper.sh
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
if [[ "$OSTYPE" == "darwin"* ]]; then
    open coverage/html/index.html
else
    start coverage/html/index.html
fi
