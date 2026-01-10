# AutoMail - Set Email Refresh Rate
# Usage: .\set-refresh.ps1 -seconds 300

param(
    [Parameter(Mandatory=$true)]
    [int]$Seconds
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$ConfigPath = "$ProjectRoot\config.json"

if (-not (Test-Path $ConfigPath)) {
    Write-Host "Config file not found at $ConfigPath" -ForegroundColor Red
    exit 1
}

$config = Get-Content $ConfigPath | ConvertFrom-Json

$oldValue = $config.email.refresh_interval_seconds
$config.email.refresh_interval_seconds = $Seconds

$config | ConvertTo-Json -Depth 4 | Out-File $ConfigPath -Encoding UTF8

Write-Host "Email refresh rate updated:" -ForegroundColor Cyan
Write-Host "  Old: $oldValue seconds ($([math]::Round($oldValue/60, 1)) min)" -ForegroundColor Gray
Write-Host "  New: $Seconds seconds ($([math]::Round($Seconds/60, 1)) min)" -ForegroundColor Green
Write-Host "`nRestart backend for changes to take effect: .\restart.ps1" -ForegroundColor Yellow
