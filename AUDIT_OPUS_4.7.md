# AUDITORIA TX01 — Opus 4.7

**Data:** 2026-05-27
**Escopo:** AWS Terraform Infrastructure (EKS / RDS / WAF / ALB / EC2)
**Modo:** Read-only (security + qualidade + CI/CD + docs + IaC)

---

## Resumo Quantitativo

| Métrica | Valor |
|---------|-------|
| Arquivos auditados | 99 |
| Linhas Terraform (`terraform/**`) | ~4.200 |
| Workflows GitHub Actions | 20 |
| **P0 (Critical)** | 0 |
| **P1 (High)** | 3 |
| **P2 (Medium)** | 7 |
| **P3 (Low)** | 9 |
| **Total** | 19 |

Top 5 arquivos mais longos: `eks.tf` (~550L), `tf-deploy.yml` (~400L), `eks-deploy.yml` (~380L), `waf.tf` (~200L), `rds.tf` (~180L).

---

## P1 — High

| # | Categoria | Título | Arquivo | Descrição & Recomendação |
|---|-----------|--------|---------|--------------------------|
| 1 | Security / CI/CD | Long-lived AWS Keys em workflows | [.github/workflows/tf-deploy.yml](.github/workflows/tf-deploy.yml) | Todos os workflows usam `AWS_ACCESS_KEY_ID` + `AWS_SECRET_ACCESS_KEY` em secrets. Migrar para OIDC via `aws-actions/configure-aws-credentials@v4` com `role-to-assume`. |
| 2 | CI/CD | 20 workflows com mesma dependência de long-lived keys | [.github/workflows/eks-deploy.yml](.github/workflows/eks-deploy.yml#L38) | Criar IAM role `GitHubActionsRole` com trust policy OIDC e atualizar todos os `.yml` em paralelo. |
| 3 | Security | ALB sem Access Logs | [terraform/modules/alb.tf](terraform/modules/alb.tf) | Sem `access_logs`; acessos não auditáveis. Adicionar bucket S3 dedicado + `enable_logging = true`. |

---

## P2 — Medium

| # | Categoria | Título | Arquivo | Descrição & Recomendação |
|---|-----------|--------|---------|--------------------------|
| 1 | Security | `AWS_IAM_POLICY.json` excessivamente permissivo | [AWS_IAM_POLICY.json](AWS_IAM_POLICY.json) | `s3:*`, `dynamodb:*`, `ec2:*`, `iam:*` com `Resource:"*"`. Restringir a ARNs específicos (`tx01-terraform-state-*`, `tx01-*`). |
| 2 | Security | `AWS_IAM_POLICY_MINIMAL.json` também permissivo | [AWS_IAM_POLICY_MINIMAL.json](AWS_IAM_POLICY_MINIMAL.json) | Apesar do nome, ainda usa wildcards `*` em `s3:*`, `iam:*`. Refatorar com ações granulares + ARNs. |
| 3 | Quality | Backend Terraform inconsistente (comentado em `provider.tf` mas ativo em `prd/main.tf`) | [terraform/provider.tf](terraform/provider.tf#L13) / [terraform/prd/main.tf](terraform/prd/main.tf#L6) | Consolidar em `backend-config.hcl` + `terraform init -backend-config=...`. |
| 4 | CI/CD | `docker-build.yml` tem código morto | [.github/workflows/docker-build.yml](.github/workflows/docker-build.yml#L61) | Bloco `if: github.event_name == 'push'` nunca dispara (só `workflow_dispatch`). Remover ou adicionar gatilho `push`. |
| 5 | Quality | Provider version `~> 5.0` (range muito amplo) | [terraform/provider.tf](terraform/provider.tf#L6) | Pinnar em `5.75.0` (ou minor específico) para evitar breaking changes. |
| 6 | Docs | `SECURITY.md` faz afirmação vaga "no secrets in code" | [SECURITY.md](SECURITY.md#L14) | Documentar pre-commit + gitleaks; clarificar política sobre `.pub` vs `.pem`. |
| 7 | IaC | `AWS_IAM_POLICY_WITH_EKS.json` vazio (0 bytes) | [AWS_IAM_POLICY_WITH_EKS.json](AWS_IAM_POLICY_WITH_EKS.json) | Deletar ou preencher com policy IRSA mínima. |

---

## P3 — Low

| # | Categoria | Título | Arquivo | Descrição & Recomendação |
|---|-----------|--------|---------|--------------------------|
| 1 | Security | RDS/ECR usam AES256 (AWS-managed) em vez de CMK | [terraform/modules/rds.tf](terraform/modules/rds.tf#L109) | Criar `aws_kms_key` dedicada + alias e passar `kms_key_id`. |
| 2 | Security | ALB listener HTTP-only (sem HTTPS/ACM) | [terraform/modules/alb.tf](terraform/modules/alb.tf#L63) | Adicionar listener `443` com `certificate_arn` ACM e redirect 80→443. |
| 3 | Security | EC2 IAM policy com `Resource:"*"` em SSM/EC2 messages | [terraform/modules/ec2.tf](terraform/modules/ec2.tf#L107) | Restringir a região + account ID. |
| 4 | Quality | RDS `db.t4g.micro` em PRD | [terraform/prd/terraform.tfvars](terraform/prd/terraform.tfvars#L6) | Subir para `db.t4g.small`/`medium` em prd; aumentar `allocated_storage`. |
| 5 | IaC | EKS Launch Template sem IMDSv2 explícito | [terraform/modules/eks.tf](terraform/modules/eks.tf#L89) | Adicionar `metadata_options { http_tokens = "required" }`. |
| 6 | IaC | Add-on versions hardcoded (`v1.19.0-eksbuild.1`) | [terraform/modules/eks.tf](terraform/modules/eks.tf#L163) | Usar `null` (latest) ou agendar update mensal. |
| 7 | Docs | `IMPLEMENTATION_STATUS.txt` refere-se a DX01 (escopo cruzado) | [IMPLEMENTATION_STATUS.txt](IMPLEMENTATION_STATUS.txt#L20) | Separar nota cross-repo em seção dedicada. |
| 8 | IaC | Sem Kubernetes NetworkPolicy | [k8s/policies/](k8s/policies/) | Adicionar deny-all egress padrão + allowlist DNS/services. |
| 9 | Quality | `ssh_allowed_cidr` default `10.0.0.0/8` sem validation | [terraform/modules/variables.tf](terraform/modules/variables.tf#L133) | Adicionar `validation { condition = can(cidrhost(...)) }`. |

---

## Pontos Fortes

1. **Estrutura Terraform modular** clara (bootstrap, modules/, prd/, stg/) com tfvars por ambiente.
2. **RDS production-ready**: encryption, `deletion_protection` em prd, backup 7d, Secrets Manager, SGs restritivos.
3. **EKS com IRSA** correto (OIDC provider + assume_role_policy para EBS CSI/SAs).
4. **EC2 com IMDSv2 enforcement** (`http_tokens = "required"`), IAM instance profile fine-grained.
5. **CI/CD defensiva**: todos `workflow_dispatch`, destroy com confirmação `DESTROY`, concurrency groups, pre-commit + gitleaks, CODEOWNERS.
6. **Observability**: CloudWatch logs (api, audit, authenticator), WAF logging, EC2 agent, Prometheus/Grafana, Gatekeeper policies.
7. **Backup & DR**: workflow `configure-backup.yml`, S3 versioning no backend, RDS final snapshots, retention 30d/90d.

---

## Roadmap Prioritário (30 dias)

1. **OIDC migration (P1)** — Eliminar long-lived keys nos 20 workflows. Estimativa: 4h.
2. **ALB Access Logs + HTTPS (P1+P3)** — Bucket S3 + ACM + listener 443. Estimativa: 2h.
3. **IAM policy refinement (P2)** — Refatorar `AWS_IAM_POLICY.json` com ARNs específicos.
4. **Docs consolidation (P2)** — `SECURITY.md` + `IMPLEMENTATION_STATUS.txt`.

---

## Score de Segurança

| Componente | Nota |
|-----------|------|
| Secrets Management | 6/10 |
| Network Isolation | 8/10 |
| Encryption | 7/10 |
| IAM Least Privilege | 4/10 |
| CI/CD | 7/10 |
| Backup/Recovery | 9/10 |
| Compliance Posture | 6/10 |
| **Overall** | **6.7/10** |

Aceitável para staging; não pronto para produção sem mitigações P1.
