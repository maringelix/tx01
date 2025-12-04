# Security Policy

## 🔒 Security Overview

This project follows security best practices for Infrastructure as Code (IaC) and CI/CD workflows.

## ✅ What's Safe to Share Publicly

This repository is **safe to be public** because:

- ✅ **No credentials in code** - All secrets are managed externally
- ✅ **No .tfstate files** - State is stored remotely in S3 with encryption
- ✅ **No private keys** - SSH keys and certificates are excluded via `.gitignore`
- ✅ **No .env files** - Environment variables are never committed
- ✅ **GitHub Secrets** - AWS credentials stored securely in GitHub
- ✅ **AWS Secrets Manager** - Database credentials managed by AWS

## 🔐 Secrets Management

### GitHub Secrets (Required)
Configure these in `Settings > Secrets and variables > Actions`:

```
AWS_ACCESS_KEY_ID       - Your AWS access key
AWS_SECRET_ACCESS_KEY   - Your AWS secret key
GRAFANA_PASSWORD        - (Optional) Custom Grafana admin password
```

### AWS Secrets Manager
Database credentials are automatically managed:

```
tx01-db-stg-credentials  - Staging database credentials
tx01-db-prd-credentials  - Production database credentials
```

### Environment Variables
Local development uses `.env` files (never committed):

```bash
# .env.example provides template
# .env contains real values (gitignored)
```

## 🛡️ Security Features Implemented

### Infrastructure Security

- **VPC Isolation**: Public/private subnet separation
- **Security Groups**: Least privilege access rules
- **IAM Roles**: IRSA for EKS pods (no static credentials)
- **Encryption**: RDS encryption at rest, S3 encryption
- **State Locking**: DynamoDB for Terraform state locking
- **Versioning**: S3 versioning for state files

### Application Security

- **No Hardcoded Credentials**: All secrets externalized
- **CORS Configuration**: Configurable allowed origins
- **Health Checks**: Liveness and readiness probes
- **Resource Limits**: CPU/memory limits for containers
- **Secrets Injection**: Kubernetes secrets from AWS

### CI/CD Security

- **Branch Protection**: Main branch requires PR approval
- **Workflow Permissions**: Minimal required permissions
- **Secret Scanning**: GitHub Dependabot enabled
- **Drift Detection**: Terraform plan on every PR
- **Audit Trail**: All changes tracked in Git history

## 🚨 Reporting Security Issues

If you discover a security vulnerability, please:

1. **DO NOT** open a public issue
2. Email the maintainer privately
3. Provide detailed information about the vulnerability
4. Allow reasonable time for response and fix

## 📋 Security Checklist for Production

Before deploying to production, ensure:

- [ ] All GitHub Secrets are configured
- [ ] AWS IAM policies follow least privilege
- [ ] RDS has automated backups enabled
- [ ] Security Groups allow only required ports
- [ ] SSL/TLS certificates are configured (ACM)
- [ ] CloudWatch alarms are set up
- [ ] Grafana alerts are configured
- [ ] VPC Flow Logs are enabled
- [ ] AWS GuardDuty is enabled
- [ ] Multi-factor authentication (MFA) is enabled
- [ ] Regular security updates are scheduled

## 🔍 Security Audits

Regular security checks performed:

- ✅ No credentials in code
- ✅ No .tfstate files committed
- ✅ No private keys committed
- ✅ No .env files committed
- ✅ `.gitignore` properly configured
- ✅ GitHub Secrets properly configured
- ✅ AWS resources properly tagged
- ✅ Security Groups follow least privilege

## 📚 Additional Resources

- [AWS Security Best Practices](https://aws.amazon.com/security/best-practices/)
- [Terraform Security Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/part1.html)
- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/overview/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)

## 🏷️ Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| Latest  | :white_check_mark: |
| < 1.0   | :x:                |

## 📞 Contact

For security-related questions or concerns, please contact the repository owner through GitHub.

---

**Last Updated**: December 2025
**Security Review**: Passed ✅
