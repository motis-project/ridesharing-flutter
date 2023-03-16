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

- Running the tests:
  - Run `flutter test` to run all tests
  - Run `./scripts/coverage.sh` (`lcov` required for MacOS) to generate a html report in the `coverage/html` folder and open the report in the browser automatically.

- Before committing, please do the following:

  - Run `dart format --line-length=120 $(find lib test -name "*.dart" -not -name "*.mocks.dart")` to format the code
  - Run `flutter analyze` to check for any static analysis issues (not really needed if you use VSCode)
  - Run the tests

### Automatically generate necessary files on checkout

When switching to another branch, there may be translations missing because Flutter still has them generated for the old branch. To automate that, run

```bash
cat >.git/hooks/post-checkout <<EOL
#!/bin/bash 

# This script is called by git when a checkout is performed.
flutter gen-l10n
scripts/coverage_helper.sh
EOL

chmod +x .git/hooks/post-checkout
```

## Idiosyncracies

### Assumptions

- We assume that the user is properly authenticated, i.e. that `currentProfile` is not null, without checking throughout the app (except on pages where they are not required to be authenticated, such as the Registration/Login Process or the Search Ride Page in Anonymous Mode). This is because we only allow users to access the app when they are authenticated.
- We assume throughout our app that users have connection and have built no safeguards concerning that.

### Pages with supabase calls

Pages where we have to fetch data from supabase, such as the `ProfilePage` or the `DriveDetailPage`, typically follow the following pattern:

- There is a constructor with the necessary parameters to fetch the data from supabase, i.e. `id`. In some cases, we also pass the data directly, e.g. `DriveDetailPage.fromDrive(Drive drive)`.
- In the `initState` method, an `async` function (typically `load...`) is called that calls supabase and stores the data in a state variable.
- The `fullyLoaded` variable signifies if that data has been loaded. If `fullyLoaded` is `false`, a `CircularProgressIndicator` is shown instead of the page content.

All methods that are called from such pages will assume that the necessary data for their execution has been loaded and will not check for that. For example, the `approvedRides` getter of the `Drive` model expects that the `rides` have already been loaded.

### Tests

#### Factories

For our tests, we wrote some helper methods in order to mock objects quickly. For example, a `Profile` can be created with `ProfileFactory().generateFake()`. With some exceptions, this creates a fully fledged Profile object with all fields filled with random data.

We also allowed developers to pass parameters to overwrite specific fields. However, dart can't differentiate between parameters that aren't given at all (where we need to generate random data, as seen above) and parameters that are explicitly `null` (e.g. `ProfileFactory().generateFake(name: null)`). Therefore, the parameters can be given as `NullableParameter(value)`, where `value` can be set explicitly to `null`. This way, we can differentiate between the scenarios.

#### Mocking Requests

Flutter replaces the original HTTP client by one that always returns 400. As such, calls to the "Outside world" are prohibited.

In order to mock HTML requests to supabase, we use mockito's processor and our own custom tooling. At the beginning of the test, a mock processor needs to be set via `MockServer.setProcessor(processor)`. `whenRequest` works like mockito's `when`: It captures any HTML request that matches the given Matchers for URL, Body and HTTP method. On that result, it is possible to call `thenReturnJson` (the normal `thenReturn` is not compatible) and thus mock the HTTP response by the server. To generate JSON objects that encapsulate models and foreign relations, use `toJsonForApi`, **NOT** `toJson` (more on that [later](#generating-models-from-and-to-json)). Be careful to mock all requests that are made by the app, otherwise the test will fail.

On the other hand, to intercept a request made by the app to the supabase server, use `verifyRequest` or `verifyRequestNever`. They also allow to give Matchers to match the Request precisely.

> **_NOTE:_** Unfortunately, we were not able to get mocking Network Images to work. As a workaround, we do not use avatar images in our tests (they are always `null`).

### Supabase

#### Generating models from and to JSON

For our communication with supabase, we created one model class per table. When we receive data from supabase, we convert it to a model class using the `fromJson` methods of the models. When we send data to supabase, we convert it to JSON using the `toJson` methods of the models.

In order to generate valid JSON "as the backend" in our tests, we created `toJsonForApi` methods. It will serialize related objects, which is needed for foreign relations and join queries. Futhermore, it will also include the `id` and `created_at` fields (Those are not needed in our communication with the database otherwise, as they are always generated on creation and never updated).

#### Triggers and Functions

We use supabase triggers and functions to do most of the work that has to be automatically performed on our data. This can happen in multiple ways.

- Triggers: A Postgres trigger fires if the specified operation has been performed on a specific table and calls a Postgres function.\
For example, if a driver cancels their drive (`UPDATE` operation on `drives`), a trigger will fire and a Postgres function will automatically cancel all rides of that drive (on the server side). Similarly, notifications are triggered by certain actions.
- RPC calls: Calling Postgres functions from the client side. This is mostly needed where a user needs to have access to data that is usually denied by RLS rules (Row Level Security).\
For example, `rejectRide` is calling a Postgres function, which will update the ride. This is needed because the driver doesn't have update access to the rider's ride.
- Cronjobs: A cronjob is a Postgres function that is called periodically.\
For example, there is a cronjob that creates drives according to the recurrence rule of a recurring drive 30 days in advance server-side.

As such, there is quite a lot of logic performed on our data that is not visible in the app. We try to comment this every time it happens.

### Coverage

We use `lcov` to generate a coverage report (line coverage). For that, the `coverage.sh` script executes the tests with coverage, generates a HTML file and automatically opens it. The `coverage_helper.sh` is run automatically beforehand, generating a file only consisting of imports of every dart file. This is necessary because `lcov` only includes files that are imported in the test files.
