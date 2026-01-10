# AutoMail - Start All Services
# Usage: .\start.ps1

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

Write-Host "Starting AutoMail Services..." -ForegroundColor Cyan

# Start API Server
Write-Host "`n[1/2] Starting API Server..." -ForegroundColor Yellow
$apiProcess = Start-Process -FilePath "python" -ArgumentList "api_server.py" -WorkingDirectory "$ProjectRoot\scripts" -PassThru -WindowStyle Minimized
Write-Host "  API Server started (PID: $($apiProcess.Id))" -ForegroundColor Green

# Wait for API to be ready
Start-Sleep -Seconds 2

# Start Frontend Dev Server
Write-Host "`n[2/2] Starting Frontend..." -ForegroundColor Yellow
$frontendProcess = Start-Process -FilePath "npm" -ArgumentList "run", "dev" -WorkingDirectory "$ProjectRoot\app" -PassThru -WindowStyle Minimized
Write-Host "  Frontend started (PID: $($frontendProcess.Id))" -ForegroundColor Green

# Save PIDs to file for stop script
@{
    ApiPid = $apiProcess.Id
    FrontendPid = $frontendProcess.Id
    StartTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
} | ConvertTo-Json | Out-File "$ScriptDir\.running.json"

Write-Host "`n=== AutoMail Running ===" -ForegroundColor Green
Write-Host "  API:      http://localhost:8000"
Write-Host "  Frontend: http://localhost:5173"
Write-Host "  Docs:     http://localhost:8000/docs"
Write-Host "`nRun .\stop.ps1 to stop all services" -ForegroundColor Gray
