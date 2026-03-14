Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  CloudScale - Local Development Startup" -ForegroundColor Cyan
Write-Host "  (100% FREE - no AWS account needed)" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$projectRoot = Split-Path -Parent $PSScriptRoot

Write-Host "[1/4] Starting infrastructure (PostgreSQL, LocalStack, Prometheus, Grafana, OpenSearch)..." -ForegroundColor Yellow
Set-Location "$projectRoot\docker"
docker-compose up -d postgres localstack prometheus grafana opensearch opensearch-dashboards
Write-Host "Waiting for services to be healthy..."
Start-Sleep -Seconds 10

Write-Host ""
Write-Host "[2/4] Building microservice images..." -ForegroundColor Yellow
docker-compose build auth-service order-service payment-service analytics-service

Write-Host ""
Write-Host "[3/4] Starting microservices..." -ForegroundColor Yellow
docker-compose up -d auth-service order-service payment-service analytics-service

Write-Host ""
Write-Host "[4/4] Running Terraform against LocalStack..." -ForegroundColor Yellow
Set-Location "$projectRoot\terraform"
if (-not (Test-Path "terraform.tfvars")) {
    Copy-Item "terraform.tfvars.example" "terraform.tfvars"
}
terraform init -input=false
terraform apply -auto-approve

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  CloudScale is running!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Microservices:" -ForegroundColor White
Write-Host "    Auth:       http://localhost:3001/health/live"
Write-Host "    Orders:     http://localhost:3002/health/live"
Write-Host "    Payments:   http://localhost:3003/health/live"
Write-Host "    Analytics:  http://localhost:3004/health/live"
Write-Host ""
Write-Host "  Observability:" -ForegroundColor White
Write-Host "    Prometheus: http://localhost:9090"
Write-Host "    Grafana:    http://localhost:3000  (admin/admin)"
Write-Host "    OpenSearch: http://localhost:5601"
Write-Host ""
Write-Host "  AWS (LocalStack):" -ForegroundColor White
Write-Host "    Endpoint:   http://localhost:4566"
Write-Host ""
Write-Host "  Database:" -ForegroundColor White
Write-Host "    PostgreSQL: localhost:5432 (cloudscale_admin/localdev123)"
Write-Host ""
Write-Host "  Stop everything:  cd docker; docker-compose down" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Cyan

Set-Location $projectRoot
