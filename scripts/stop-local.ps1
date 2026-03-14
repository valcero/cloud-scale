Write-Host "Stopping CloudScale..." -ForegroundColor Yellow
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location "$projectRoot\docker"
docker-compose down
Write-Host "CloudScale stopped." -ForegroundColor Green
Set-Location $projectRoot
