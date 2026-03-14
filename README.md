# CloudScale – Production-Grade AWS DevOps Platform

A fully automated cloud-native platform that deploys microservices on Kubernetes (EKS) using Terraform, CI/CD pipelines, GitOps (ArgoCD), observability, and data pipelines.

## Architecture

```
Developer pushes code → GitHub
        ↓
  GitHub Actions CI Pipeline
        ↓
  Build Docker Image → Push to Amazon ECR
        ↓
  Terraform deploys infrastructure
        ↓
  EKS Kubernetes Cluster ← Helm deploys microservices
        ↓
  ArgoCD GitOps continuous delivery
        ↓
  Observability: Prometheus + Grafana (metrics), FluentBit → OpenSearch (logs)
        ↓
  Data Pipeline: App events → Kinesis → Lambda → S3 → Athena/Redshift
```

## Services

| Service           | Port | Description                       |
|-------------------|------|-----------------------------------|
| auth-service      | 3001 | JWT authentication & user management |
| order-service     | 3002 | Order lifecycle management        |
| payment-service   | 3003 | Payment processing                |
| analytics-service | 3004 | Event ingestion & analytics       |

## Project Structure

```
cloud-scale/
├── services/                    # Microservice source code
│   ├── auth-service/
│   ├── order-service/
│   ├── payment-service/
│   └── analytics-service/
├── docker/                      # Dockerfiles
├── kubernetes/manifests/        # Raw K8s manifests
├── helm/                        # Helm charts per service
├── terraform/                   # IaC modules
│   ├── vpc/                     # VPC, subnets, NAT, IGW
│   ├── eks/                     # EKS cluster + node groups
│   ├── rds/                     # RDS PostgreSQL
│   ├── s3/                      # S3 buckets (data lake)
│   ├── kinesis/                 # Kinesis data stream
│   └── ecr/                     # ECR repositories
├── ci-cd/                       # CI/CD pipelines
│   ├── .github/workflows/       # GitHub Actions
│   └── argocd/                  # ArgoCD application manifests
├── observability/               # Monitoring & logging
│   ├── prometheus/
│   ├── grafana/
│   ├── fluentbit/
│   └── opensearch/
├── data-pipeline/               # Data engineering
│   ├── lambda/
│   ├── kinesis/
│   └── athena/
└── docs/
```

## Prerequisites

- AWS CLI v2 configured with appropriate IAM credentials
- Terraform >= 1.5
- kubectl >= 1.28
- Helm >= 3.12
- Docker >= 24.0
- Node.js >= 20 LTS

## Quick Start

### 1. Provision Infrastructure

```bash
cd terraform/vpc && terraform init && terraform apply
cd ../eks && terraform init && terraform apply
cd ../rds && terraform init && terraform apply
cd ../s3 && terraform init && terraform apply
cd ../kinesis && terraform init && terraform apply
cd ../ecr && terraform init && terraform apply
```

### 2. Configure kubectl

```bash
aws eks update-kubeconfig --name cloudscale-cluster --region us-east-1
```

### 3. Build & Push Docker Images

```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com

for svc in auth-service order-service payment-service analytics-service; do
  docker build -f docker/Dockerfile.${svc} -t ${svc}:latest services/${svc}/
  docker tag ${svc}:latest <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/${svc}:latest
  docker push <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/${svc}:latest
done
```

### 4. Deploy with Helm

```bash
for chart in auth-chart order-chart payment-chart analytics-chart; do
  helm upgrade --install ${chart} helm/${chart}/ -n cloudscale --create-namespace
done
```

### 5. Deploy Observability Stack

```bash
kubectl apply -f observability/prometheus/
kubectl apply -f observability/grafana/
kubectl apply -f observability/fluentbit/
kubectl apply -f observability/opensearch/
```

## CI/CD Pipeline Stages

1. **Lint** – ESLint + Hadolint
2. **Unit Test** – Jest test suites
3. **Build** – Docker image build
4. **Push** – Push to Amazon ECR
5. **Terraform** – Infrastructure apply
6. **Deploy** – Helm upgrade via ArgoCD

## License

MIT
