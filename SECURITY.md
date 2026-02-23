# Security Policy

## Reporting Vulnerabilities

If you discover a security issue, **do not** open a public issue. Contact the maintainer privately via GitHub.

## Security Posture

| Layer | Control |
|-------|---------|
| **Secrets** | No credentials in code; all via `terraform.tfvars` (gitignored) or GitHub Secrets |
| **SSH** | Restricted to `var.ssh_allowed_cidr` (no `0.0.0.0/0`) |
| **RDS** | Private subnet, password auth, encrypted storage |
| **IAM** | Least-privilege roles for EKS, EC2, and CI/CD |
| **Network** | VPC with public/private subnets, security groups, NACLs |
| **CI/CD** | Deploy workflows require manual dispatch (`workflow_dispatch`) |
| **IaC Scanning** | tfsec + Checkov in CI pipeline |

## Safe to Share Publicly

This repository contains **no secrets**. All sensitive values are externalized via variables and injected at deploy time.
