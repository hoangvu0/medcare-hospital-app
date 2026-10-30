Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "MedCare manual E2E device checklist"
Write-Host "1. Start backend: .\scripts\run_backend_local.ps1"
Write-Host "2. Start app: flutter run --dart-define=MEDCARE_API_BASE_URL=http://127.0.0.1:8080"
Write-Host "3. Login patient: vu@example.com / 123456"
Write-Host "4. Login doctor in another run/session: doctor@medcare.vn / 123456"
Write-Host "5. Open Live Queue on patient."
Write-Host "6. Doctor clicks call-next."
Write-Host "7. Confirm patient queue number updates via SSE without manual refresh."
