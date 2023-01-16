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

- All package imports should be relative. Furthermore, we use the `import_sorter` package to sort the imports into 4 main groups. You can use the `flutter pub run import_sorter:main --no-comments` to do this.

- Before committing, please do the following:

  - Run `flutter format .` to format the code
  - Run `flutter pub run import_sorter:main --no-comments` to sort the imports
  - Run `flutter analyze` to check for any static analysis issues (not really needed if you use VSCode)
  - Run `flutter test` to run all tests

## Running the tests

- Run `flutter test` to run all tests

- Run `./scripts/coverage.sh` (`lcov` required for MacOS) to generate a html report in the `coverage/html` folder and open the report in the browser automatically.
