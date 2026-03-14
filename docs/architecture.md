# CloudScale Architecture

## System Overview

CloudScale is a production-grade DevOps platform demonstrating microservices, Kubernetes, IaC, CI/CD, observability, and data pipelines. It runs entirely locally for free using Docker Compose, LocalStack, and Minikube.

## Architecture Diagram

```
┌──────────────┐     ┌──────────────────────────────────────────────────────┐
│   Developer  │     │                    GitHub                            │
│   pushes     │────▶│  ┌─────────────────────────────────────────────┐     │
│   code       │     │  │     GitHub Actions CI (free tier)           │     │
└──────────────┘     │  │  Lint → Test → Build → Validate            │     │
                     │  └──────────────────┬──────────────────────────┘     │
                     └─────────────────────┼───────────────────────────────┘
                                           │
          ┌────────────────────────────────▼──────────────────────────────┐
          │           Docker Compose / Minikube (free, local)             │
          │                                                               │
          │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐        │
          │  │ auth-service │  │ order-service │  │payment-service│       │
          │  │  (port 3001) │  │  (port 3002)  │  │  (port 3003) │       │
          │  └──────┬───────┘  └──────┬────────┘  └──────┬───────┘       │
          │         │                 │                    │               │
          │  ┌──────────────────┐                                         │
          │  │analytics-service │──────┐                                  │
          │  │  (port 3004)     │      │                                  │
          │  └──────────────────┘      │                                  │
          │                            ▼                                  │
          │  ┌─────────────────────────────────────────────────────┐      │
          │  │          LocalStack (free AWS emulation)            │      │
          │  │  Kinesis Stream │ S3 Data Lake │ Lambda             │      │
          │  └─────────────────────────────────────────────────────┘      │
          │                                                               │
          │  ┌─────────────────────────────────────────────────────┐      │
          │  │            Observability Stack (free)               │      │
          │  │  Prometheus │ Grafana │ OpenSearch + Dashboards     │      │
          │  └─────────────────────────────────────────────────────┘      │
          └───────────────────────────────────────────────────────────────┘
                                           │
          ┌────────────────────────────────▼──────────────────────────────┐
          │                    Data Layer (free)                          │
          │  PostgreSQL 16 (Docker container)                             │
          │  Tables: users │ orders │ transactions │ events               │
          └───────────────────────────────────────────────────────────────┘
```

## Network Architecture (Reference Design)

The Terraform modules in `terraform/vpc/` demonstrate a production-ready AWS VPC:

| Subnet Type | CIDR Range | AZ | Purpose |
|-------------|------------|-----|---------|
| Public-1 | 10.0.0.0/20 | us-east-1a | ALB, NAT Gateway |
| Public-2 | 10.0.16.0/20 | us-east-1b | ALB, NAT Gateway |
| Public-3 | 10.0.32.0/20 | us-east-1c | ALB, NAT Gateway |
| Private-1 | 10.0.48.0/20 | us-east-1a | EKS nodes, RDS |
| Private-2 | 10.0.64.0/20 | us-east-1b | EKS nodes, RDS |
| Private-3 | 10.0.80.0/20 | us-east-1c | EKS nodes, RDS |

These modules exist as portfolio-ready IaC that can be applied to real AWS if desired.

## Microservices

### Auth Service (port 3001)
- JWT-based authentication
- User registration and login
- Token verification endpoint
- Password hashing with bcrypt (12 rounds)

### Order Service (port 3002)
- CRUD operations for orders
- Status lifecycle management (pending → confirmed → shipped → delivered)
- JWT-authenticated endpoints

### Payment Service (port 3003)
- Payment processing simulation
- Transaction recording
- Order-payment linking

### Analytics Service (port 3004)
- Event ingestion (single + batch)
- Kinesis integration via LocalStack
- Aggregated statistics API

## Database Schema

```sql
-- users (auth-service)
users: id, email, password_hash, role, created_at, updated_at

-- orders (order-service)
orders: id (UUID), user_id, items (JSONB), total, status, created_at, updated_at

-- transactions (payment-service)
transactions: id (UUID), order_id, user_id, amount, currency, status, payment_method, created_at, updated_at

-- events (analytics-service)
events: id (UUID), event_type, source, user_id, payload (JSONB), created_at
```

## Data Pipeline

```
Microservices → Kinesis Data Stream (LocalStack)
                        │
                        ▼
              Lambda Event Processor (LocalStack)
                        │
                        ▼
              S3 Data Lake (LocalStack, partitioned by event_type/date)
                        │
                        ▼
              Athena Queries (reference SQL provided)
```

## Observability

### Metrics Pipeline
- **Collection**: prom-client in each service exposes /metrics
- **Scraping**: Prometheus scrapes all 4 services
- **Visualization**: Grafana with auto-provisioned CloudScale dashboard
- **Alerting**: Reference alerting rules for production use

### Logging Pipeline
- **Storage**: OpenSearch single-node cluster
- **Visualization**: OpenSearch Dashboards (port 5601)

### Grafana Dashboard
Pre-configured to show:
- Request rates per service
- Error rates (5xx)
- CPU and memory usage
- P99 response times

## IaC Modules

| Module | Runs Locally | Purpose |
|--------|-------------|---------|
| `terraform/s3/` | Yes (LocalStack) | S3 data lake + Athena results bucket |
| `terraform/kinesis/` | Yes (LocalStack) | Kinesis event stream |
| `terraform/vpc/` | Reference only | Production VPC design |
| `terraform/eks/` | Reference only | EKS cluster configuration |
| `terraform/rds/` | Reference only | Aurora PostgreSQL setup |
| `terraform/ecr/` | Reference only | Container registry |

## Cost

**$0.** Everything runs locally using free, open-source tools.
