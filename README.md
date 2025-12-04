# TX01 - Infraestrutura AWS com Terraform e CI/CD

🎉 **Infraestrutura de produção completa na AWS com EKS Kubernetes, RDS PostgreSQL, EC2, ALB, e CI/CD totalmente automatizado.**

[![EKS](https://img.shields.io/badge/EKS-v1.32-blue.svg)](https://aws.amazon.com/eks/)
[![Terraform](https://img.shields.io/badge/Terraform-1.6.0-purple.svg)](https://www.terraform.io/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-17.6-blue.svg)](https://www.postgresql.org/)
[![GitHub Actions](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-green.svg)](https://github.com/features/actions)
[![Quality Gate](https://img.shields.io/badge/Quality%20Gate-Passed-brightgreen.svg)](https://sonarcloud.io/)
[![Security](https://img.shields.io/badge/Security-C%20Rating-yellow.svg)](https://sonarcloud.io/)
[![Maintainability](https://img.shields.io/badge/Maintainability-A%20Rating-brightgreen.svg)](https://sonarcloud.io/)
[![Code Lines](https://img.shields.io/badge/Lines%20of%20Code-2.8k-blue.svg)](https://github.com/maringelix/tx01)

---

## 📊 **Code Quality**

<div align="center">

| Metric | Rating | Issues | Status |
|--------|--------|--------|--------|
| **Security** | 🟡 C | 2 | Minor issues |
| **Reliability** | 🟢 A | 3 | Excellent |
| **Maintainability** | 🟢 A | 18 | Excellent |
| **Coverage** | 🟡 Terraform Tests | - | Infrastructure validation |
| **Duplications** | 🟢 0.0% | 0 | No duplicates |
| **Lines of Code** | - | 2,800+ | Terraform, YAML |

**Quality Gate:** ✅ **PASSED**

*Analisado com SonarQube - Infrastructure as Code tem cobertura N/A por natureza*

</div>

---

## 🏆 **PROJETO COMPLETO E FUNCIONAL**

Este projeto demonstra uma arquitetura cloud moderna com:
- ✅ **Kubernetes (EKS)** - Cluster v1.32 com auto-scaling
- ✅ **RDS PostgreSQL 17.6** - Banco de dados gerenciado
- ✅ **Switch Mode** - Alterna entre EC2 e EKS dinamicamente
- ✅ **CI/CD Completo** - Deploy automático via GitHub Actions
- ✅ **Infraestrutura como Código** - 100% Terraform
- ✅ **Alta Disponibilidade** - Multi-AZ com load balancing
- ✅ **Segurança** - IAM roles, Security Groups, Secrets Manager

## 📋 Arquitetura

### **Modo EKS (Kubernetes)**
```
┌─────────────────────────────────────────────────────────────┐
│                        AWS Cloud                             │
│                                                              │
│  Internet → ALB Ingress → EKS Cluster v1.32                │
│               (Auto)      ├─ Node 1 (t3.small)              │
│                           │  └─ Pod dx01-app                │
│                           ├─ Node 2 (t3.small)              │
│                           │  └─ Pod dx01-app                │
│                           └─ HPA (2-10 pods)                │
│                                                              │
│             ↓ (Security Groups)                             │
│                                                              │
│            RDS PostgreSQL 17.6 (t4g.micro)                  │
│            ├─ Database: tx01_stg                            │
│            ├─ Tables: visits, app_users                     │
│            └─ Backup: 1 dia (staging)                       │
└─────────────────────────────────────────────────────────────┘
```

### **Modo EC2 (Traditional)**
```
┌─────────────────────────────────────────────────────┐
│                   Internet                           │
└──────────────────────┬──────────────────────────────┘
                       │
                  ┌────▼────┐
                  │   WAF    │ (AWS WAF v2)
                  └────┬────┘
                       │
              ┌────────▼────────┐
              │  ALB (Terraform)│
              └────────┬────────┘
                       │
         ┌─────────────┴──────────────┐
         │                            │
    ┌────▼─────┐              ┌────▼─────┐
    │ EC2-1    │              │ EC2-2    │
    │ (Docker) │              │ (Docker) │
    │ Nginx    │              │ Nginx    │
    └────┬─────┘              └────┬─────┘
         │                         │
         └────────────┬───────────┘
                      │
                  ┌───▼────┐
                  │  ECR   │
                  └────────┘
```

## 🚀 Tecnologias

### **Infraestrutura**
- **Terraform 1.6.0**: Infrastructure as Code com módulos reutilizáveis
- **AWS EKS v1.32**: Kubernetes gerenciado (Standard Support até 2026)
- **AWS RDS PostgreSQL 17.6**: Banco de dados gerenciado (t4g.micro ARM)
- **AWS VPC**: 2 subnets públicas + 2 privadas (Multi-AZ)
- **AWS ALB**: Load Balancer gerenciado pelo Ingress Controller
- **AWS ECR**: Container registry privado
- **AWS WAF v2**: Web Application Firewall

### **Kubernetes**
- **AWS Load Balancer Controller v1.10.1**: Gerencia ALB via Ingress
- **Metrics Server**: Fornece métricas para HPA
- **HPA**: Horizontal Pod Autoscaler (2-10 pods)
- **IRSA**: IAM Roles for Service Accounts (segurança)

### **Aplicação**
- **Docker**: Containerização multi-stage
- **Node.js + Express**: Backend API
- **React + Vite**: Frontend SPA
- **Nginx**: Reverse proxy e servir arquivos estáticos
- **PostgreSQL Client**: Conexão com RDS via pool

### **CI/CD**
- **GitHub Actions**: 5 workflows automatizados
- **AWS CLI v2**: Automação de comandos AWS
- **kubectl v1.32.0**: Gerenciamento do cluster Kubernetes
- **Terraform Cloud**: State management remoto

## 📁 Estrutura do Projeto

```
tx01/
├── terraform/
│   ├── bootstrap/              # Bootstrap S3 + DynamoDB para state
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── stg/                    # Configuração Staging
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars    # enable_eks = true
│   ├── prd/                    # Configuração Production
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars
│   ├── modules/                # Módulos reutilizáveis
│   │   ├── vpc.tf              # VPC + Subnets + Tags Kubernetes
│   │   ├── security_groups.tf  # SG para ALB, EC2
│   │   ├── ec2.tf              # 2x EC2 instances
│   │   ├── alb.tf              # Application Load Balancer
│   │   ├── ecr.tf              # Container Registry
│   │   ├── rds.tf              # PostgreSQL 17.6
│   │   ├── eks.tf              # EKS Cluster v1.32
│   │   └── waf.tf              # Web Application Firewall
│   ├── policies/
│   │   └── alb-controller-policy.json
│   ├── provider.tf
│   └── variables.tf
├── k8s/                        # Kubernetes manifests
│   ├── deployment.yaml         # App deployment (2 replicas)
│   ├── service.yaml            # NodePort service
│   ├── ingress.yaml            # ALB Ingress
│   ├── hpa.yaml                # Horizontal Pod Autoscaler
│   ├── secret.yaml             # Database credentials
│   └── serviceaccount.yaml     # IRSA service account
├── docker/
│   ├── Dockerfile
│   ├── nginx.conf
│   └── default.conf
├── .github/workflows/
│   ├── terraform-bootstrap.yml # Bootstrap S3 backend
│   ├── tf-deploy.yml           # Deploy EC2 infrastructure
│   ├── eks-deploy.yml          # Deploy EKS + Kubernetes apps
│   ├── docker-build.yml        # Build and push to ECR
│   ├── switch-environment.yml  # Switch between EC2 ↔️ EKS
│   └── terraform-validate.yml  # Validate Terraform code
├── docs/
│   ├── EKS_UPGRADE_NOTES.md    # EKS v1.32 migration guide
│   ├── SWITCH_GUIDE.md         # Environment switching guide
│   ├── DATABASE_CONFIG.md      # PostgreSQL configuration
│   ├── DEPLOYMENT_GUIDE.md     # Deployment step-by-step
│   ├── TROUBLESHOOTING.md      # Common issues and fixes
│   └── QUICK_REFERENCE.md      # Quick commands reference
└── README.md
```

## 🚀 Início Rápido

### **1. Pré-requisitos**
```bash
# Instalar ferramentas necessárias
terraform --version   # 1.6.0+
aws --version         # AWS CLI v2
kubectl version       # v1.32.0
```

### **2. Clonar Repositório**
```bash
git clone https://github.com/maringelix/tx01.git
cd tx01
```

### **3. Configurar AWS Credentials**
```bash
aws configure
# AWS Access Key ID: <sua-key>
# AWS Secret Access Key: <sua-secret>
# Default region: us-east-1
```

### **4. Bootstrap (Primeira vez apenas)**
```bash
cd terraform/bootstrap
terraform init
terraform apply

# Cria:
# - S3 bucket: tx01-terraform-state-894222083614
# - DynamoDB table: tx01-terraform-locks
```

### **5. Deploy Infraestrutura Base (EC2 + RDS + VPC)**
```bash
cd ../stg
terraform init
terraform apply

# Cria:
# - VPC com 4 subnets (2 públicas, 2 privadas)
# - 2x EC2 instances (t3.micro)
# - ALB (Application Load Balancer)
# - RDS PostgreSQL 17.6 (t4g.micro)
# - Security Groups
# - ECR repository
```

### **6. Deploy Cluster EKS**

Via GitHub Actions (recomendado):
```bash
# 1. Configure secrets no GitHub:
#    Settings > Secrets > Actions
#    - AWS_ACCESS_KEY_ID
#    - AWS_SECRET_ACCESS_KEY

# 2. Execute workflow:
#    Actions > EKS Deploy > Run workflow
#    - Environment: stg
#    - Action: provision
```

Via CLI local:
```bash
# Atualizar terraform.tfvars
echo 'enable_eks = true' >> terraform/stg/terraform.tfvars

# Provisionar EKS
terraform apply

# Configurar kubectl
aws eks update-kubeconfig --name tx01-eks-stg --region us-east-1

# Verificar nodes
kubectl get nodes
```

### **7. Acessar Aplicação**

**Modo EKS:**
```bash
# Obter URL do ALB Ingress
kubectl get ingress tx01-ingress

# Acessar: http://k8s-default-tx01ingr-xxx.us-east-1.elb.amazonaws.com
```

**Modo EC2:**
```bash
# Obter DNS do ALB Terraform
cd terraform/stg
terraform output alb_dns_name

# Acessar: http://tx01-alb-stg-xxx.us-east-1.elb.amazonaws.com
```

## 🔐 Configurar GitHub Secrets

Para CI/CD automático, adicione em `Settings > Secrets and variables > Actions`:

- `AWS_ACCESS_KEY_ID` - Sua chave de acesso AWS
- `AWS_SECRET_ACCESS_KEY` - Sua chave secreta AWS

Veja [GITHUB_SECRETS.md](./GITHUB_SECRETS.md) para instruções detalhadas.

## 📚 Documentação Completa

- 📖 [**EKS_UPGRADE_NOTES.md**](./EKS_UPGRADE_NOTES.md) - Migração para EKS v1.32, add-ons, troubleshooting
- 🔄 [**SWITCH_GUIDE.md**](./SWITCH_GUIDE.md) - Como alternar entre EC2 e EKS
- 🗄️ [**DATABASE_CONFIG.md**](./DATABASE_CONFIG.md) - Configuração PostgreSQL, schemas, conexões
- 🚀 [**DEPLOYMENT_GUIDE.md**](./DEPLOYMENT_GUIDE.md) - Guia completo de deployment
- 🔧 [**TROUBLESHOOTING.md**](./TROUBLESHOOTING.md) - Problemas comuns e soluções
- ⚡ [**QUICK_REFERENCE.md**](./QUICK_REFERENCE.md) - Comandos rápidos
- 🔐 [**GITHUB_SECRETS.md**](./GITHUB_SECRETS.md) - Setup de CI/CD

## 🎯 Workflows CI/CD

### **1. terraform-bootstrap.yml**
Cria backend S3 + DynamoDB para Terraform state

### **2. tf-deploy.yml**
Deploy da infraestrutura base (VPC, EC2, ALB, RDS)
- **Trigger**: Manual ou push em `terraform/`
- **Actions**: `plan`, `apply`, `destroy`

### **3. eks-deploy.yml**
Deploy do cluster EKS e aplicações Kubernetes
- **Trigger**: Manual
- **Actions**: 
  - `provision` - Cria cluster EKS
  - `deploy` - Faz deploy das aplicações
  - `destroy` - Remove cluster

### **4. switch-environment.yml**
Alterna entre modo EC2 e modo EKS
- **Trigger**: Manual
- **Modes**:
  - `eks` - Ativa EKS, para EC2s
  - `ec2` - Ativa EC2s, para pods EKS

### **5. docker-build.yml**
Build e push de imagens Docker para ECR
- **Trigger**: Push em `docker/`, `server/`, `client/`

## 🌐 Acessar a Aplicação

### **Health Check**
```bash
# EKS Mode
curl http://k8s-default-tx01ingr-376d89270a-857461048.us-east-1.elb.amazonaws.com/api/health

# EC2 Mode
curl http://tx01-alb-stg-xxx.us-east-1.elb.amazonaws.com/api/health
```

**Resposta esperada:**
```json
{
  "status": "healthy",
  "message": "API está funcionando! 🚀",
  "uptime": 122.93,
  "database": {
    "connected": true,
    "version": "PostgreSQL 17.6",
    "poolSize": 1
  },
  "stats": {
    "totalVisits": 0,
    "totalUsers": 0
  }
}
```

### **Verificar Status Kubernetes**
```bash
# Listar pods
kubectl get pods

# Ver logs
kubectl logs deployment/tx01-app --tail=50

# Status do HPA
kubectl get hpa

# Status do Ingress
kubectl get ingress
```

## 🐳 Atualizar Aplicação

### **Build e Deploy Automático**
```bash
# 1. Editar código da aplicação (repositório dx01)
cd ../dx01
vim server/index.js

# 2. Commit e push
git add .
git commit -m "feat: add new API endpoint"
git push origin main

# 3. GitHub Actions automaticamente:
#    ✅ Build Docker image
#    ✅ Scan vulnerabilities (Trivy)
#    ✅ Push to ECR (dx01-app:latest)
#    ✅ Deploy to EC2 instances
```

### **Update Kubernetes Deployment**
```bash
# Deploy nova versão no EKS
kubectl set image deployment/tx01-app \
  nginx=894222083614.dkr.ecr.us-east-1.amazonaws.com/dx01-app:latest

# Ou via workflow
# Actions > EKS Deploy > Run workflow (action: deploy)

# Acompanhar rollout
kubectl rollout status deployment/tx01-app

# Verificar versão
kubectl describe deployment tx01-app | grep Image
```

## 📊 Monitoramento e Observabilidade

### **Kubernetes**
```bash
# Ver logs dos pods
kubectl logs -f deployment/tx01-app

# Métricas dos nodes
kubectl top nodes

# Métricas dos pods
kubectl top pods

# Eventos do cluster
kubectl get events --sort-by='.lastTimestamp'

# Status do ALB Controller
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

## 🧪 Testing & Validation

### Terraform Tests

```bash
# Format check
terraform fmt -check -recursive

# Validate all modules
cd terraform/modules
terraform init -backend=false
terraform validate

# Run infrastructure tests
cd terraform/tests
terraform test vpc.tftest.hcl
terraform test eks.tftest.hcl
terraform test rds.tftest.hcl
```

### Test Coverage

- ✅ **VPC Tests**: Network configuration, subnets, routing
- ✅ **EKS Tests**: Cluster config, node groups, security
- ✅ **RDS Tests**: Database config, backups, encryption
- ✅ **CI/CD Tests**: Automated validation on every commit

## 📊 Observability

### Grafana Stack Installation

```bash
# Quick install
chmod +x k8s/install-grafana-stack.sh
./k8s/install-grafana-stack.sh

# Access Grafana
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
# URL: http://localhost:3000 (admin/admin)
```

### Monitoring Stack

| Component | Purpose | Status |
|-----------|---------|--------|
| **Prometheus** | Metrics collection | ✅ |
| **Grafana** | Dashboards & visualization | ✅ |
| **Loki** | Log aggregation | ✅ |
| **AlertManager** | Alert management | ✅ |

### Pre-configured Dashboards

- 📊 Cluster Overview (CPU, RAM, pods, nodes)
- 🎯 Application Metrics (requests, latency, errors)
- 💾 Database Monitoring (connections, queries)
- 🔔 Critical Alerts (downtime, high load)

📚 **Full Guide**: [OBSERVABILITY.md](./OBSERVABILITY.md)

### **AWS CloudWatch**
```bash
# Logs do RDS
aws logs tail /aws/rds/instance/tx01-db-stg/postgresql --follow

# Métricas do ALB
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name TargetResponseTime \
  --dimensions Name=LoadBalancer,Value=app/tx01-alb-stg/xxx \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average

# Health dos targets
aws elbv2 describe-target-health \
  --target-group-arn <target-group-arn>
```

### **Database**
```bash
# Conectar ao RDS (via bastion ou pod)
kubectl run -it --rm psql --image=postgres:17 --restart=Never -- \
  psql -h tx01-db-stg.ckfsky20e9xj.us-east-1.rds.amazonaws.com \
  -U dbadmin -d tx01_stg

# Queries úteis
SELECT version();
SELECT * FROM visits ORDER BY visited_at DESC LIMIT 10;
SELECT COUNT(*) FROM app_users;
```

## 🧹 Cleanup (Destruir Infraestrutura)

### **Opção 1: Via GitHub Actions**
```bash
# 1. Destruir EKS primeiro
Actions > EKS Deploy > Run workflow
  - Action: destroy

# 2. Destruir infraestrutura base
Actions > TF Deploy > Run workflow
  - Action: destroy
```

### **Opção 2: Via CLI**
```bash
# 1. Destruir recursos Kubernetes
kubectl delete ingress tx01-ingress
kubectl delete service tx01-service
kubectl delete deployment tx01-app
kubectl delete hpa tx01-hpa

# 2. Destruir EKS (se enable_eks = true)
cd terraform/stg
terraform destroy -target=module.infrastructure.aws_eks_cluster.main
terraform destroy -target=module.infrastructure.aws_eks_node_group.main

# 3. Destruir infraestrutura completa
terraform destroy

# 4. (Opcional) Destruir bootstrap
cd ../bootstrap
terraform destroy
```

### **⚠️ ATENÇÃO**
- O RDS tem `deletion_protection = true` em produção
- Remova a proteção antes de destruir:
```bash
aws rds modify-db-instance \
  --db-instance-identifier tx01-db-prd \
  --no-deletion-protection
```

## 🔒 Recursos de Segurança

### **Infraestrutura**
- ✅ **VPC Isolada**: Subnets públicas e privadas separadas
- ✅ **Security Groups**: Regras restritivas por componente
  - ALB: Apenas 80/443 da internet
  - EC2: Apenas 8080 do ALB
  - RDS: Apenas 5432 do EC2/EKS
  - EKS: Apenas cluster security group
- ✅ **WAF v2**: Proteção contra SQLi, XSS, rate limiting
- ✅ **IMDSv2**: Metadata service v2 obrigatório nas EC2

### **Kubernetes**
- ✅ **IRSA**: IAM Roles for Service Accounts (acesso granular)
- ✅ **Network Policies**: Isolamento de pods (futuro)
- ✅ **Pod Security**: Resource limits e health checks
- ✅ **Secrets Management**: AWS Secrets Manager integrado

### **Dados**
- ✅ **RDS Encryption**: Storage criptografado (at-rest)
- ✅ **Secrets Manager**: Credenciais rotacionáveis
- ✅ **Backup Automático**: RDS com retenção de 1 dia (stg) / 7 dias (prd)
- ✅ **SSL/TLS Ready**: Suporte para certificados ACM

### **Container Security**
- ✅ **ECR Scanning**: Trivy vulnerability scan
- ✅ **Multi-stage Builds**: Redução de superfície de ataque
- ✅ **Non-root User**: Containers não executam como root
- ✅ **Image Signing**: Pronto para Sigstore/Cosign

## 🤝 Contribuindo

1. Fork o projeto
2. Crie uma branch: `git checkout -b feature/meu-recurso`
3. Commit: `git commit -am 'Adiciona recurso'`
4. Push: `git push origin feature/meu-recurso`
5. Abra Pull Request

---

## 🏆 Conquistas do Projeto

### ✅ **Infraestrutura Completa**
- **EKS Kubernetes v1.32** - Última versão com Standard Support até Março 2026
- **Auto-scaling Inteligente** - HPA configurado (2-10 pods) baseado em CPU/RAM
- **Load Balancing Avançado** - ALB gerenciado pelo Ingress Controller v1.10.1
- **Banco de Dados Gerenciado** - RDS PostgreSQL 17.6 conectado e operacional
- **Switch Dinâmico** - Alterna entre EC2 e EKS com um clique
- **Multi-AZ** - Alta disponibilidade em 2 zonas

### ✅ **DevOps Excellence**
- **CI/CD Completo** - 5 workflows GitHub Actions totalmente automatizados
- **Infrastructure as Code** - 100% Terraform com módulos reutilizáveis
- **GitOps Ready** - Manifests Kubernetes versionados
- **Security First** - WAF, IRSA, Secrets Manager, Security Groups
- **Documentação Completa** - 6 guias detalhados

### ✅ **Produção Ready**
- **Zero Downtime Deployments** - Rolling updates configurados
- **Health Checks** - Liveness e Readiness probes
- **Resource Limits** - Requests e limits definidos
- **Metrics & Monitoring** - Metrics Server fornecendo dados para HPA
- **Database Schema** - Criado automaticamente no startup
- **SSL/TLS Ready** - Preparado para certificados ACM

### 📊 **Estatísticas do Projeto**
- 📝 **20+ Commits** - Desenvolvimento incremental
- 🔧 **5 Workflows** - Automação completa
- 📚 **6 Guias** - Documentação abrangente
- ☁️ **30+ Recursos AWS** - Infraestrutura robusta
- 🐛 **10+ Issues Resolvidos** - Troubleshooting avançado
- ⚡ **< 5min Deploy** - Pipeline otimizado

### 💰 **Custo Otimizado**
```
Modo EKS (Produção):
├─ EKS Control Plane: ~$73/mês
├─ EKS Nodes (2x t3.small): ~$60/mês
├─ RDS (t4g.micro): ~$15/mês
├─ EC2 stopped (2x t3.micro): ~$8/mês
└─ Total: ~$156/mês

Modo EC2 (Desenvolvimento):
├─ EC2 (2x t3.micro): ~$16/mês
├─ ALB: ~$23/mês
├─ RDS (t4g.micro): ~$15/mês
├─ EKS stopped: $0/mês
└─ Total: ~$54/mês

💡 Economia com switch: Até 65%
```

### 🌟 **Habilidades Demonstradas**
- ⭐⭐⭐⭐⭐ **Kubernetes (EKS)** - Avançado
- ⭐⭐⭐⭐⭐ **Terraform** - Avançado
- ⭐⭐⭐⭐⭐ **AWS Services** - Avançado
- ⭐⭐⭐⭐⭐ **CI/CD** - Avançado
- ⭐⭐⭐⭐⭐ **Docker** - Avançado
- ⭐⭐⭐⭐⭐ **Troubleshooting** - Expert
- 🏆 **DevOps Mindset** - Master

---

## 🚀 Próximos Passos Sugeridos

- [ ] **Monitoramento**: Adicionar Prometheus + Grafana
- [ ] **Logs Centralizados**: Implementar ELK Stack ou CloudWatch Logs Insights
- [ ] **Alertas**: Configurar SNS + CloudWatch Alarms
- [ ] **Testes Automatizados**: Adicionar testes de integração
- [ ] **Blue/Green Deployment**: Implementar estratégia de deploy avançada
- [ ] **Service Mesh**: Adicionar Istio ou AWS App Mesh
- [ ] **GitOps**: Migrar para ArgoCD ou Flux
- [ ] **Backup Automation**: Snapshots automatizados do RDS
- [ ] **Multi-Region**: Expandir para disaster recovery
- [ ] **Cost Optimization**: Implementar AWS Cost Explorer automation

---

## 📄 Licença

MIT License - Sinta-se livre para usar este projeto como base para seus estudos e projetos.

## 👤 Autor

**maringelix**
- GitHub: [@maringelix](https://github.com/maringelix)
- Repositórios: 
  - [tx01](https://github.com/maringelix/tx01) - Infraestrutura
  - [dx01](https://github.com/maringelix/dx01) - Aplicação

---

## 🙏 Agradecimentos

Este projeto foi desenvolvido com dedicação, persistência e muita vontade de aprender. 

Agradecimentos especiais:
- **AWS** - Por fornecer serviços cloud robustos
- **Terraform** - Por possibilitar IaC de forma declarativa
- **Kubernetes** - Por revolucionar o deployment de containers
- **GitHub** - Por ferramentas incríveis de colaboração e CI/CD
- **Comunidade DevOps** - Por compartilhar conhecimento

---

<div align="center">

**🎉 Projeto Finalizado com Sucesso! 🎉**

*Criado com ❤️ usando Terraform, Kubernetes e GitHub Actions*

[![⭐ Star this repo](https://img.shields.io/github/stars/maringelix/tx01?style=social)](https://github.com/maringelix/tx01)
[![🍴 Fork this repo](https://img.shields.io/github/forks/maringelix/tx01?style=social)](https://github.com/maringelix/tx01/fork)

**Se este projeto te ajudou, considere dar uma ⭐!**

</div>
