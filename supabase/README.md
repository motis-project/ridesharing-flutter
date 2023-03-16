# Supabase

This directory contains the files necessary for setting up the Supabase project from scratch. They are not directly used by the app, but are used to configure the Supabase instance. The directory structure represents where the files should be located/uploaded in the Supabase interface.

## Set up Supabase

- Create a new project in [Supabase](https://app.supabase.com/)

- Go to the `Storage` tab, and create a public bucket called `public`, as well as a private bucket called `avatars`.

- Copy the contents of the `email_templates/confirm_signup.html` and `email_templates/reset_password.html` files into the corresponding templates in the `Auth > Email Templates` tab in supabase. Note that you need to replace the source of the logo image with the URL of where you want to host it (We hosted it in the `public` bucket).

- Go to `Auth > URL Configuration` and paste the following two redirect URLS:

  - `io.supabase.flutter://reset-callback/`
  - `io.supabase.flutter://login-callback/`

- Find the connection information for your database in the `Settings > Database` tab. Use these to restore the database from the `database.sql` file in this directory:

  ```bash
  psql -h db.__yourrandomstring__.supabase.co -p 5432 -d postgres -U postgres < supabase/database.sql
  ```

- Run the following in your postgres shell of choice:

  ```sql
  select cron.schedule (
    'create-recurring-drives',
    '0 3 * * *', -- Every day at 3am
    $$ select create_drives_from_recurring() $$
  );
  ```

  This schedules a cron job to run the `create_drives_from_recurring` function every day at 3am.

- Find the connection information for your API in the `Settings > API` tab and paste them into the `.env` file (following the style of the `example.env` file). Do the same in the React app (but note that the keys need to be named a little differently there, as you can see in the corresponding `example.env` file in that repository).

## Dumping the database schema

If you are logged in to the Supabase CLI, you can run the following command to dump the database schema into the `database.sql` file:

  ```bash
  supabase db dump > supabase/database.sql
  ```

> **_Note:_** This will overwrite the existing `database.sql` file, so make sure you have committed any changes you want to keep first.
<!-- -->
> **WARNING:** Be sure to remove any sensitive information from the `database.sql` file before committing it to the repository (e.g. the firebase connection string)
