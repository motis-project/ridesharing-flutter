./scripts/coverage_helper.sh
if command -v fvm &> /dev/null; then
    fvm flutter test --coverage
else
    flutter test --coverage
fi
    
genhtml coverage/lcov.info -o coverage/html

if [[ "$OSTYPE" == "darwin"* ]]; then
    open coverage/html/index.html
else
    start coverage/html/index.html
fi
