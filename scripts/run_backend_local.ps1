Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Push-Location "$PSScriptRoot\..\server"
try {
  if (-not $env:MEDCARE_JWT_SECRET) {
    $env:MEDCARE_JWT_SECRET = "dev-local-secret-change-before-production"
  }
  if (-not $env:MEDCARE_DB_PATH) {
    $env:MEDCARE_DB_PATH = "medcare_server.sqlite"
  }
  dart pub get
  dart run bin/server.dart
} finally {
  Pop-Location
}
