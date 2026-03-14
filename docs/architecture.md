# CloudScale Architecture

## System Overview

CloudScale is a production-grade AWS DevOps platform consisting of four microservices deployed on Kubernetes (EKS), with full observability, CI/CD automation, and a real-time data pipeline.

## Architecture Diagram

```
┌──────────────┐     ┌──────────────────────────────────────────────────────┐
│   Developer  │     │                    GitHub                            │
│   pushes     │────▶│  ┌─────────────────────────────────────────────┐     │
│   code       │     │  │           GitHub Actions CI/CD              │     │
└──────────────┘     │  │  Lint → Test → Build → Push → Deploy       │     │
                     │  └──────────────────┬──────────────────────────┘     │
                     └─────────────────────┼───────────────────────────────┘
                                           │
                     ┌─────────────────────▼───────────────────────────────┐
                     │                Amazon ECR                           │
                     │  auth-service │ order-service │ payment │ analytics │
                     └─────────────────────┬───────────────────────────────┘
                                           │
          ┌────────────────────────────────▼──────────────────────────────┐
          │                     AWS EKS Cluster                           │
          │                                                               │
          │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐        │
          │  │ auth-service │  │ order-service │  │payment-service│       │
          │  │  (port 3001) │  │  (port 3002)  │  │  (port 3003) │       │
          │  └──────┬───────┘  └──────┬────────┘  └──────┬───────┘       │
          │         │                 │                    │               │
          │  ┌──────▼─────────────────▼────────────────────▼──────┐       │
          │  │              AWS ALB Ingress Controller             │       │
          │  └────────────────────────────────────────────────────┘       │
          │                                                               │
          │  ┌──────────────────┐                                         │
          │  │analytics-service │──────┐                                  │
          │  │  (port 3004)     │      │                                  │
          │  └──────────────────┘      │                                  │
          │                            │                                  │
          │  ┌─────────────────────────▼──────────────────────────┐       │
          │  │            Observability Stack                      │       │
          │  │  Prometheus │ Grafana │ FluentBit │ OpenSearch      │       │
          │  └────────────────────────────────────────────────────┘       │
          └───────────────────────────────────────────────────────────────┘
                                           │
          ┌────────────────────────────────▼──────────────────────────────┐
          │                    Data Pipeline                              │
          │                                                               │
          │  App Events ──▶ Kinesis Stream ──▶ Lambda ──▶ S3 Data Lake   │
          │                                                    │          │
          │                                              Athena / Redshift│
          └───────────────────────────────────────────────────────────────┘
                                           │
          ┌────────────────────────────────▼──────────────────────────────┐
          │                    Data Layer                                  │
          │  RDS Aurora PostgreSQL (Multi-AZ, Encrypted)                  │
          │  Tables: users │ orders │ transactions │ events               │
          └───────────────────────────────────────────────────────────────┘
```

## Network Architecture

### VPC Design (10.0.0.0/16)

| Subnet Type | CIDR Range | AZ | Purpose |
|-------------|------------|-----|---------|
| Public-1 | 10.0.0.0/20 | us-east-1a | ALB, NAT Gateway |
| Public-2 | 10.0.16.0/20 | us-east-1b | ALB, NAT Gateway |
| Public-3 | 10.0.32.0/20 | us-east-1c | ALB, NAT Gateway |
| Private-1 | 10.0.48.0/20 | us-east-1a | EKS nodes, RDS |
| Private-2 | 10.0.64.0/20 | us-east-1b | EKS nodes, RDS |
| Private-3 | 10.0.80.0/20 | us-east-1c | EKS nodes, RDS |

### Security Groups

- **EKS Cluster SG**: Port 443 inbound (API server)
- **EKS Node SG**: Inter-node communication, kubelet
- **RDS SG**: Port 5432 from VPC CIDR only
- **ALB SG**: Ports 80/443 from 0.0.0.0/0

### Network ACLs

- **Public NACL**: Allow all inbound/outbound
- **Private NACL**: Allow VPC CIDR inbound, ephemeral ports from 0.0.0.0/0

## Microservices

### Auth Service (port 3001)
- JWT-based authentication
- User registration and login
- Token verification endpoint
- Password hashing with bcrypt (12 rounds)

### Order Service (port 3002)
- CRUD operations for orders
- Status lifecycle management
- JWT-authenticated endpoints

### Payment Service (port 3003)
- Payment processing simulation
- Transaction recording
- Order-payment linking

### Analytics Service (port 3004)
- Event ingestion (single + batch)
- Kinesis integration for real-time streaming
- Aggregated statistics API

## Database Schema

```sql
-- Users table (auth-service)
users: id, email, password_hash, role, created_at, updated_at

-- Orders table (order-service)
orders: id (UUID), user_id, items (JSONB), total, status, created_at, updated_at

-- Transactions table (payment-service)
transactions: id (UUID), order_id, user_id, amount, currency, status, payment_method, created_at, updated_at

-- Events table (analytics-service)
events: id (UUID), event_type, source, user_id, payload (JSONB), created_at
```

## Data Pipeline

```
Microservices → Kinesis Data Stream (2 shards, 72h retention)
                        │
                        ▼
              Lambda Event Processor
              (batch size: 100, 10x parallelization)
                        │
                        ▼
              S3 Data Lake (partitioned by event_type/year/month/day/hour)
                        │
                    ┌───┴───┐
                    ▼       ▼
                Athena   Redshift
              (ad-hoc)  (warehouse)
```

## Observability

### Metrics Pipeline
- **Collection**: prom-client in each service exposes /metrics
- **Scraping**: Prometheus scrapes all pods with `prometheus.io/scrape: "true"`
- **Visualization**: Grafana dashboards (auto-provisioned)
- **Alerting**: Prometheus alerting rules for SLOs

### Logging Pipeline
- **Collection**: FluentBit DaemonSet tails container logs
- **Processing**: Kubernetes metadata enrichment
- **Storage**: OpenSearch cluster (3 nodes, 50GB each)
- **Visualization**: OpenSearch Dashboards

### Key Alerts
| Alert | Condition | Severity |
|-------|-----------|----------|
| ServiceDown | up == 0 for 1m | Critical |
| HighCPUUsage | CPU > 80% for 5m | Warning |
| HighErrorRate | 5xx > 5% for 5m | Critical |
| HighLatency | P99 > 2s for 5m | Warning |
| PodCrashLooping | Restarts in 15m | Critical |

## Scaling

- **HPA**: CPU/Memory-based autoscaling per service
- **Node Group**: 2-10 nodes (t3.large), ON_DEMAND
- **Database**: Aurora PostgreSQL with read replicas
- **Kinesis**: 2 shards (expandable)
