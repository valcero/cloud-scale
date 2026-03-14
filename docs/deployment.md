# CloudScale Deployment Guide

Everything runs locally for free. No AWS account needed.

## Prerequisites

| Tool | Install | Cost |
|------|---------|------|
| Docker Desktop | [docker.com](https://www.docker.com/products/docker-desktop/) | Free |
| Terraform | [hashicorp.com](https://developer.hashicorp.com/terraform/downloads) or `choco install terraform` | Free |
| Minikube (optional) | `choco install minikube` or [minikube.sigs.k8s.io](https://minikube.sigs.k8s.io/) | Free |
| Helm (optional) | `choco install kubernetes-helm` | Free |
| Node.js 20 | [nodejs.org](https://nodejs.org/) (for development) | Free |

## Method 1: Docker Compose (Recommended)

The fastest way to get the full platform running.

### Start

```powershell
# Windows
.\scripts\start-local.ps1

# Linux/Mac
./scripts/start-local.sh
```

Or manually:

```bash
cd docker
docker-compose up -d
```

### What runs

- **PostgreSQL** (port 5432) – database
- **LocalStack** (port 4566) – free AWS emulator (S3, Kinesis, Lambda)
- **auth-service** (port 3001) – user auth
- **order-service** (port 3002) – orders
- **payment-service** (port 3003) – payments
- **analytics-service** (port 3004) – events & analytics
- **Prometheus** (port 9090) – metrics
- **Grafana** (port 3000) – dashboards (login: admin/admin)
- **OpenSearch** (port 9200) – log storage
- **OpenSearch Dashboards** (port 5601) – log viewer

### Verify

```bash
# Health checks
curl http://localhost:3001/health/live
curl http://localhost:3002/health/live
curl http://localhost:3003/health/live
curl http://localhost:3004/health/live

# Register + Login
curl -X POST http://localhost:3001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@demo.com","password":"test123"}'

# Check Prometheus is scraping services
# Open http://localhost:9090/targets

# Check Grafana dashboard
# Open http://localhost:3000 (admin/admin)

# Check LocalStack
curl http://localhost:4566/_localstack/health
```

### Stop

```powershell
.\scripts\stop-local.ps1
# or
cd docker && docker-compose down

# Remove all data volumes too:
cd docker && docker-compose down -v
```

## Method 2: Terraform + LocalStack

Demonstrates IaC skills without any AWS cost.

```bash
# Make sure LocalStack is running (from docker-compose)
cd docker && docker-compose up -d localstack

# Apply Terraform against LocalStack
cd ../terraform
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply -auto-approve

# Verify resources were created
aws --endpoint-url=http://localhost:4566 s3 ls
aws --endpoint-url=http://localhost:4566 kinesis list-streams
```

## Method 3: Minikube (Full Kubernetes Experience)

Free local Kubernetes cluster.

### Setup

```bash
# Start Minikube
minikube start --memory=4096 --cpus=2

# Use Minikube's Docker daemon so images are available
eval $(minikube docker-env)   # Linux/Mac
# Windows PowerShell: minikube docker-env --shell powershell | Invoke-Expression

# Build all images inside Minikube
docker build -f docker/Dockerfile.auth-service -t cloudscale/auth-service:latest .
docker build -f docker/Dockerfile.order-service -t cloudscale/order-service:latest .
docker build -f docker/Dockerfile.payment-service -t cloudscale/payment-service:latest .
docker build -f docker/Dockerfile.analytics-service -t cloudscale/analytics-service:latest .
```

### Deploy

```bash
# Create namespace
kubectl apply -f kubernetes/manifests/namespace.yaml

# Deploy secrets and configmaps
kubectl apply -f kubernetes/manifests/auth-service/
kubectl apply -f kubernetes/manifests/order-service/
kubectl apply -f kubernetes/manifests/payment-service/
kubectl apply -f kubernetes/manifests/analytics-service/

# Or use Helm
for chart in auth-chart order-chart payment-chart analytics-chart; do
  helm upgrade --install ${chart} helm/${chart}/ -n cloudscale
done

# Enable nginx ingress on Minikube
minikube addons enable ingress
kubectl apply -f kubernetes/manifests/ingress.yaml

# Check pods
kubectl get pods -n cloudscale

# Access services
minikube service list -n cloudscale
kubectl port-forward svc/auth-service 3001:80 -n cloudscale
```

### Teardown

```bash
minikube delete
```

## Method 4: CI/CD with GitHub Actions (Free)

```bash
# Copy the workflow to your repo root
mkdir -p .github/workflows
cp ci-cd/.github/workflows/ci-cd.yaml .github/workflows/

# Push to GitHub – pipeline runs automatically
git add . && git commit -m "Add CloudScale platform" && git push
```

The pipeline (all free):
1. Lints code with ESLint
2. Lints Dockerfiles with Hadolint
3. Runs unit tests with PostgreSQL service container
4. Builds Docker images (verification only, no push)
5. Validates Terraform configuration

## Verification Checklist

- [ ] `docker-compose up -d` starts all containers
- [ ] All 4 services return 200 on `/health/live`
- [ ] User registration and login work
- [ ] Orders can be created with JWT token
- [ ] Analytics events are ingested
- [ ] Prometheus shows targets at http://localhost:9090/targets
- [ ] Grafana dashboard loads at http://localhost:3000
- [ ] OpenSearch Dashboards loads at http://localhost:5601
- [ ] LocalStack health returns OK at http://localhost:4566/_localstack/health
- [ ] `terraform apply` succeeds against LocalStack
- [ ] Minikube pods reach Running state (if testing K8s)

## Troubleshooting

### Containers not starting
```bash
docker-compose logs auth-service
docker-compose logs postgres
```

### Port already in use
```bash
# Find what's using the port
netstat -ano | findstr :3001
# Kill the process or change the port in docker-compose.yml
```

### LocalStack not ready
```bash
# Wait longer or check logs
docker-compose logs localstack
curl http://localhost:4566/_localstack/health
```

### Minikube out of memory
```bash
minikube stop
minikube start --memory=6144 --cpus=4
```

### Reset everything
```bash
cd docker
docker-compose down -v
docker system prune -f
docker-compose up -d
```
