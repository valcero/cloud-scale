#!/bin/bash
set -e

echo "============================================"
echo "  CloudScale - Local Development Startup"
echo "  (100% FREE - no AWS account needed)"
echo "============================================"
echo ""

cd "$(dirname "$0")/.."

echo "[1/4] Starting infrastructure (PostgreSQL, LocalStack, Prometheus, Grafana, OpenSearch)..."
cd docker
docker-compose up -d postgres localstack prometheus grafana opensearch opensearch-dashboards
echo "Waiting for services to be healthy..."
sleep 10

echo ""
echo "[2/4] Building microservice images..."
docker-compose build auth-service order-service payment-service analytics-service

echo ""
echo "[3/4] Starting microservices..."
docker-compose up -d auth-service order-service payment-service analytics-service

echo ""
echo "[4/4] Running Terraform against LocalStack..."
cd ../terraform
cp terraform.tfvars.example terraform.tfvars 2>/dev/null || true
terraform init -input=false
terraform apply -auto-approve

echo ""
echo "============================================"
echo "  CloudScale is running!"
echo "============================================"
echo ""
echo "  Microservices:"
echo "    Auth:       http://localhost:3001/health/live"
echo "    Orders:     http://localhost:3002/health/live"
echo "    Payments:   http://localhost:3003/health/live"
echo "    Analytics:  http://localhost:3004/health/live"
echo ""
echo "  Observability:"
echo "    Prometheus: http://localhost:9090"
echo "    Grafana:    http://localhost:3000  (admin/admin)"
echo "    OpenSearch: http://localhost:5601"
echo ""
echo "  AWS (LocalStack):"
echo "    Endpoint:   http://localhost:4566"
echo "    S3:         awslocal s3 ls"
echo "    Kinesis:    awslocal kinesis list-streams"
echo ""
echo "  Database:"
echo "    PostgreSQL: localhost:5432 (cloudscale_admin/localdev123)"
echo ""
echo "  Stop everything:  cd docker && docker-compose down"
echo "============================================"
