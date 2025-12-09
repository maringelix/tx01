# 🚀 Guia de Execução dos Workflows GitHub Actions

## 📋 Ordem de Execução para Setup Inicial

### ✅ Pré-requisitos

1. **GitHub Secrets configurados:**
   - Vá em: `https://github.com/maringelix/tx01/settings/secrets/actions`
   - Adicione:
     - `AWS_ACCESS_KEY_ID` = Sua chave AWS Access Key ID
     - `AWS_SECRET_ACCESS_KEY` = Sua chave AWS Secret Access Key
   - ⚠️ **NUNCA** comite as credenciais no código!

2. **Verificar se secrets estão configurados:**
   - Acesse: https://github.com/maringelix/tx01/settings/secrets/actions
   - Deve ter 2 secrets: AWS_ACCESS_KEY_ID e AWS_SECRET_ACCESS_KEY

---

## 🔄 Passo 1: Bootstrap (S3 + DynamoDB para Terraform State)

**Objetivo:** Criar backend S3 + DynamoDB para armazenar o state do Terraform remotamente.

### Executar:
1. Vá em: `https://github.com/maringelix/tx01/actions/workflows/terraform-bootstrap.yml`
2. Clique em: **Run workflow**
3. Selecione:
   - **action:** `apply`
4. Clique em: **Run workflow**

### O que será criado:
- ✅ S3 Bucket: `tx01-terraform-state-maringelix-2025`
- ✅ DynamoDB Table: `tx01-terraform-state-maringelix-2025-locks`
- ✅ Versionamento e encriptação habilitados

### Tempo estimado: ~2 minutos

---

## 🏗️ Passo 2: Deploy da Infraestrutura Staging

**Objetivo:** Provisionar infraestrutura AWS (VPC, EKS, RDS, ALB, etc.)

### Executar:
1. Vá em: `https://github.com/maringelix/tx01/actions/workflows/tf-deploy.yml`
2. Clique em: **Run workflow**
3. Selecione:
   - **environment:** `stg`
   - **action:** `plan` (primeiro faça um plan para revisar)
   - **recreate_ec2:** `false`
   - **include_db_checks:** `true`
4. Clique em: **Run workflow**

### Revisar o Plan:
- Veja os recursos que serão criados
- Verifique custos estimados
- Se estiver OK, execute novamente com **action: apply**

### Segunda execução (Apply):
1. Mesmo workflow: `tf-deploy.yml`
2. **Run workflow** novamente
3. Selecione:
   - **environment:** `stg`
   - **action:** `apply` ⚠️
   - **recreate_ec2:** `false`
   - **include_db_checks:** `true`
4. Clique em: **Run workflow**

### O que será criado:
- ✅ VPC (10.0.0.0/16) com subnets públicas/privadas
- ✅ EKS Cluster v1.32 (Control Plane + Node Group)
- ✅ RDS PostgreSQL 17.6 (t4g.micro)
- ✅ ALB (Application Load Balancer)
- ✅ Security Groups
- ✅ IAM Roles e Policies
- ✅ AWS Secrets Manager (credenciais RDS)

### Tempo estimado: ~15-20 minutos

---

## 🐳 Passo 3: Build e Deploy da Aplicação DX01

**Objetivo:** Construir imagem Docker do DX01 e fazer deploy no EKS.

### Executar:
1. Vá em: `https://github.com/maringelix/tx01/actions/workflows/eks-deploy.yml`
2. Clique em: **Run workflow**
3. Selecione:
   - **environment:** `stg`
   - **image_tag:** `latest` (ou versão específica)
4. Clique em: **Run workflow**

### O que será feito:
- ✅ Build da imagem Docker do DX01
- ✅ Push para ECR
- ✅ Deploy no EKS (criação de pods)
- ✅ Configuração de variáveis de ambiente (DB_HOST, etc)
- ✅ Aplicação de secrets do RDS

### Tempo estimado: ~5-7 minutos

---

## 📊 Passo 4: Deploy Observability (Prometheus + Grafana)

**Objetivo:** Instalar stack de monitoramento no EKS.

### Executar:
1. Vá em: `https://github.com/maringelix/tx01/actions/workflows/deploy-observability.yml`
2. Clique em: **Run workflow**
3. Selecione:
   - **environment:** `stg`
   - **action:** `install`
4. Clique em: **Run workflow**

