param(
  [switch]$SkipMobile
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

Write-Host "=== 1. FIXO Backend QA ===" -ForegroundColor Cyan
Push-Location (Join-Path $root "Fixo/backend")
npm run prisma:validate
npm run prisma:generate
npm run lint
npm test
npm audit --omit=dev --audit-level=high
Pop-Location

Write-Host "`n=== 2. FIXO Web QA ===" -ForegroundColor Cyan
Push-Location (Join-Path $root "Fixo/web")
npm run lint
npm run typecheck
npm test
npm run build
npm audit --omit=dev --audit-level=high
Pop-Location

if (-not $SkipMobile) {
  Write-Host "`n=== 3. FIXO Mobile QA ===" -ForegroundColor Cyan
  Push-Location (Join-Path $root "Fixo/mobile")
  flutter analyze
  flutter test
  Pop-Location
}

Write-Host "`nALL FIXO QA CHECKS PASSED!" -ForegroundColor Green
