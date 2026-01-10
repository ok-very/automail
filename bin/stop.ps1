# AutoMail - Stop All Services
# Usage: .\stop.ps1

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "Stopping AutoMail Services..." -ForegroundColor Cyan

# Try to read saved PIDs
$pidFile = "$ScriptDir\.running.json"
if (Test-Path $pidFile) {
    $pids = Get-Content $pidFile | ConvertFrom-Json
    
    try {
        if ($pids.ApiPid) {
            Stop-Process -Id $pids.ApiPid -Force -ErrorAction SilentlyContinue
            Write-Host "  Stopped API Server (PID: $($pids.ApiPid))" -ForegroundColor Yellow
        }
        if ($pids.FrontendPid) {
            Stop-Process -Id $pids.FrontendPid -Force -ErrorAction SilentlyContinue
            Write-Host "  Stopped Frontend (PID: $($pids.FrontendPid))" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  Some processes already stopped" -ForegroundColor Gray
    }
    
    Remove-Item $pidFile -Force
}

# Also kill any lingering python/node processes on our ports
Write-Host "`nCleaning up port bindings..." -ForegroundColor Gray

# Kill processes on port 8000 (API)
$apiProc = Get-NetTCPConnection -LocalPort 8000 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique
if ($apiProc) {
    Stop-Process -Id $apiProc -Force -ErrorAction SilentlyContinue
    Write-Host "  Freed port 8000" -ForegroundColor Yellow
}

# Kill processes on port 5173 (Vite)
$viteProc = Get-NetTCPConnection -LocalPort 5173 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique
if ($viteProc) {
    Stop-Process -Id $viteProc -Force -ErrorAction SilentlyContinue
    Write-Host "  Freed port 5173" -ForegroundColor Yellow
}

Write-Host "`n=== All Services Stopped ===" -ForegroundColor Green