### O que será instalado:
- ✅ Prometheus (coleta de métricas)
- ✅ Grafana (visualização)
- ✅ kube-state-metrics
- ✅ node-exporter
- ✅ Dashboards pré-configurados

### Tempo estimado: ~3-5 minutos

---

## 🔒 Passo 5: Deploy Gatekeeper (Policy Enforcement - Opcional)

**Objetivo:** Instalar OPA Gatekeeper para políticas de segurança.

### Executar:
1. Vá em: `https://github.com/maringelix/tx01/actions/workflows/deploy-gatekeeper.yml`
2. Clique em: **Run workflow**
3. Selecione:
   - **environment:** `stg`
   - **action:** `install`
4. Clique em: **Run workflow**

### O que será instalado:
- ✅ Gatekeeper (OPA)
- ✅ Policies de segurança (block privileged containers, etc)

### Tempo estimado: ~2-3 minutos

---

## 🔍 Verificação e Acesso

### Obter URL da Aplicação:
1. Vá em: Actions → Último run do `eks-deploy.yml`
2. Procure no log: `ALB DNS Name` ou `Ingress Address`
3. Acesse: `http://<alb-dns-name>`

### Verificar Status dos Recursos:

```bash
# Localmente (após configurar kubectl):
aws eks update-kubeconfig --region us-east-1 --name tx01-eks-stg

# Ver pods
kubectl get pods -n default

# Ver services
kubectl get svc -n default

# Ver ingress
kubectl get ingress -n default

# Status do RDS
aws rds describe-db-instances --db-instance-identifier tx01-db-stg
```

---

## 📝 Workflows de Manutenção

### Gerenciar Ambiente (Start/Stop EC2):
- Workflow: `manage-environment.yml`
- Use para: Iniciar/Parar instâncias EC2 (economia de custos)

### Switch EC2 ↔ EKS:
- Workflow: `switch-environment.yml`
- Use para: Alternar entre modo EC2 e EKS

### Scale Nodes EKS:
- Workflow: `scale-eks-nodes.yml`
- Use para: Aumentar/Diminuir nodes do EKS

### Destroy Environment:
- Workflow: `destroy-environment.yml`
- Use para: ⚠️ DESTRUIR toda infraestrutura (cuidado!)

---

## 💰 Custos Estimados (Staging)

| Recurso | Tipo | Custo/mês |
|---------|------|-----------|
| EKS Control Plane | - | $73.00 |
| EKS Nodes | 2x t3.small | $30.00 |
| RDS PostgreSQL | t4g.micro | $15.00 |
| ALB | - | $18.00 |
| NAT Gateway | 2x | $66.00 |
| **Total** | | **~$202/mês** |

**Economia:**
- Use `manage-environment.yml` para parar EC2 quando não usar
- Use `scale-eks-nodes.yml` para reduzir nodes: 2 → 1 (economia de $15/mês)

---

## ⚠️ Troubleshooting

### Erro: "No AWS credentials found"
**Solução:** Configure os GitHub Secrets (Passo 1 dos pré-requisitos)

### Erro: "Backend initialization required"
**Solução:** Execute o workflow `terraform-bootstrap.yml` primeiro

### Erro: "Cluster not found"
**Solução:** Aguarde o workflow `tf-deploy.yml` completar (~20min)

### Erro: "ImagePullBackOff" nos pods
**Solução:** Verifique se o workflow `eks-deploy.yml` completou com sucesso

---

## 📚 Links Úteis

- **GitHub Actions:** https://github.com/maringelix/tx01/actions
- **AWS Console:** https://console.aws.amazon.com/
- **EKS Console:** https://console.aws.amazon.com/eks/
- **RDS Console:** https://console.aws.amazon.com/rds/
- **Documentação:** Ver `README.md`, `DEPLOYMENT_GUIDE.md`, `TROUBLESHOOTING.md`

---

## ✅ Checklist de Setup Completo

- [ ] Secrets configurados no GitHub
- [ ] Bootstrap executado (S3 + DynamoDB)
- [ ] Infraestrutura provisionada (tf-deploy.yml com apply)
- [ ] Aplicação deployada (eks-deploy.yml)
- [ ] Observability instalado (deploy-observability.yml)
- [ ] Aplicação acessível via ALB
- [ ] kubectl configurado localmente (opcional)
- [ ] Grafana acessível (opcional)

---

🎉 **Pronto!** Sua infraestrutura TX01/DX01 está no ar via GitHub Actions!
