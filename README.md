# TX01 - Infraestrutura AWS com Terraform e CI/CD

🎉 **Infraestrutura de produção completa na AWS com EKS Kubernetes, RDS PostgreSQL, EC2, ALB, e CI/CD totalmente automatizado.**

[![EKS](https://img.shields.io/badge/EKS-v1.32-blue.svg)](https://aws.amazon.com/eks/)
[![Terraform](https://img.shields.io/badge/Terraform-1.6.0-purple.svg)](https://www.terraform.io/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-17.6-blue.svg)](https://www.postgresql.org/)
[![GitHub Actions](https://img.shields.io/badge/CI%2FCD-20%20Workflows-green.svg)](https://github.com/features/actions)
[![Prometheus](https://img.shields.io/badge/Prometheus-Latest-orange.svg)](https://prometheus.io/)
[![Grafana](https://img.shields.io/badge/Grafana-Latest-orange.svg)](https://grafana.com/)
[![Slack Alerts](https://img.shields.io/badge/Slack-Alerts%20Enabled-purple.svg)](https://slack.com/)
[![Quality Gate](https://img.shields.io/badge/Quality%20Gate-Passed-brightgreen.svg)](https://sonarcloud.io/)
[![Security](https://img.shields.io/badge/Security-C%20Rating-yellow.svg)](https://sonarcloud.io/)
[![Maintainability](https://img.shields.io/badge/Maintainability-A%20Rating-brightgreen.svg)](https://sonarcloud.io/)
[![Code Lines](https://img.shields.io/badge/Lines%20of%20Code-2.8k-blue.svg)](https://github.com/maringelix/tx01)

---

## ⚠️ **Important Security Notice**

> 🔒 **This is a demonstration/portfolio project showcasing DevOps best practices.**

**Before using this in production:**

- ⚠️ **DO NOT** copy AWS credentials to code or commit them to Git
- ✅ All AWS credentials must be managed via **GitHub Secrets** or **AWS Secrets Manager**
- ✅ Replace all placeholder values with your own configurations
- ✅ Review and adjust IAM policies according to your security requirements
- ✅ Enable encryption at rest and in transit for all resources
- ✅ Implement proper backup and disaster recovery strategies
- ✅ Follow your organization's security and compliance policies
- ✅ Use AWS Organizations and SCPs for multi-account governance

**Security Features Implemented:**
- 🔐 No credentials in code (all via Secrets Manager/GitHub Secrets)
- 🔐 S3 backend with encryption and versioning
- 🔐 IRSA (IAM Roles for Service Accounts) for EKS
- 🔐 Security Groups with least privilege
- 🔐 RDS encryption at rest
- 🔐 VPC with public/private subnets isolation

**This project is safe to share publicly** - All sensitive data is properly externalized.

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
│  Internet → ALB (via AWS LB Controller) → EKS v1.32        │
│               ├─ Ingress (auto-created)                     │
│               └─ Service (LoadBalancer)                     │
│                           │                                  │
│                    EKS Cluster v1.32                        │
│                    ├─ Node 1 (t3.small)                     │
│                    │  └─ Pod dx01-app                       │
│                    ├─ Node 2 (t3.small)                     │
│                    │  └─ Pod dx01-app                       │
│                    ├─ Node 3 (t3.small)                     │
│                    ├─ Node 4 (t3.small)                     │
│                    └─ HPA (2-10 pods)                       │
│                                                              │
│             ↓ (Security Groups)                             │
│                                                              │
│            RDS PostgreSQL 17.6 (t4g.micro)                  │
│            ├─ Database: tx01_stg                            │
│            ├─ Tables: visits, app_users                     │
│            └─ Backup: AWS Backup (7 dias) + RDS Snapshots  │
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
- **GitHub Actions**: 8 workflows automatizados
- **AWS CLI v2**: Automação de comandos AWS
- **kubectl v1.32.0**: Gerenciamento do cluster Kubernetes
- **Terraform Cloud**: State management remoto

### **Observability**
- **Prometheus**: Coleta de métricas (application + infrastructure)
- **Grafana**: Dashboards e visualização
- **Loki**: Agregação de logs centralizada
- **Promtail**: Coleta de logs dos pods
- **AlertManager**: Gerenciamento e roteamento de alertas
- **Slack Integration**: Notificações em tempo real (Critical, Warning, Info)
- **15+ Alertas Críticos**: Monitoramento proativo com notificações automáticas

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
│   ├── serviceaccount.yaml     # IRSA service account
│   ├── install-grafana-stack.sh    # Script de instalação do Grafana Stack
│   └── prometheus-alerts.yaml  # 15+ alertas críticos configurados
├── docker/
│   ├── Dockerfile
│   ├── nginx.conf
│   └── default.conf
├── .github/workflows/
│   ├── tests.yml               # 🧪 Terraform validation tests
│   ├── terraform-plan.yml      # 📊 Terraform convergence reports
│   ├── terraform-bootstrap.yml # 🏗️ Bootstrap S3 backend
│   ├── tf-deploy.yml           # 🚀 Deploy EC2 infrastructure
│   ├── eks-deploy.yml          # ☸️ Deploy EKS + Kubernetes apps
│   ├── deploy-observability.yml # 📊 Deploy Grafana Stack
│   ├── switch-environment.yml  # 🔄 Switch between EC2 ↔️ EKS
│   ├── docker-build.yml        # 🐳 Build and push to ECR
│   └── manage-environment.yml  # ⚙️ Manage infrastructure
├── terraform/tests/
│   ├── vpc.tftest.hcl          # Network validation tests
│   ├── eks.tftest.hcl          # EKS cluster tests
│   └── rds.tftest.hcl          # Database tests
├── docs/
│   ├── EKS_UPGRADE_NOTES.md    # EKS v1.32 migration guide
│   ├── SWITCH_GUIDE.md         # Environment switching guide
│   ├── DATABASE_CONFIG.md      # PostgreSQL configuration
│   ├── DEPLOYMENT_GUIDE.md     # Deployment step-by-step
│   ├── TROUBLESHOOTING.md      # Common issues and fixes
│   ├── OBSERVABILITY.md        # Grafana Stack complete guide
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

### **Overview de Workflows**

O projeto possui **20 workflows automatizados** para gerenciar todo o ciclo de vida da infraestrutura:

| Workflow | Emoji | Trigger | Função |
|----------|-------|---------|--------|
| **CI/CD & Validation** | | | |
| Tests | 🧪 | Push, PR | Valida Terraform (fmt, validate, test) |
| Terraform Validate | ✅ | Push, PR | Valida sintaxe Terraform |
| Terraform Plan | 📊 | Pull Request | Gera relatório de convergência |
| Docker Build & Push | 🐳 | Push (docker/, server/, client/) | Build e push para ECR com Trivy scan |
| **Infrastructure** | | | |
| Terraform Bootstrap | 🏗️ | Manual | Cria backend S3 + DynamoDB |
| Terraform Deploy | 🚀 | Manual, Push | Deploy infraestrutura base |
| EKS Deploy | ☸️ | Manual | Provisiona/deploy/destroy cluster EKS |
| Switch Environment | 🔄 | Manual | Alterna entre modo EC2 ↔️ EKS |
| Manage Environment | 🎛️ | Manual | Shutdown/Startup de EKS + RDS (economia) |
| Destroy Environment | 💣 | Manual | Destrói ambiente completo (preserva state) |
| Scale EKS Nodes | 📈 | Manual | Ajusta número de nodes (0-10) |
| Destroy & Recreate NodeGroup | 🔄 | Manual | Recria node group (troubleshooting) |
| Terraform Import EBS CSI | 📥 | Manual | Importa EBS CSI driver ao state |
| **Observability** | | | |
| Deploy Observability Stack | 📊 | Manual | Instala Grafana Stack completo |
| Deploy Observability Micro | 📊 | Manual | Instala versão otimizada (low resources) |
| Configure AlertManager | 🔔 | Manual | Configura alertas Slack |
| Deploy Gatekeeper | 🛡️ | Manual | Instala OPA Gatekeeper (policies) |
| Deploy Gatekeeper Micro | 🛡️ | Manual | Versão otimizada do Gatekeeper |
| **Backup & Recovery** | | | |
| Configure Backup Automation | 🗄️ | Manual | Configura AWS Backup (RDS, EBS) |
| Restore from Backup | ♻️ | Manual | Restaura recursos de backups |

---

### **1. 🧪 Terraform Tests**
Valida código Terraform em cada commit/PR

```yaml
Trigger: push, pull_request
Branches: main, develop
Actions:
  - terraform fmt -check
  - terraform validate
  - terraform test (vpc, eks, rds)
```

**Quando usar:**
- Automático em todo push/PR
- Valida sintaxe e lógica antes do merge

---

### **2. 📊 Terraform Plan Report**
Gera relatório detalhado de mudanças em Pull Requests

```yaml
Trigger: pull_request
Branches: main
Actions:
  - terraform init
  - terraform plan
  - Parse output (resources to add/change/destroy)
  - Comment no PR com tabela de mudanças
  - Upload plan artifact (5 dias)
```

**Output Exemplo:**
```
📊 Terraform Plan Report - stg

📝 Summary:
Resources to add: 5
Resources to change: 2
Resources to destroy: 1

🔍 Detailed Changes:
+ aws_eks_cluster.main
+ aws_eks_node_group.main
~ aws_security_group.eks (tags)
- aws_instance.old_server
```

**Quando usar:**
- Automático em todo Pull Request
- Review de mudanças antes do merge
- Detecção de drift de infraestrutura

---

### **3. 🏗️ Terraform Bootstrap**
Cria backend S3 + DynamoDB para Terraform state

```yaml
Trigger: workflow_dispatch (manual)
Actions: bootstrap
Output:
  - S3 bucket: tx01-terraform-state-<account-id>
  - DynamoDB table: tx01-terraform-locks
```

**Quando usar:**
- Apenas uma vez no início do projeto
- Se precisar recriar o backend

---

### **4. 🚀 Terraform Deploy**
Deploy da infraestrutura base (VPC, EC2, ALB, RDS)

```yaml
Trigger: workflow_dispatch (manual), push em terraform/
Environment: stg, prd
Actions: plan, apply, destroy
```

**Quando usar:**
- Deploy inicial da infraestrutura
- Atualizar recursos (VPC, ALB, RDS, Security Groups)
- Destruir ambiente completo

---

### **5. ☸️ EKS Deploy**
Deploy do cluster EKS e aplicações Kubernetes

```yaml
Trigger: workflow_dispatch (manual)
Environment: stg, prd
Actions:
  - provision: Cria cluster EKS + node groups
  - deploy: Deploy de aplicações K8s
  - destroy: Remove cluster EKS
```

**Recursos criados:**
- EKS Cluster v1.32
- Node Group (2x t3.small)
- AWS Load Balancer Controller
- Metrics Server
- Deployments + Services + Ingress + HPA

**Quando usar:**
- Criar cluster Kubernetes
- Fazer deploy/atualizar aplicações
- Remover cluster para economizar

---

### **6. 📊 Deploy Observability Stack**
Instala stack completo de monitoramento (Grafana + Prometheus + Loki)

```yaml
Trigger: workflow_dispatch (manual)
Environment: stg, prd
Actions:
  - install: Instalação completa (~5-8 min)
  - upgrade: Atualiza stack existente (~2-3 min)
  - uninstall: Remove stack, preserva dados (~1-2 min)
```

**⚠️ Pré-requisito obrigatório:**
Configure o secret `GRAFANA_PASSWORD` no GitHub antes de executar:
1. Acesse: `Settings > Secrets and variables > Actions`
2. Crie `GRAFANA_PASSWORD` com senha forte (min 8 chars)
3. O workflow validará antes de instalar

**Stack instalado:**
- ✅ Prometheus (métricas, 7d retention, 10Gi)
- ✅ Grafana (dashboards, 5Gi storage) 🔐 Senha configurada via secret
- ✅ Loki (logs, 7d retention, 10Gi)
- ✅ Promtail (coleta de logs)
- ✅ AlertManager (15+ alertas críticos)

**Output:**
- URL do Grafana LoadBalancer
- Status dos pods
- Comandos para port-forward
- Credenciais: `admin` / `<seu GRAFANA_PASSWORD>`

**Quando usar:**
- Após criar cluster EKS
- Adicionar monitoramento a ambiente existente
- Atualizar versões do stack
- Remover observability temporariamente

**💰 Custo:** ~$2.50/mês (apenas volumes EBS)

---

### **7. 🔔 Configure AlertManager**
Configura integração do Prometheus AlertManager com Slack

```yaml
Trigger: workflow_dispatch (manual)
Inputs:
  - slack_channel: Nome do canal (sem #)
  - severity_filter: critical, warning, info
```

**Pré-requisitos:**
1. Criar Incoming Webhook no Slack:
   - Acesse https://api.slack.com/apps
   - Create App > From scratch
   - Ative "Incoming Webhooks"
   - Adicione webhook ao workspace
   - Copie a URL

2. Adicionar secret no GitHub:
   - `Settings > Secrets > Actions`
   - Nome: `SLACK_WEBHOOK_URL`
   - Value: URL do webhook

**Stack configurado:**
- ✅ **AlertManager** - 3 receivers (Critical, Warning, Info)
- ✅ **Slack Notifications** - Mensagens formatadas com cores
- ✅ **@channel mention** - Para alertas críticos
- ✅ **Resolved alerts** - Notificação quando problema é resolvido
- ✅ **Test alert** - Enviado automaticamente após configuração

**Tipos de alertas:**
- 🚨 **Critical**: KubePodCrashLooping, KubeNodeNotReady, TargetDown (menciona @channel)
- ⚠️ **Warning**: KubePodNotReady, KubeDeploymentReplicasMismatch, Resource overcommit
- 🔔 **Info**: Alertas informativos gerais
- ✅ **Resolved**: Notificação verde quando alerta é resolvido

**Quando usar:**
- Após instalar Grafana Stack
- Quando precisar de notificações em tempo real
- Para integrar com ferramentas de comunicação da equipe

**Documentação:** Veja alertas ativos em `k8s/prometheus-alerts.yaml`

---

### **8. 🗄️ Configure Backup Automation**
Configura backups automatizados para RDS e EBS usando AWS Backup

```yaml
Trigger: workflow_dispatch (manual)
Inputs:
  - environment: stg, prd
  - backup_retention_days: 7, 14, 30, 90
  - enable_cross_region: true/false
  - backup_schedule: cron expression (default: 0 3 * * *)
```

**O que será configurado:**
- ✅ **AWS Backup Vault** - Repositório seguro para backups
- ✅ **Backup Plan** - Política diária automatizada
- ✅ **IAM Roles** - Permissões para AWS Backup service
- ✅ **Resource Tagging** - Tags automáticas para recursos elegíveis
- ✅ **RDS Automated Snapshots** - Backup nativo do PostgreSQL
- ✅ **EBS Volume Snapshots** - Backup de volumes Kubernetes (PVCs)
- ✅ **Cross-Region Copy** - Cópia para região secundária (disaster recovery)
- ✅ **Lifecycle Management** - Rotação automática baseada em retention

**Recursos protegidos:**
- 🗄️ **RDS PostgreSQL** - Database completo
- 💾 **EBS Volumes** - Persistent volumes (Prometheus, Grafana, Loki, app data)
- 📦 **Automated daily backups** - 3h AM UTC (horário de menor uso)

**Retenção recomendada:**
- Staging: 7 dias (economia de custos)
- Production: 30-90 dias (compliance e auditoria)

**Cross-region:**
- Primary: `us-east-1`
- Backup: `us-west-2` (proteção contra falha regional)

**Quando usar:**
- Logo após provisionar infraestrutura
- Antes de mudanças críticas no banco de dados
- Como parte da estratégia de disaster recovery

**💰 Custo estimado:**
- Snapshots: ~$0.05/GB/mês
- Cross-region transfer: ~$0.02/GB (primeira cópia)
- Exemplo: 20GB RDS + 30GB EBS = ~$2.50/mês (single region)

---

### **9. ♻️ Restore from Backup**
Restaura recursos a partir de backups do AWS Backup

```yaml
Trigger: workflow_dispatch (manual)
Inputs:
  - environment: stg, prd
  - resource_type: rds, ebs, list-backups
  - recovery_point_arn: ARN do backup (ou vazio para listar)
  - restore_to_new_resource: true/false
```

**Fluxo de restauração:**

1. **Listar backups disponíveis:**
   - resource_type: `list-backups`
   - Mostra tabela com ARNs, datas, tamanhos

2. **Restaurar RDS:**
   - resource_type: `rds`
   - recovery_point_arn: `<ARN do backup>`
   - Cria nova instância ou sobrescreve existente
   - Mantém mesma VPC, security groups, subnet

3. **Restaurar EBS:**
   - resource_type: `ebs`
   - recovery_point_arn: `<ARN do backup>`
   - Cria novo volume na mesma AZ
   - Tags automáticas para rastreamento

**Segurança:**
- ✅ Por padrão cria NOVO recurso (não sobrescreve)
- ✅ Validação de IAM roles e permissões
- ✅ Monitoramento de progresso em tempo real
- ✅ Notificação Slack ao completar/falhar

**Cenários de uso:**
- 🔴 **Disaster Recovery** - Falha catastrófica do RDS/EBS
- 🔄 **Rollback** - Reverter mudança problemática
- 🧪 **Testing** - Criar ambiente de testes com dados reais
- 📊 **Analytics** - Copiar dados para análise offline

**Tempo de restore:**
- RDS: 10-30 minutos (depende do tamanho)
- EBS: 5-15 minutos (depende do tamanho)

**Quando usar:**
- Após falha de banco de dados
- Para testar processo de DR
- Para criar ambiente de staging com dados reais
- Em caso de corrupção de dados

---

### **10. 🎛️ Manage Environment**
Gerencia shutdown/startup de EKS e RDS para economia de custos

```yaml
Trigger: workflow_dispatch (manual)
Inputs:
  - environment: stg, prd
  - action: shutdown, startup
```

**O que faz:**

**Shutdown Mode:**
- ⏸️ Para o cluster EKS (destroy via Terraform)
- ⏸️ Para a instância RDS (aws rds stop-db-instance)
- 💰 Reduz custo de $218/mês → $70/mês
- ⚠️ Volumes EBS são mantidos (dados preservados)
- ⚠️ RDS para automaticamente por até 7 dias

**Startup Mode:**
- ▶️ Recria cluster EKS (terraform apply)
- ▶️ Reinicia instância RDS (aws rds start-db-instance)
- 🚀 Redeploy automático da aplicação
- ✅ Restaura ambiente completo em ~10 minutos

**Quando usar:**
- 🌙 **Shutdown noturno** - Economizar durante off-hours
- 📅 **Fim de semana** - Desligar sexta à noite, ligar segunda de manhã
- 💰 **Economia de crédito** - Reduzir queima de AWS credits
- 🧪 **Ambiente de dev** - Ligar apenas quando estiver desenvolvendo

**Exemplo de economia:**
- Rodando 24/7: $218/mês = $7.27/dia
- Shutdown 16h/dia: $70/mês = $2.33/dia
- **Economia: 68%** ($148/mês)

---

### **11. 💣 Destroy Environment**
Destrói ambiente completo preservando Terraform state

```yaml
Trigger: workflow_dispatch (manual)
Inputs:
  - environment: stg, prd
```

**O que faz:**
- 🗑️ Remove cluster EKS completo
- 🗑️ Remove instância RDS
- 🗑️ Remove VPC, subnets, security groups
- 🗑️ Remove volumes EBS
- ✅ **Preserva:** S3 backend, DynamoDB locks, AWS Backup vault
- 💰 Reduz custo para $1.20/mês (S3 + DynamoDB + Backups)

**Multi-pass cleanup:**
- 🔄 Pass 1: Terraform destroy (recursos principais)
- 🔄 Pass 2: Orphaned resources (ENIs, security groups)
- 🔄 Pass 3: Backup verification (confirma que backups existem)

**Segurança:**
- ⚠️ Requer confirmação manual do environment
- ✅ Valida existência de backups antes de destruir RDS
- ✅ Lista recursos órfãos para cleanup manual se necessário
- 📊 Relatório completo de recursos destruídos

**Quando usar:**
- 🏁 **Projeto finalizado** - Desativar ambiente permanentemente
- 💰 **Economia extrema** - Reduzir custo ao mínimo
- 🔄 **Rebuild completo** - Destruir e recriar do zero
- 🧹 **Cleanup** - Remover ambiente de teste/staging

**Tempo:** ~15-20 minutos

---

### **12. 🔄 Switch Environment**
Alterna entre modo EC2 e modo EKS

```yaml
Trigger: workflow_dispatch (manual)
Environment: stg, prd
Modes:
  - eks: Ativa EKS, para EC2s
  - ec2: Ativa EC2s, para pods EKS
```

**Quando usar:**
- Economizar custos (EKS ~$156 → EC2 ~$54)
- Testar diferentes arquiteturas
- Manutenção de um ambiente

---

### **11. 🐳 Docker Build & Push**
Build e push de imagens Docker para ECR

```yaml
Trigger: push em docker/, server/, client/
Actions:
  - Build multi-stage image
  - Vulnerability scan (Trivy)
  - Push to ECR
  - Update ECS/EC2 (se aplicável)
```

**Quando usar:**
- Automático ao atualizar código da aplicação
- Build manual de nova versão

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

## 📊 Observability Stack

### 🎯 Stack Completo de Monitoramento

O projeto inclui um stack completo de observabilidade baseado em **Grafana Stack** (totalmente gratuito) para monitoramento de aplicações, infraestrutura e logs.

| Component | Purpose | Retention | Storage |
|-----------|---------|-----------|---------|
| **Prometheus** | Métricas (CPU, RAM, requests) | 7 dias | 10Gi |
| **Grafana** | Dashboards e visualização | - | 5Gi |
| **Loki** | Agregação de logs | 7 dias | 10Gi |
| **Promtail** | Coleta de logs dos pods | - | - |
| **AlertManager** | Gerenciamento de alertas | - | - |

**💰 Custo Total**: ~$2.50/mês (apenas volumes EBS)

---

### 🚀 Deploy Automático via GitHub Actions

#### **Opção 1: Workflow Automatizado (Recomendado)**

```bash
# 1. Acesse GitHub Actions
https://github.com/maringelix/tx01/actions

# 2. Selecione "📊 Deploy Observability Stack"

# 3. Clique em "Run workflow"

# 4. Configure:
   Environment: stg ou prd
   Action: install     # Primeira instalação
          upgrade      # Atualizar stack existente  
          uninstall    # Remover stack (preserva dados)

# 5. Aguarde ~5-8 minutos para instalação completa
```

**O workflow automaticamente:**
- ✅ Instala Prometheus + Grafana + Loki + Promtail
- ✅ Aplica 15+ alertas críticos pré-configurados
- ✅ Configura retenção de 7 dias
- ✅ Provisiona volumes persistentes (10Gi/5Gi)
- ✅ Obtém URL do Grafana LoadBalancer
- ✅ Verifica saúde dos pods

---

#### **Opção 2: Instalação Manual (Alternativa)**

```bash
# Quick install
chmod +x k8s/install-grafana-stack.sh
./k8s/install-grafana-stack.sh

# Verificar instalação
kubectl get pods -n monitoring
kubectl get pvc -n monitoring
```

---

### 🔐 Acessar Grafana

#### **Opção A: Port-Forward (Grátis - Recomendado)**

```bash
# Forward porta local
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80

# Acessar no browser
http://localhost:3000

# Credenciais padrão
Username: admin
Password: admin
```

💡 **Economia**: $0/mês vs $18/mês do LoadBalancer

#### **Opção B: LoadBalancer (Automático - Custa $18/mês)**

```bash
# URL fornecida pelo workflow
# Ou obter manualmente:
kubectl get svc -n monitoring kube-prometheus-stack-grafana

# Acessar URL externa
http://<load-balancer-url>
```

---

### 📊 Dashboards Pré-configurados

Importe os seguintes dashboards no Grafana:

| Dashboard | ID | Descrição |
|-----------|-----|-----------|
| **Node.js Application** | 11159 | Métricas de app Node.js/Express |
| **PostgreSQL Database** | 9628 | Monitoramento RDS PostgreSQL |
| **Kubernetes Cluster** | 15757 | Overview do cluster EKS |
| **Kubernetes Pods** | 15760 | Métricas detalhadas dos pods |
| **NGINX Ingress** | 9614 | Tráfego e latência do Ingress |

**Como Importar:**
1. Grafana → Menu (☰) → Dashboards → Import
2. Cole o ID do dashboard
3. Selecione o datasource "Prometheus"
4. Click "Import"

---

### 🔔 Alertas Críticos (15+ Configurados)

Os seguintes alertas são aplicados automaticamente:

#### **Critical Alerts** (⚠️ Alta Prioridade)
- 🔴 **ApplicationDown** - Aplicação indisponível
- 🔴 **DatabaseDown** - PostgreSQL offline
- 🔴 **NodeNotReady** - Node do cluster com problemas
- 🔴 **PodCrashLooping** - Pod reiniciando continuamente
- 🔴 **PersistentVolumeClaimPending** - Volume não provisionado

#### **Warning Alerts** (⚠️ Média Prioridade)
- 🟡 **HighErrorRate** - Taxa de erros >5%
- 🟡 **HighLatency** - Latência P95 >500ms
- 🟡 **HighCPUUsage** - CPU >80%
- 🟡 **HighMemoryUsage** - RAM >85%
- 🟡 **DiskPressure** - Disco >85%
- 🟡 **DatabaseConnectionsHigh** - Conexões >80%
- 🟡 **HighPodRestartRate** - Restarts frequentes

**Configuração de Notificações:**
```bash
# Editar AlertManager config
kubectl edit configmap -n monitoring alertmanager-kube-prometheus-stack-alertmanager

# Adicionar integrações:
# - AWS SNS
# - Slack
# - Email
# - PagerDuty
```

---

### 📈 Métricas Coletadas

#### **Application Metrics** (via Prometheus)
```bash
# Total de requisições HTTP
http_requests_total

# Latência das requisições
http_request_duration_seconds

# Taxa de erros
http_requests_errors_total

# Conexões do banco
pg_stat_database_numbackends
```

#### **Infrastructure Metrics**
```bash
# Uso de CPU dos pods
container_cpu_usage_seconds_total

# Uso de memória dos pods
container_memory_working_set_bytes

# Tráfego de rede
container_network_transmit_bytes_total
```

#### **Database Metrics** (PostgreSQL)
```bash
# Conexões ativas
pg_stat_database_numbackends

# Queries executadas
pg_stat_database_xact_commit

# Tamanho do banco
pg_database_size_bytes
```

---

### 📝 Logs com Loki

#### **Visualizar Logs no Grafana**
```bash
# 1. Grafana → Explore
# 2. Datasource: Loki
# 3. Log browser: {namespace="default"}
# 4. Filtros úteis:

# Logs da aplicação
{app="tx01-app"}

# Logs de erro
{app="tx01-app"} |= "error"

# Logs por severidade
{app="tx01-app"} | json | level="error"

# Top 10 erros
topk(10, sum by (level) (count_over_time({app="tx01-app"} [1h])))
```

#### **CLI: Logs via Promtail**
```bash
# Ver logs em tempo real
kubectl logs -f -n monitoring -l app.kubernetes.io/name=promtail

# Logs da aplicação
kubectl logs -f deployment/tx01-app

# Logs do banco (RDS)
aws logs tail /aws/rds/instance/tx01-db-stg/postgresql --follow
```

---

### 🔧 Gerenciamento do Stack

#### **Atualizar Stack**
```bash
# Via Workflow (recomendado)
GitHub Actions → Deploy Observability Stack → upgrade

# Via CLI
helm upgrade kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  -n monitoring \
  --values k8s/prometheus-values.yaml
```

#### **Remover Stack (Preserva Dados)**
```bash
# Via Workflow
GitHub Actions → Deploy Observability Stack → uninstall

# Os volumes persistentes são preservados
kubectl get pvc -n monitoring
```

#### **Remover TUDO (Incluindo Dados)**
```bash
# ⚠️ CUIDADO: Remove dados históricos
kubectl delete namespace monitoring
```

#### **Verificar Saúde**
```bash
# Status dos pods
kubectl get pods -n monitoring

# Métricas dos pods
kubectl top pods -n monitoring

# Logs do Prometheus
kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus

# Logs do Grafana
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana
```

---

### 💡 Dicas de Uso

#### **1. Configurar senha customizada no Grafana**
```bash
# Adicionar secret no GitHub
Settings > Secrets > Actions
Nome: GRAFANA_PASSWORD
Valor: SuaSenhaSegura123!

# O workflow usará automaticamente
```

#### **2. Persistência de Dados**
```bash
# Os dados são salvos em volumes EBS
# Mesmo se deletar os pods, dados permanecem

# Verificar volumes
kubectl get pvc -n monitoring

# Verificar uso
kubectl exec -n monitoring prometheus-kube-prometheus-stack-prometheus-0 -- \
  df -h /prometheus
```

#### **3. Exportar Dashboards**
```bash
# Grafana → Dashboard → Share → Export → Save to file
# Commit no repo: k8s/dashboards/custom-dashboard.json
```

#### **4. Consultar Métricas via API**
```bash
# Port-forward Prometheus
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090

# Query via curl
curl 'http://localhost:9090/api/v1/query?query=up'
```

---

### 📚 Documentação Completa

📖 **Guia Detalhado**: [OBSERVABILITY.md](./OBSERVABILITY.md)

**Conteúdo:**
- Setup passo-a-passo
- Configuração de alertas customizados
- Queries Prometheus avançadas
- Integrações (Slack, SNS, Email)
- Dashboard customization
- Troubleshooting
- Best practices

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
- **CI/CD Completo** - 8 workflows GitHub Actions totalmente automatizados
- **Infrastructure as Code** - 100% Terraform com módulos reutilizáveis
- **Automated Testing** - Terraform validation tests (vpc, eks, rds)
- **Drift Detection** - Terraform Plan reports em Pull Requests
- **GitOps Ready** - Manifests Kubernetes versionados
- **Security First** - WAF, IRSA, Secrets Manager, Security Groups
- **Observability** - Grafana Stack completo (Prometheus + Grafana + Loki)
- **Documentação Completa** - 7 guias detalhados

### ✅ **Produção Ready**
- **Zero Downtime Deployments** - Rolling updates configurados
- **Health Checks** - Liveness e Readiness probes
- **Resource Limits** - Requests e limits definidos
- **Metrics & Monitoring** - Prometheus + Grafana com 15+ alertas
- **Log Aggregation** - Loki para logs centralizados
- **Alert Management** - AlertManager configurado
- **Database Schema** - Criado automaticamente no startup
- **SSL/TLS Ready** - Preparado para certificados ACM

### 📊 **Estatísticas do Projeto**
- 📝 **30+ Commits** - Desenvolvimento incremental
- 🔧 **8 Workflows** - Automação completa (Tests, Deploy, Observability)
- 📚 **7 Guias** - Documentação abrangente (incluindo Observability)
- ☁️ **30+ Recursos AWS** - Infraestrutura robusta
- 📊 **15+ Alertas** - Monitoramento proativo
- 🧪 **3 Test Suites** - Terraform validation (vpc, eks, rds)
- 🐛 **15+ Issues Resolvidos** - Troubleshooting avançado
- ⚡ **< 5min Deploy** - Pipeline otimizado

### 💰 **Custo Otimizado**
```
Modo EKS (Produção):
├─ EKS Control Plane: ~$73/mês
├─ EKS Nodes (2x t3.small): ~$60/mês
├─ RDS (t4g.micro): ~$15/mês
├─ ALB: ~$23/mês
├─ Grafana Stack (EBS volumes): ~$2.50/mês
├─ EC2 stopped (2x t3.micro): ~$8/mês (volumes)
└─ Total: ~$181.50/mês

Modo EKS + LoadBalancer Grafana:
├─ EKS + RDS + ALB: ~$171/mês
├─ Grafana LoadBalancer: ~$18/mês
├─ Grafana Stack (EBS): ~$2.50/mês
└─ Total: ~$191.50/mês

Modo EC2 (Desenvolvimento):
├─ EC2 (2x t3.micro): ~$16/mês
├─ ALB: ~$23/mês
├─ RDS (t4g.micro): ~$15/mês
├─ EKS stopped: $0/mês
└─ Total: ~$54/mês

💡 Economia com switch: Até 70%
💡 Use port-forward no Grafana: Economize $18/mês no LoadBalancer
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

- [x] **✅ Monitoramento**: Grafana Stack implementado (Prometheus + Grafana + Loki)
- [x] **✅ Testes Automatizados**: Terraform validation tests implementados
- [x] **✅ Drift Detection**: Terraform Plan workflow com relatórios em PRs
- [x] **✅ Alertas Avançados**: Slack integration configurada (Critical, Warning, Info)
- [x] **✅ Backup Automation**: AWS Backup configurado (RDS, EBS, cross-region, 7-90 dias)
- [x] **✅ Container Security**: Trivy scan implementado no pipeline Docker
- [ ] **Logs Centralizados**: Expandir queries e dashboards do Loki
- [ ] **APM (Application Performance Monitoring)**: Adicionar distributed tracing (Tempo/Jaeger)
- [ ] **Blue/Green Deployment**: Implementar estratégia de deploy avançada
- [ ] **Service Mesh**: Adicionar Istio ou AWS App Mesh
- [ ] **GitOps**: Migrar para ArgoCD ou Flux
- [ ] **Multi-Region**: Expandir para disaster recovery
- [ ] **Cost Optimization**: Implementar AWS Cost Explorer automation e budget alerts
- [ ] **Security Scanning - IaC**: Adicionar tfsec/checkov para Terraform, gitleaks para secrets
- [ ] **Security Scanning - DAST**: Adicionar OWASP ZAP para testes dinâmicos
- [ ] **Chaos Engineering**: Implementar testes de resiliência

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
