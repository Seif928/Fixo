param([switch]$SkipMobile)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
function Invoke-Check {
  param([string]$Executable, [string[]]$Arguments)
  & $Executable @Arguments
  if ($LASTEXITCODE -ne 0) { throw "$Executable failed with exit code $LASTEXITCODE" }
}
if (-not $env:TEST_DATABASE_URL) { throw 'Set TEST_DATABASE_URL explicitly to local fixo_test.' }
$testTarget = [uri]$env:TEST_DATABASE_URL
if ($testTarget.Host -ne 'localhost' -or $testTarget.Port -ne 5432 -or
    $testTarget.AbsolutePath -ne '/fixo_test') { throw 'Only localhost:5432/fixo_test is allowed.' }
Push-Location (Join-Path $projectRoot 'Fixo/backend')
try {
  Invoke-Check npm @('run','prisma:validate')
  Invoke-Check npm @('run','prisma:generate')
  Invoke-Check npm @('run','lint')
  Invoke-Check npm @('test')
} finally { Pop-Location }
if (-not $SkipMobile) {
  Push-Location (Join-Path $projectRoot 'Fixo/mobile')
  try {
    Invoke-Check flutter @('analyze','--no-pub')
    Invoke-Check flutter @('test','--no-pub')
    Invoke-Check flutter @('build','web','--no-pub','--release','--no-wasm-dry-run','--dart-define=FIXO_API_BASE_URL=https://fixo-api.vercel.app/api/v1')
  } finally { Pop-Location }
}
Write-Host 'All requested FIXO checks passed.' -ForegroundColor Green
