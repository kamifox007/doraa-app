# Run the combined Supabase deployment script (PowerShell)
# Usage:
# 1) Open PowerShell in project root
# 2) Set $env:DATABASE_URL or supply when prompted
#    $env:DATABASE_URL = 'postgres://postgres:PW@db.xxxx.supabase.co:5432/postgres'
# 3) Run: .\supabase\run_sql.ps1

function Check-Command($name) {
  $null -ne (Get-Command $name -ErrorAction SilentlyContinue)
}

if (-not (Check-Command psql)) {
  Write-Host "psql not found in PATH. Install PostgreSQL client or add psql to PATH." -ForegroundColor Yellow
  Write-Host "You can install from https://www.postgresql.org/download/ or use the Supabase SQL editor in the dashboard." -ForegroundColor Yellow
  exit 1
}

if (-not $env:DATABASE_URL) {
  $input = Read-Host "DATABASE_URL not found. Paste your full Postgres connection URL (or press Enter to cancel)"
  if ([string]::IsNullOrWhiteSpace($input)) {
    Write-Error "No DATABASE_URL provided. Exiting."
    exit 1
  }
  $env:DATABASE_URL = $input
}

$files = @(
  "supabase/sql/00_deploy_all.sql"
)

foreach ($file in $files) {
  if (-not (Test-Path $file)) {
    Write-Error "File not found: $file"
    exit 1
  }
  Write-Host "\n--- Running: $file ---" -ForegroundColor Cyan
  $procInfo = @{ FilePath = 'psql'; ArgumentList = @($env:DATABASE_URL, '-f', $file); RedirectStandardOutput = '$true'; RedirectStandardError = '$true' }
  try {
    $proc = Start-Process -FilePath psql -ArgumentList @($env:DATABASE_URL, '-f', $file) -NoNewWindow -Wait -PassThru -ErrorAction Stop
    if ($proc.ExitCode -ne 0) {
      Write-Error "psql returned exit code $($proc.ExitCode) for $file"
      exit $proc.ExitCode
    }
    Write-Host "Completed: $file" -ForegroundColor Green
  } catch {
    Write-Error ("Error running psql on {0}: {1}" -f $file, $_)
    exit 1
  }
}

Write-Host "\nAll SQL files executed successfully." -ForegroundColor Green
