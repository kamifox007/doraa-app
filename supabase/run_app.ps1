param(
  [string]$SupabaseUrl = $env:SUPABASE_URL,
  [string]$SupabaseAnonKey = $env:SUPABASE_ANON_KEY,
  [string]$SupabasePublishableKey = $env:SUPABASE_PUBLISHABLE_KEY,
  [string]$StitchBaseUrl = $env:STITCH_BASE_URL
)

if ([string]::IsNullOrWhiteSpace($SupabaseUrl)) {
  $SupabaseUrl = Read-Host "Enter SUPABASE_URL"
}

if ([string]::IsNullOrWhiteSpace($SupabaseAnonKey)) {
  $SupabaseAnonKey = $SupabasePublishableKey
}

if ([string]::IsNullOrWhiteSpace($SupabaseAnonKey)) {
  $SupabaseAnonKey = Read-Host "Enter SUPABASE_ANON_KEY or SUPABASE_PUBLISHABLE_KEY"
}

if ([string]::IsNullOrWhiteSpace($StitchBaseUrl)) {
  $StitchBaseUrl = Read-Host "Enter STITCH_BASE_URL (press Enter to skip)"
}

$arguments = @(
  "run",
  "--dart-define=SUPABASE_URL=$SupabaseUrl",
  "--dart-define=SUPABASE_ANON_KEY=$SupabaseAnonKey"
)

if (-not [string]::IsNullOrWhiteSpace($SupabasePublishableKey)) {
  $arguments += "--dart-define=SUPABASE_PUBLISHABLE_KEY=$SupabasePublishableKey"
}

if (-not [string]::IsNullOrWhiteSpace($StitchBaseUrl)) {
  $arguments += "--dart-define=STITCH_BASE_URL=$StitchBaseUrl"
}

Write-Host "Starting Flutter app..." -ForegroundColor Cyan
& flutter @arguments
