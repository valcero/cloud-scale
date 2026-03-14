# CloudScale – Production-Grade AWS DevOps Platform

A fully automated cloud-native platform demonstrating microservices on Kubernetes, Infrastructure as Code with Terraform, CI/CD pipelines, GitOps, observability, and data pipelines.

**Runs 100% locally for free** using Docker Compose, LocalStack (AWS emulator), and Minikube.

## Architecture

```
Developer pushes code → GitHub
        ↓
  GitHub Actions CI Pipeline (free tier)
        ↓
  Lint → Test → Build Docker Images
        ↓
  Kubernetes (Minikube local) ← Helm deploys microservices
        ↓
  Observability: Prometheus + Grafana (metrics), FluentBit → OpenSearch (logs)
        ↓
  Data Pipeline: App events → Kinesis (LocalStack) → Lambda → S3 (LocalStack)
```

## Services

| Service           | Port | Description                       |
|-------------------|------|-----------------------------------|
| auth-service      | 3001 | JWT authentication & user management |
| order-service     | 3002 | Order lifecycle management        |
| payment-service   | 3003 | Payment processing                |
| analytics-service | 3004 | Event ingestion & analytics       |

## Quick Start (One Command)

### Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (free)
- [Terraform](https://developer.hashicorp.com/terraform/downloads) (free)

### Windows (PowerShell)

```powershell
.\scripts\start-local.ps1
```

### Linux / macOS

```bash
chmod +x scripts/start-local.sh
./scripts/start-local.sh
```

### What starts up (all free):

| Service | URL | Credentials |
|---------|-----|-------------|
| Auth Service | http://localhost:3001 | - |
| Order Service | http://localhost:3002 | - |
| Payment Service | http://localhost:3003 | - |
| Analytics Service | http://localhost:3004 | - |
| Prometheus | http://localhost:9090 | - |
| Grafana | http://localhost:3000 | admin / admin |
| OpenSearch Dashboards | http://localhost:5601 | - |
| LocalStack (AWS) | http://localhost:4566 | - |
| PostgreSQL | localhost:5432 | cloudscale_admin / localdev123 |

### Try It

```bash
# Register a user
curl -X POST http://localhost:3001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@test.com","password":"password123"}'

# Login (copy the token from the response)
curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@test.com","password":"password123"}'

# Create an order (replace TOKEN)
curl -X POST http://localhost:3002/api/orders \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TOKEN" \
  -d '{"items":[{"name":"Widget","qty":2}],"total":29.99}'

# Send an analytics event (replace TOKEN)
curl -X POST http://localhost:3004/api/events \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TOKEN" \
  -d '{"event_type":"page_view","source":"web","payload":{"page":"/home"}}'

# Check Prometheus metrics
curl http://localhost:3001/metrics
```

### Stop Everything

```powershell
.\scripts\stop-local.ps1
# or
cd docker && docker-compose down
```

## Project Structure

```
cloud-scale/
├── services/                    # Microservice source code (Node.js)
│   ├── auth-service/            #   JWT auth, registration, login
│   ├── order-service/           #   Order CRUD, status management
│   ├── payment-service/         #   Payment processing
│   └── analytics-service/       #   Event ingestion, Kinesis streaming
├── docker/                      # Dockerfiles + docker-compose (local stack)
├── kubernetes/manifests/        # K8s manifests (for Minikube)
├── helm/                        # Helm charts per service
├── terraform/                   # IaC modules (runs on LocalStack)
│   ├── vpc/                     # VPC, subnets, NAT, IGW (reference)
│   ├── eks/                     # EKS cluster + node groups (reference)
│   ├── rds/                     # RDS PostgreSQL (reference)
│   ├── s3/                      # S3 buckets ← runs locally
│   ├── kinesis/                 # Kinesis stream ← runs locally
│   └── ecr/                     # ECR repositories (reference)
├── ci-cd/                       # CI/CD pipelines (free GitHub Actions)
│   ├── .github/workflows/       #   Lint, test, build (no AWS needed)
│   └── argocd/                  #   ArgoCD manifests (reference)
├── observability/               # Monitoring & logging (all free)
│   ├── prometheus/              #   Metrics collection
│   ├── grafana/                 #   Dashboards
│   ├── fluentbit/               #   Log shipping
│   └── opensearch/              #   Log storage & search
├── data-pipeline/               # Data engineering
│   ├── lambda/                  #   Event processor (Python)
│   ├── kinesis/                 #   Stream config
│   └── athena/                  #   SQL analytics queries
├── scripts/                     # Startup & test scripts
└── docs/                        # Architecture & deployment docs
```

## Technology Stack

| Layer | Technology | Cost |
|-------|-----------|------|
| Microservices | Node.js + Express | Free |
| Database | PostgreSQL (Docker) | Free |
| AWS Emulation | LocalStack | Free |
| Container Runtime | Docker Desktop | Free |
| Local Kubernetes | Minikube | Free |
| IaC | Terraform → LocalStack | Free |
| CI/CD | GitHub Actions (free tier) | Free |
| Metrics | Prometheus + Grafana | Free |
| Logs | FluentBit + OpenSearch | Free |
| Data Pipeline | Kinesis + Lambda (LocalStack) | Free |

## Kubernetes (Minikube)

For the full K8s experience locally:

```bash
# Install Minikube (free)
# Windows: choco install minikube
# Mac: brew install minikube
# Linux: curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

minikube start --memory=4096 --cpus=2

# Build images inside Minikube
eval $(minikube docker-env)
docker build -f docker/Dockerfile.auth-service -t cloudscale/auth-service:latest .
docker build -f docker/Dockerfile.order-service -t cloudscale/order-service:latest .
docker build -f docker/Dockerfile.payment-service -t cloudscale/payment-service:latest .
docker build -f docker/Dockerfile.analytics-service -t cloudscale/analytics-service:latest .

# Deploy with Helm
kubectl apply -f kubernetes/manifests/namespace.yaml
for chart in auth-chart order-chart payment-chart analytics-chart; do
  helm upgrade --install ${chart} helm/${chart}/ -n cloudscale
done

# Access services
minikube service auth-service -n cloudscale
```

## CI/CD Pipeline (Free)

Push to GitHub and the pipeline runs automatically:

1. **Lint** – ESLint (code) + Hadolint (Dockerfiles)
2. **Test** – Jest with PostgreSQL service container
3. **Build** – Docker image build verification
4. **Validate** – Terraform format & validate

No AWS credentials or paid services needed.

## License

MIT
