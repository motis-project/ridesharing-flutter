# Motis Mitfahr-App

A ride-sharing app by the Motis team.

## Getting Started

### Prerequisites

- [Flutter](https://flutter.dev/docs/get-started/install)
- A working emulator or device

### Installing

- Clone the repository
- Insert the environment variables in `.env`, following the `example.env` file. You can find the supabase url and key in the supabase project settings (use the `anon` key for the `SUPABASE_KEY` variable)
- Run `flutter pub get` to install all dependencies

## Local Development

- Run `flutter run` to start the app

- Before committing, please do the following:

  - Run `dart format --line-length=120 $(find lib test -name "*.dart" -not -name "*.mocks.dart")` to format the code
  - Run `flutter analyze` to check for any static analysis issues (not really needed if you use VSCode)
  - Run `flutter test` to run all tests

## Running the tests

- Run `flutter test` to run all tests

- Run `./scripts/coverage.sh` (`lcov` required for MacOS) to generate a html report in the `coverage/html` folder and open the report in the browser automatically.
