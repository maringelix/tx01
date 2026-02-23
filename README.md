# tx01 — AWS Infrastructure (Terraform + EKS)

[![Terraform](https://img.shields.io/badge/Terraform-1.9+-purple.svg)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-Cloud-orange.svg)](https://aws.amazon.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Production-grade AWS infrastructure provisioned with Terraform. Implements EKS, RDS (PostgreSQL), EC2, VPC, WAF, ALB, and ECR with full observability via Prometheus/Grafana.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                          WAF v2                             │
├─────────────────────────────────────────────────────────────┤
│                Application Load Balancer                    │
├─────────────────────────────────────────────────────────────┤
│                       EKS Cluster                           │
│  ┌──────────┐  ┌──────────┐  ┌───────────┐  ┌───────────┐ │
│  │   App    │  │  nginx   │  │Prometheus │  │  Grafana  │ │
│  │  Pods    │  │ Ingress  │  │ Metrics   │  │ Dashboards│ │
│  └──────────┘  └──────────┘  └───────────┘  └───────────┘ │
├─────────────────────────────────────────────────────────────┤
│     RDS PostgreSQL  ·  ECR  ·  EC2 (bastion)               │
│                    VPC (3 AZs)                              │
└─────────────────────────────────────────────────────────────┘
```

## Terraform Modules

| Module | Description |
|--------|-------------|
| `vpc` | VPC with public/private subnets across 3 AZs |
| `eks` | EKS cluster with managed node groups |
| `rds` | RDS PostgreSQL with automated backups |
| `ec2` | Bastion host for cluster access |
| `alb` | Application Load Balancer with health checks |
| `waf` | AWS WAF v2 with rate limiting and geo-blocking |
| `ecr` | Elastic Container Registry for images |
| `security_groups` | Least-privilege security group rules |

## Kubernetes Components

```
k8s/
├── policies/           # Network policies, pod security
└── observability/      # Prometheus + Grafana stack
```

## Prerequisites

- Terraform >= 1.9
- AWS CLI v2 configured (`aws configure`)
- `kubectl` and `eksctl`

## Quick Start

```bash
# Initialize Terraform
cd terraform/environments/prd
terraform init

# Plan and apply
terraform plan -out=tfplan
terraform apply tfplan

# Configure kubectl for EKS
aws eks update-kubeconfig \
  --region us-east-1 \
  --name <CLUSTER_NAME>
```

## Environments

| Environment | Directory | Purpose |
|-------------|-----------|---------|
| Production | `terraform/environments/prd/` | Live infrastructure |
| Staging | `terraform/environments/stg/` | Pre-production validation |

## CI/CD Workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `docker-build.yml` | Manual dispatch | Build and push to ECR |
| `tests.yml` | Push/PR to main | Run test suite |

## Security Features

- **WAF v2** — Rate limiting, SQL injection protection, geo-blocking
- **Private Subnets** — EKS nodes and RDS in private subnets
- **Security Groups** — SSH restricted to authorized CIDRs only
- **RDS Encryption** — Encryption at rest and in transit
- **ECR Scanning** — Vulnerability scanning on image push
- **Network Policies** — Namespace-level pod isolation

## License

MIT
