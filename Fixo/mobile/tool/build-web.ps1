param([string]$ApiBaseUrl = 'https://fixo-api.vercel.app/api/v1')
$ErrorActionPreference = 'Stop'
$mobileRoot = Split-Path -Parent $PSScriptRoot
Push-Location $mobileRoot
try {
    flutter build web --release --pwa-strategy=none "--dart-define=FIXO_API_BASE_URL=$ApiBaseUrl"
    if ($LASTEXITCODE -ne 0) { throw 'FIXO web build failed.' }
    Copy-Item -LiteralPath web/retire_flutter_service_worker.js -Destination build/web/flutter_service_worker.js
    Copy-Item -LiteralPath vercel.static.json -Destination build/web/vercel.json
    if (Test-Path -LiteralPath .vercel/project.json) {
        New-Item -ItemType Directory -Path build/web/.vercel -Force | Out-Null
        Copy-Item -LiteralPath .vercel/project.json -Destination build/web/.vercel/project.json
    }
} finally { Pop-Location }
