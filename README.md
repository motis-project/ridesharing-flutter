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

## Running the tests

- Run `flutter test` to run all tests

- Run `flutter test --coverage` to run all tests and generate a coverage report. You can then run `genhtml coverage/lcov.info -o coverage/html` (`lcov` required for MacOS) to generate a html report in the `coverage/html` folder.
