# TX01 - Infraestrutura AWS com Terraform, EKS e CI/CD

Infraestrutura profissional de DevOps com opções de deployment em **EC2** ou **EKS (Kubernetes)**, incluindo Docker, Nginx, ALB, RDS PostgreSQL, WAF, ECR e CI/CD automatizado via GitHub Actions.

## 📋 Arquitetura

### Arquitetura Híbrida (EC2 + EKS)

```
                          ┌─────────────────┐
                          │       WAF       │
                          └────────┬────────┘
                                   │
                          ┌────────▼────────┐
                          │       ALB       │
                          │  (Compartilhado)│
                          └────┬──────┬─────┘
                               │      │
                ┌──────────────┘      └──────────────┐
                │                                     │
        ┌───────▼────────┐                   ┌───────▼────────┐
        │  Target Group  │                   │  Target Group  │
        │      EC2       │                   │      EKS       │
        └───────┬────────┘                   └───────┬────────┘
                │                                     │
        ┌───────▼────────┐                   ┌───────▼────────┐
        │  2x EC2 Instances│                 │  EKS Cluster   │
        │  + Docker       │                  │  + Kubernetes  │
        └───────┬────────┘                   │  + HPA (2-10)  │
                │                             └───────┬────────┘
                └─────────────┬───────────────────────┘
                              │
                     ┌────────▼────────┐
                     │  RDS PostgreSQL │
                     │  (Compartilhado)│
                     └────────┬────────┘
                              │
                     ┌────────▼────────┐
                     │ Secrets Manager │
                     │  + ECR Registry │
                     └─────────────────┘
```

## 🚀 Tecnologias

- **Terraform**: Infrastructure as Code
- **AWS**: VPC, EC2, EKS, ALB, WAF, RDS, ECR, Secrets Manager
- **Kubernetes**: EKS com auto-scaling (HPA)
- **Docker**: Nginx + Node.js containerizado
- **PostgreSQL**: RDS com SSL/TLS
- **GitHub Actions**: CI/CD Pipeline completo
- **CloudWatch**: Monitoramento e logs

## ✨ Novidades - Migração EKS

Este projeto agora suporta **deployment híbrido**:
- 🐳 **EC2 Mode**: 2x EC2 t2.micro com Docker (~$82/mês)
- ☸️ **EKS Mode**: Kubernetes cluster gerenciado (~$172/mês)
- 🔄 **Both Mode**: Ambos ativos simultaneamente para testes

### Vantagens do EKS

| Recurso | EC2 | EKS |
|---------|-----|-----|
| Auto-scaling | ❌ | ✅ (HPA: 2-10 pods) |
| Zero-downtime deploys | ⚠️ Manual | ✅ Automático |
| Health checks | ⚠️ ALB apenas | ✅ ALB + K8s probes |
| Resource limits | ❌ | ✅ CPU/Memory por pod |
| Self-healing | ❌ | ✅ Restart automático |
| Rollback | ⚠️ Manual | ✅ 1 comando |
| Gerenciamento | 🔧 SSH manual | 🎮 kubectl/API |

📖 **Guia completo**: [EKS_MIGRATION.md](EKS_MIGRATION.md)

## 📁 Estrutura do Projeto

```
tx01/
├── terraform/
│   ├── stg/                    # Configuração Staging
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars
│   ├── prd/                    # Configuração Production
│   ├── modules/                # Módulos reutilizáveis
│   │   ├── vpc.tf
│   │   ├── security_groups.tf
│   │   ├── ec2.tf
│   │   ├── alb.tf
│   │   ├── rds.tf              # ⭐ PostgreSQL RDS
│   │   ├── eks.tf              # ⭐ EKS Cluster + Nodes
│   │   ├── ecr.tf
│   │   └── waf.tf
│   ├── policies/
│   │   └── alb-controller-policy.json
│   └── bootstrap/              # Estado remoto S3 + DynamoDB
├── k8s/                        # ⭐ Kubernetes Manifests
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── hpa.yaml
│   ├── serviceaccount.yaml
│   └── secret.yaml
├── docker/
│   ├── Dockerfile
│   ├── nginx.conf
│   └── default.conf
├── .github/workflows/
│   ├── terraform-deploy.yml
│   ├── deploy-dx01.yml
│   ├── manage-environment.yml
│   ├── eks-deploy.yml          # ⭐ EKS provision/deploy/destroy
│   └── switch-environment.yml  # ⭐ Alternar EC2/EKS/Both
├── EKS_MIGRATION.md           # ⭐ Guia de migração EKS
├── eks-helper.sh              # ⭐ Script auxiliar kubectl
└── README.md
```

