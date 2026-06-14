# LiveBench startup script for Windows
# This script starts both the backend API and frontend

$projectRoot = Get-Location
Write-Host "Launching ClawWork Project..." -ForegroundColor Green
Write-Host "Project path: $projectRoot" -ForegroundColor Cyan
Write-Host ""

# Check Python and Node.js
Write-Host "Checking environment..." -ForegroundColor Blue
$pythonVersion = python --version 2>&1
$nodeVersion = node --version 2>&1
Write-Host "  Python: $pythonVersion" -ForegroundColor Gray
Write-Host "  Node.js: $nodeVersion" -ForegroundColor Gray
Write-Host ""

# Create logs directory
if (-not (Test-Path "logs")) {
    New-Item -ItemType Directory -Path "logs" | Out-Null
}

Write-Host "Installing/checking Python dependencies..." -ForegroundColor Blue
Write-Host "  (This may take 1-2 minutes)" -ForegroundColor Gray

# Install Python dependencies in background
$requirementsPath = Join-Path $projectRoot "requirements.txt"
$pipProcess = Start-Process -FilePath "python" -ArgumentList "-m pip install -q -r $requirementsPath" `
    -RedirectStandardOutput (Join-Path $projectRoot "logs\pip.log") `
    -PassThru -NoNewWindow

Write-Host ""
Write-Host "Frontend:" -ForegroundColor Yellow
Write-Host "  Starting frontend dev server..." -ForegroundColor Gray
Set-Location frontend
$frontendLogPath = Join-Path (Get-Location) "..\logs\frontend.log"
$frontendProcess = Start-Process -FilePath "npm" -ArgumentList "run dev" `
    -RedirectStandardOutput $frontendLogPath `
    -PassThru -NoNewWindow
Set-Location ..
Write-Host "  Frontend PID: $($frontendProcess.Id)" -ForegroundColor Gray
Start-Sleep -Seconds 3

Write-Host ""
Write-Host "Backend:" -ForegroundColor Yellow
Write-Host "  Starting API server..." -ForegroundColor Gray

# Wait for pip installation to complete
Wait-Process -Id $pipProcess.Id -Timeout 300 -ErrorAction SilentlyContinue
Write-Host "  Python dependencies installed" -ForegroundColor Gray

$apiLogPath = Join-Path $projectRoot "logs\api.log"
$apiProcess = Start-Process -FilePath "python" -ArgumentList "livebench/api/server.py" `
    -RedirectStandardOutput $apiLogPath `
    -PassThru -NoNewWindow
Write-Host "  API PID: $($apiProcess.Id)" -ForegroundColor Gray

Start-Sleep -Seconds 2

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host "Services Started!" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host ""
Write-Host "Access URLs:" -ForegroundColor Cyan
Write-Host "  Frontend: http://localhost:3000" -ForegroundColor Yellow
Write-Host "  API:      http://localhost:8000" -ForegroundColor Yellow
Write-Host "  Docs:     http://localhost:8000/docs" -ForegroundColor Yellow
Write-Host ""
Write-Host "Log files:" -ForegroundColor Cyan
Write-Host "  Frontend: logs\frontend.log" -ForegroundColor Gray
Write-Host "  API:      logs\api.log" -ForegroundColor Gray
Write-Host ""
Write-Host "Press Ctrl+C to stop services" -ForegroundColor Red
Write-Host ""

# Monitor services
while ($true) {
    $frontendRunning = Get-Process -Id $frontendProcess.Id -ErrorAction SilentlyContinue
    $apiRunning = Get-Process -Id $apiProcess.Id -ErrorAction SilentlyContinue
    
    $frontendStatus = if ($frontendRunning) { "[OK]" } else { "[STOPPED]" }
    $apiStatus = if ($apiRunning) { "[OK]" } else { "[STOPPED]" }
    
    Write-Host "Frontend: $frontendStatus  API: $apiStatus" -ForegroundColor Gray -NoNewline
    Write-Host "`r" -NoNewline
    
    Start-Sleep -Seconds 2
}
