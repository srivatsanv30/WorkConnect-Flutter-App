# Run WorkConnect backend + Flutter web (Chrome)
# Usage: run this script from any PowerShell. To allow starting services, run as Administrator.

function Check-Command($cmd, $name) {
  if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
    Write-Host "[MISSING] $name - please install and ensure it's on PATH." -ForegroundColor Red
    return $false
  }
  Write-Host "[OK] $name found." -ForegroundColor Green
  return $true
}

Write-Host "Starting WorkConnect helper script..." -ForegroundColor Cyan

$okFlutter = Check-Command flutter Flutter
$okNode = Check-Command node Node
$okNpm = Check-Command npm NPM
$okMongosh = Check-Command mongosh Mongosh

$projectRoot = (Split-Path -Parent $PSScriptRoot)
$backendPath = Join-Path $projectRoot 'workconnect-backend\workconnect-backend'
$flutterPath = $projectRoot

Write-Host "Project root: $projectRoot"
Write-Host "Backend path: $backendPath"
Write-Host "Flutter path: $flutterPath"

# Try to start MongoDB service if present
$svc = Get-Service -Name MongoDB -ErrorAction SilentlyContinue
if ($svc) {
  if ($svc.Status -ne 'Running') {
    Write-Host "Attempting to start MongoDB service..." -ForegroundColor Yellow
    try {
      Start-Service MongoDB -ErrorAction Stop
      Write-Host "MongoDB service started." -ForegroundColor Green
    } catch {
      Write-Host "Failed to start MongoDB service (may require admin)." -ForegroundColor Yellow
    }
  } else { Write-Host "MongoDB service already running." -ForegroundColor Green }
} else {
  Write-Host "MongoDB service not found. If you run mongod directly, please ensure it's running." -ForegroundColor Yellow
}

# Backend: install deps, copy .env if missing, run dev server in a new terminal
if (Test-Path $backendPath) {
  Write-Host "Preparing backend..." -ForegroundColor Cyan
  Push-Location $backendPath
  npm install
  if (-not (Test-Path .env) -and (Test-Path .env.example)) {
    Copy-Item .env.example .env
    Write-Host "Copied .env from .env.example. Edit $backendPath\.env if needed." -ForegroundColor Yellow
  }
  Pop-Location

  Write-Host "Launching backend (nodemon) in a new PowerShell window..." -ForegroundColor Cyan
  Start-Process powershell -ArgumentList "-NoExit","-Command","Set-Location '$backendPath'; npm run dev" -WindowStyle Normal
} else {
  Write-Host "Backend path not found: $backendPath" -ForegroundColor Red
}

# Flutter: get packages and run in Chrome in a new terminal
if (Test-Path $flutterPath) {
  Write-Host "Launching Flutter web (Chrome) in a new PowerShell window..." -ForegroundColor Cyan
  Start-Process powershell -ArgumentList "-NoExit","-Command","Set-Location '$flutterPath'; flutter pub get; flutter run -d chrome" -WindowStyle Normal
} else {
  Write-Host "Flutter path not found: $flutterPath" -ForegroundColor Red
}

Write-Host "Script finished: backend and Flutter launched in separate windows (if available)." -ForegroundColor Green
