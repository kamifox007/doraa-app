# doraa

A Flutter app for rider/driver registration and ride flow with Supabase integration.

## Run with real Supabase credentials

From the project root, run:

```bash
C:\flutter\bin\flutter.bat run \
  --dart-define=SUPABASE_URL=https://zszqfbiomkfevkmtnoho.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

If the values are missing or still dummy, the app will show a warning banner and prevent the real registration flow from continuing.

## Database setup

Run the SQL script in [supabase/sql/00_deploy_all.sql](supabase/sql/00_deploy_all.sql) inside your Supabase SQL Editor before testing registration.
