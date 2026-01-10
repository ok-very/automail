# AutoMail - Quick Status Check
# Usage: .\status.ps1

Write-Host "`n=== AutoMail Status ===" -ForegroundColor Cyan

# Check API Server
$apiPort = Get-NetTCPConnection -LocalPort 8000 -State Listen -ErrorAction SilentlyContinue
if ($apiPort) {
    Write-Host "`n[API Server] " -NoNewline
    Write-Host "RUNNING" -ForegroundColor Green
    Write-Host "  URL: http://localhost:8000"
    Write-Host "  Docs: http://localhost:8000/docs"
} else {
    Write-Host "`n[API Server] " -NoNewline
    Write-Host "STOPPED" -ForegroundColor Red
}

# Check Frontend
$frontendPort = Get-NetTCPConnection -LocalPort 5173 -State Listen -ErrorAction SilentlyContinue
if ($frontendPort) {
    Write-Host "`n[Frontend] " -NoNewline
    Write-Host "RUNNING" -ForegroundColor Green
    Write-Host "  URL: http://localhost:5173"
} else {
    Write-Host "`n[Frontend] " -NoNewline
    Write-Host "STOPPED" -ForegroundColor Red
}

# Show config
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$ConfigPath = "$ProjectRoot\config.json"

if (Test-Path $ConfigPath) {
    $config = Get-Content $ConfigPath | ConvertFrom-Json
    Write-Host "`n[Config]" -ForegroundColor Yellow
    Write-Host "  Refresh Rate: $($config.email.refresh_interval_seconds)s ($([math]::Round($config.email.refresh_interval_seconds/60, 1)) min)"
    Write-Host "  Auto Refresh: $($config.email.auto_refresh)"
}

Write-Host ""
