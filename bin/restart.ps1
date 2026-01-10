# AutoMail - Restart Backend Only
# Usage: .\restart.ps1 [-frontend]

param(
    [switch]$Frontend  # Also restart frontend
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

Write-Host "Restarting AutoMail Backend..." -ForegroundColor Cyan

# Kill API server on port 8000
$apiProc = Get-NetTCPConnection -LocalPort 8000 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique
if ($apiProc) {
    Stop-Process -Id $apiProc -Force -ErrorAction SilentlyContinue
    Write-Host "  Stopped old API server" -ForegroundColor Yellow
    Start-Sleep -Seconds 1
}

# Start new API server
Write-Host "  Starting API Server..." -ForegroundColor Yellow
$apiProcess = Start-Process -FilePath "python" -ArgumentList "api_server.py" -WorkingDirectory "$ProjectRoot\scripts" -PassThru -WindowStyle Minimized
Write-Host "  API Server restarted (PID: $($apiProcess.Id))" -ForegroundColor Green

if ($Frontend) {
    # Kill frontend on port 5173
    $viteProc = Get-NetTCPConnection -LocalPort 5173 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique
    if ($viteProc) {
        Stop-Process -Id $viteProc -Force -ErrorAction SilentlyContinue
        Write-Host "  Stopped old frontend" -ForegroundColor Yellow
        Start-Sleep -Seconds 1
    }
    
    Write-Host "  Starting Frontend..." -ForegroundColor Yellow
    $frontendProcess = Start-Process -FilePath "npm" -ArgumentList "run", "dev" -WorkingDirectory "$ProjectRoot\app" -PassThru -WindowStyle Minimized
    Write-Host "  Frontend restarted (PID: $($frontendProcess.Id))" -ForegroundColor Green
}

Write-Host "`n=== Restart Complete ===" -ForegroundColor Green
