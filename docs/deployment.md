# CloudScale Deployment Guide

## Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| AWS CLI | >= 2.x | AWS resource management |
| Terraform | >= 1.5 | Infrastructure provisioning |
| kubectl | >= 1.28 | Kubernetes management |
| Helm | >= 3.12 | Application deployment |
| Docker | >= 24.0 | Container builds |
| Node.js | >= 20 LTS | Service development |

## Step 1: AWS Configuration

```bash
aws configure
# Set: AWS Access Key ID, Secret Access Key, Region (us-east-1), Output (json)
```

Ensure your IAM user/role has permissions for: EKS, ECR, VPC, RDS, S3, Kinesis, Lambda, CloudWatch, IAM.

## Step 2: Provision Infrastructure with Terraform

```bash
cd terraform

# Copy and configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Initialize and apply
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

This creates:
- VPC with public/private subnets across 3 AZs
- NAT Gateways, Internet Gateway, Route Tables
- EKS cluster with managed node group
- Aurora PostgreSQL cluster (2 instances)
- S3 buckets (data lake + Athena results)
- Kinesis data stream
- ECR repositories for all 4 services

## Step 3: Configure kubectl

```bash
aws eks update-kubeconfig --name cloudscale-eks-production --region us-east-1
kubectl get nodes  # verify connectivity
```

## Step 4: Build and Push Docker Images

```bash
# Login to ECR
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com

# Build and push all services
for svc in auth-service order-service payment-service analytics-service; do
  docker build -f docker/Dockerfile.${svc} -t ${svc}:latest .
  docker tag ${svc}:latest ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/cloudscale/${svc}:latest
  docker push ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/cloudscale/${svc}:latest
done
```

## Step 5: Deploy Kubernetes Namespace and Secrets

```bash
# Create namespace
kubectl apply -f kubernetes/manifests/namespace.yaml

# Update secrets with real values
# Edit each secret.yaml file with actual RDS endpoint, credentials, JWT secret
kubectl apply -f kubernetes/manifests/auth-service/secret.yaml
kubectl apply -f kubernetes/manifests/order-service/secret.yaml
kubectl apply -f kubernetes/manifests/payment-service/secret.yaml
kubectl apply -f kubernetes/manifests/analytics-service/secret.yaml
```

## Step 6: Deploy Services with Helm

```bash
# Update image repository in each chart's values.yaml
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

for chart in auth-chart order-chart payment-chart analytics-chart; do
  helm upgrade --install ${chart} helm/${chart}/ \
    --namespace cloudscale \
    --create-namespace \
    --set image.repository=${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/cloudscale/$(echo ${chart} | sed 's/-chart/-service/') \
    --wait --timeout 300s
done

# Verify deployments
kubectl get pods -n cloudscale
kubectl get svc -n cloudscale
```

## Step 7: Deploy Ingress Controller

```bash
# Install AWS Load Balancer Controller
helm repo add eks https://aws.github.io/eks-charts
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=cloudscale-eks-production

# Apply ingress
kubectl apply -f kubernetes/manifests/ingress.yaml
```

## Step 8: Deploy Observability Stack

```bash
# Deploy monitoring namespace, Prometheus, Grafana, FluentBit, OpenSearch
kubectl apply -f observability/prometheus/
kubectl apply -f observability/grafana/
kubectl apply -f observability/fluentbit/
kubectl apply -f observability/opensearch/

# Verify
kubectl get pods -n monitoring
```

Access points:
- **Grafana**: `kubectl get svc grafana -n monitoring` (LoadBalancer external IP, port 80)
- **OpenSearch Dashboards**: `kubectl get svc opensearch-dashboards -n monitoring` (port 5601)
- **Prometheus**: `kubectl port-forward svc/prometheus 9090:9090 -n monitoring`

## Step 9: Deploy Data Pipeline

```bash
# Deploy Lambda function
cd data-pipeline/lambda/event-processor
sam build
sam deploy --guided

# Create Athena tables
# Open AWS Athena Console → Query Editor → Run:
# Paste contents of data-pipeline/athena/create-tables.sql
```

## Step 10: Set Up ArgoCD (GitOps)

```bash
# Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Apply CloudScale project and applications
kubectl apply -f ci-cd/argocd/project.yaml
kubectl apply -f ci-cd/argocd/application.yaml

# Get ArgoCD admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Open https://localhost:8080
```

## Step 11: Configure CI/CD

1. Copy `.github/workflows/ci-cd.yaml` from `ci-cd/` to your repo root
2. Set GitHub repository secrets:
   - `AWS_ACCOUNT_ID`
   - `AWS_ROLE_ARN` (OIDC role for GitHub Actions)
3. Push to `main` branch to trigger the full pipeline

## Local Development

```bash
# Start all services locally with Docker Compose
cd docker
docker-compose up -d

# Services available at:
# Auth:      http://localhost:3001
# Orders:    http://localhost:3002
# Payments:  http://localhost:3003
# Analytics: http://localhost:3004
```

## Verification Checklist

- [ ] All Terraform resources created successfully
- [ ] kubectl can connect to EKS cluster
- [ ] All pods in `cloudscale` namespace are Running
- [ ] ALB is provisioned and accessible
- [ ] Health endpoints return 200 for all services
- [ ] Prometheus is scraping service metrics
- [ ] Grafana dashboard shows data
- [ ] FluentBit is shipping logs to OpenSearch
- [ ] Kinesis stream is receiving events
- [ ] Lambda is processing events to S3
- [ ] Athena can query the data lake
- [ ] ArgoCD is syncing applications
- [ ] GitHub Actions pipeline completes successfully

## Troubleshooting

### Pods not starting
```bash
kubectl describe pod <pod-name> -n cloudscale
kubectl logs <pod-name> -n cloudscale
```

### Database connectivity issues
```bash
kubectl exec -it <pod-name> -n cloudscale -- nc -zv <rds-endpoint> 5432
```

### ALB not provisioning
```bash
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
kubectl describe ingress cloudscale-ingress -n cloudscale
```

### Kinesis issues
```bash
aws kinesis describe-stream --stream-name cloudscale-events-production
aws kinesis get-shard-iterator --stream-name cloudscale-events-production \
  --shard-id shardId-000000000000 --shard-iterator-type LATEST
```