## 🚀 Início Rápido

### Opção 1: Deploy EC2 (Tradicional)

```bash
# 1. Clonar
git clone https://github.com/maringelix/tx01.git
cd tx01

# 2. Configurar AWS
aws configure

# 3. Deploy Staging via GitHub Actions
# Ir em Actions → Terraform Deploy
# Selecionar: environment=stg, action=apply
```

### Opção 2: Deploy EKS (Kubernetes)

```bash
# 1. Provisionar cluster EKS
# GitHub Actions → EKS Deploy
# Selecionar: environment=stg, action=provision
# ⏳ Aguardar 15-20 minutos

# 2. Deploy da aplicação
# GitHub Actions → EKS Deploy
# Selecionar: environment=stg, action=deploy
# ⏳ Aguardar 3-5 minutos

# 3. Verificar
./eks-helper.sh stg status
```

### Opção 3: Alternar entre EC2 e EKS

```bash
# Via GitHub Actions → Switch Environment

# Apenas EC2 (~$82/mês)
Mode: ec2

# Apenas EKS (~$172/mês)
Mode: eks

# Ambos ativos (~$188/mês)
Mode: both
```

### 4. Acessar Aplicação
```bash
# Obter DNS do ALB
terraform output alb_dns_name

# Acessar no navegador: http://seu-alb-dns
```

### 5. Deploy Production
```bash
cd ../prd
terraform init
terraform apply
```

## 🔐 Configurar GitHub Secrets

Para CI/CD automático, adicione em `Settings > Secrets and variables > Actions`:

- `AWS_ACCESS_KEY_ID` - Sua chave de acesso AWS
- `AWS_SECRET_ACCESS_KEY` - Sua chave secreta AWS

Veja [GITHUB_SECRETS.md](./GITHUB_SECRETS.md) para instruções detalhadas.

## 📚 Documentação

- [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) - Guia passo-a-passo
- [GITHUB_SECRETS.md](./GITHUB_SECRETS.md) - Setup CI/CD

## 🌐 Acessar a Aplicação

```bash
# Após deploy, obter DNS do ALB
cd terraform/stg
ALB_DNS=$(terraform output -raw alb_dns_name)
echo "Acesse: http://$ALB_DNS"

# Verificar health
curl http://$ALB_DNS/health
```

## 🐳 Atualizar Imagem Docker

```bash
# 1. Editar Dockerfile ou configuração
vim docker/Dockerfile

# 2. Commit e push
git add docker/Dockerfile
git commit -m "update: nginx config"
git push origin main

# 3. GitHub Actions automaticamente:
#    - Constrói nova imagem
#    - Escaneia vulnerabilidades
#    - Faz push para ECR
```

## 📊 Monitoramento

```bash
# Ver logs do EC2
aws logs tail /aws/ec2/tx01-stg --follow

# Ver health dos targets
aws elbv2 describe-target-health \
  --target-group-arn <seu-tg-arn>

# Ver métricas do CloudWatch
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name TargetResponseTime \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 300 \
  --statistics Average
```

## 🧹 Cleanup (Destruir Infraestrutura)

```bash
# Staging
cd terraform/stg
terraform destroy

# Production
cd ../prd
terraform destroy
```

## 🔒 Recursos de Segurança

- ✅ WAF com rate limiting e proteção contra SQLi
- ✅ Security Groups restritivos
- ✅ ECR com image scanning
- ✅ CloudWatch logs encrypted
- ✅ IMDSv2 obrigatório nas EC2
- ✅ SSL/TLS ready (configure certificado ACM)

## 🤝 Contribuindo

1. Fork o projeto
2. Crie uma branch: `git checkout -b feature/meu-recurso`
3. Commit: `git commit -am 'Adiciona recurso'`
4. Push: `git push origin feature/meu-recurso`
5. Abra Pull Request

## 📄 Licença

MIT License

## 👤 Autor

- **GitHub**: @maringelix

---

**Criado com ❤️ usando Terraform e GitHub Actions**
