# 🗄️ Backup and Disaster Recovery Strategy

Este documento descreve a estratégia de backup e recuperação de desastres (DR) implementada no projeto TX01.

## 📋 Visão Geral

O projeto utiliza **AWS Backup** - serviço gerenciado da AWS para backup centralizado e automatizado de recursos.

### **Recursos Protegidos**

| Recurso | Tecnologia | Método de Backup | Retention |
|---------|-----------|------------------|-----------|
| RDS PostgreSQL | AWS RDS | AWS Backup + Native Snapshots | 7-90 dias |
| EBS Volumes (EKS) | Amazon EBS | AWS Backup Snapshots | 7-90 dias |
| Terraform State | S3 | Versioning + Replication | Vitalício |
| Kubernetes Manifests | Git | GitHub Repository | Vitalício |

---

## 🎯 Objetivos de Recuperação

### **RTO (Recovery Time Objective)**
Tempo máximo aceitável para restaurar um serviço:

- **RDS Database:** 30 minutos (staging), 15 minutos (production)
- **EBS Volumes:** 20 minutos
- **Kubernetes Cluster:** 10 minutos (provisionar novo cluster)
- **Aplicação:** 5 minutos (redeploy)

### **RPO (Recovery Point Objective)**
Quantidade máxima de dados que pode ser perdida:

- **RDS Database:** 1 dia (staging), 1 hora (production com PITR)
- **EBS Volumes:** 1 dia
- **Terraform State:** 0 (versionamento S3)
- **Application Code:** 0 (Git commits)

---

## 🔄 Estratégia de Backup

### **1. Backup Diário Automatizado**

```yaml
Schedule: 0 3 * * * (3h AM UTC)
Window: 60 minutos de início, 120 minutos de conclusão
Retention: Configurável (7, 14, 30, 90 dias)
```

**Por que 3h AM UTC?**
- Horário de menor tráfego para aplicação brasileira (0h-1h Brasil)
- Minimiza impacto na performance
- Permite conclusão antes do horário comercial

### **2. Tipos de Backup por Recurso**

#### **RDS PostgreSQL**
- ✅ **AWS Backup snapshots** - Backup completo diário
- ✅ **RDS Native snapshots** - Backup automático nativo
- ✅ **Point-in-Time Recovery (PITR)** - Restore para qualquer segundo (últimos 7-35 dias)
- ✅ **Transaction logs** - Mantidos automaticamente pelo RDS

**Processo:**
1. AWS Backup inicia snapshot às 3h AM
2. RDS cria snapshot incremental (minimiza impacto)
3. Snapshot armazenado no backup vault
4. Cópia cross-region (se habilitado)
5. Lifecycle: Delete após retention period

#### **EBS Volumes**
- ✅ **EBS Snapshots** - Backup incremental (apenas blocos modificados)
- ✅ **Tag-based selection** - Identifica volumes automaticamente
- ✅ **Application-consistent** - Snapshot de volume inteiro

**Volumes protegidos:**
- Prometheus storage (métricas)
- Grafana storage (dashboards, configs)
- Loki storage (logs)
- Application PVCs (se existirem)

**Processo:**
1. AWS Backup identifica volumes por tags
2. Snapshot incremental é criado
3. Apenas blocos modificados são copiados
4. Primeiro snapshot: Full backup
5. Subsequentes: Apenas deltas

### **3. Cross-Region Replication (Opcional)**

**Primary Region:** `us-east-1` (North Virginia)  
**Backup Region:** `us-west-2` (Oregon)

**Por que cross-region?**
- ✅ Proteção contra falha regional da AWS
- ✅ Compliance e auditoria
- ✅ Disaster recovery geográfico
- ✅ Permite restore em outra região

**Custos:**
- Transfer: ~$0.02/GB (primeira cópia)
- Storage: ~$0.05/GB/mês (mesma taxa)

**Quando habilitar:**
- ☑️ Production: SIM (crítico)
- ☐ Staging: NÃO (economia de custos)

---

## 🏗️ Arquitetura de Backup

```
┌─────────────────────────────────────────────────────────────┐
│                     us-east-1 (Primary)                      │
│                                                              │
│  ┌──────────────┐         ┌──────────────┐                 │
│  │ RDS Database │────────▶│ AWS Backup   │                 │
│  │  (PostgreSQL)│         │   Vault      │                 │
│  └──────────────┘         │              │                 │
│                           │ - Snapshots  │                 │
│  ┌──────────────┐         │ - Lifecycle  │                 │
│  │ EBS Volumes  │────────▶│ - Encryption │                 │
│  │ (Kubernetes) │         │ - Retention  │                 │
│  └──────────────┘         └──────┬───────┘                 │
│                                   │                          │
└───────────────────────────────────┼─────────────────────────┘
                                    │
                    Cross-Region Copy (optional)
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────┐
│                    us-west-2 (Backup)                        │
│                                                              │
│                    ┌──────────────┐                         │
│                    │ AWS Backup   │                         │
│                    │ Vault Replica│                         │
│                    │              │                         │
│                    │ - DR Copies  │                         │
│                    │ - Same Tags  │                         │
│                    │ - Same Policy│                         │
│                    └──────────────┘                         │
└─────────────────────────────────────────────────────────────┘
```

---

## ⚙️ Configuração

### **Setup Inicial (Uma vez)**

Execute o workflow: **🗄️ Configure Backup Automation**

```bash
Inputs:
  environment: stg ou prd
  backup_retention_days: 7 (stg) ou 30 (prd)
  enable_cross_region: false (stg) ou true (prd)
  backup_schedule: 0 3 * * * (3h AM UTC diariamente)
```

**O que é criado:**
1. Backup Vault em `us-east-1`
2. Backup Vault em `us-west-2` (se cross-region)
3. IAM Role para AWS Backup service
4. Backup Plan com schedule e lifecycle
5. Backup Selections (RDS e EBS por tags)
6. Tags em recursos para identificação

### **Verificar Configuração**

```bash
# AWS Console
AWS Backup > Backup vaults > tx01-backup-vault-stg

# AWS CLI
aws backup list-backup-plans
aws backup list-recovery-points-by-backup-vault \
  --backup-vault-name tx01-backup-vault-stg
```

---

## ♻️ Processo de Restore

### **Cenário 1: Falha de RDS Database**

**Situação:** Database corrompido ou deletado acidentalmente

**Passos:**
1. Execute workflow: **♻️ Restore from Backup**
2. Input: `resource_type: list-backups` (listar disponíveis)
3. Copie o `Recovery Point ARN` do backup desejado
4. Execute novamente:
   - `resource_type: rds`
   - `recovery_point_arn: <ARN copiado>`
   - `restore_to_new_resource: true` (cria novo DB)
5. Aguarde 15-30 minutos
6. Novo DB criado: `tx01-rds-stg-restored-YYYYMMDD-HHMMSS`
7. Atualize Kubernetes secret com novo endpoint:
   ```bash
   kubectl edit secret tx01-db-credentials -n default
   # Altere DB_HOST para novo endpoint
   ```
8. Faça rollout da aplicação:
   ```bash
   kubectl rollout restart deployment dx01-app -n default
   ```
9. Valide conectividade e dados
10. Delete DB antigo se tudo OK

**Tempo total:** ~30-45 minutos

### **Cenário 2: Falha de EBS Volume (Prometheus/Grafana)**

**Situação:** Volume corrompido ou dados perdidos

**Passos:**
1. Liste backups disponíveis (workflow)
2. Copie Recovery Point ARN do volume
3. Restore para novo volume
4. Novo volume: `vol-xxxxx` criado na mesma AZ
5. Anexe volume ao node:
   ```bash
   aws ec2 attach-volume \
     --volume-id vol-xxxxx \
     --instance-id i-xxxxx \
     --device /dev/xvdf
   ```
6. Delete PVC antigo e crie novo apontando para volume restaurado
7. Reinicie pod do Prometheus/Grafana

**Tempo total:** ~20-30 minutos

### **Cenário 3: Disaster Recovery (Região inteira down)**

**Situação:** us-east-1 completamente indisponível

**Passos:**
1. Provisione novo cluster EKS em `us-west-2`:
   ```bash
   # Atualize terraform/stg/terraform.tfvars
   region = "us-west-2"
   
   terraform init
   terraform apply
   ```

2. Restore RDS de backup cross-region:
   - Recovery points estão em `us-west-2` backup vault
   - Execute restore workflow com região `us-west-2`

3. Restore EBS volumes (se necessário):
   - Snapshots replicados estão disponíveis
   - Crie volumes em `us-west-2`

4. Deploy aplicação no novo cluster:
   ```bash
   kubectl apply -f k8s/
   ```

5. Atualize DNS/Route53 para novo ALB

**Tempo total:** ~1-2 horas (provisionamento cluster + restore + deploy)

---

## 🧪 Testes de Restore

### **Frequência Recomendada**
- **Staging:** Mensal
- **Production:** Trimestral

### **Checklist de Teste**

```markdown
- [ ] Listar backups disponíveis
- [ ] Restore RDS para novo recurso
- [ ] Validar integridade de dados (queries)
- [ ] Validar schema e tabelas
- [ ] Restore EBS volume
- [ ] Validar dados no volume restaurado
- [ ] Testar conexão da aplicação com DB restaurado
- [ ] Documentar tempo de restore (RTO real)
- [ ] Deletar recursos de teste
- [ ] Notificar time sobre resultado
```

### **Script de Validação (exemplo)**

```bash
#!/bin/bash
# validate-rds-restore.sh

NEW_ENDPOINT="tx01-rds-stg-restored-20251210-150000.xxx.us-east-1.rds.amazonaws.com"
DB_NAME="tx01_stg"
DB_USER="tx01admin"

echo "Testing restored database..."

# Test connection
psql -h $NEW_ENDPOINT -U $DB_USER -d $DB_NAME -c "SELECT version();"

# Count tables
psql -h $NEW_ENDPOINT -U $DB_USER -d $DB_NAME -c "
  SELECT schemaname, tablename 
  FROM pg_tables 
  WHERE schemaname NOT IN ('pg_catalog', 'information_schema');"

# Validate data
psql -h $NEW_ENDPOINT -U $DB_USER -d $DB_NAME -c "
  SELECT COUNT(*) FROM visits;
  SELECT COUNT(*) FROM app_users;"

echo "✅ Validation complete!"
```

---

## 💰 Custos

### **Staging (7 dias retention, single region)**
```
RDS (20GB database):
  - Snapshots: 20GB × $0.05/GB = $1.00/mês
  - PITR logs: ~$0.20/mês

EBS (30GB Prometheus + Grafana + Loki):
  - Snapshots: 30GB × $0.05/GB = $1.50/mês
  - Incremental: ~70% redução após primeiro = ~$0.50/mês

Total staging: ~$2.00/mês
```

### **Production (30 dias retention, cross-region)**
```
RDS (100GB database):
  - Snapshots: 100GB × $0.05/GB = $5.00/mês
  - Cross-region copy: 100GB × $0.02/GB = $2.00 (uma vez)
  - Cross-region storage: 100GB × $0.05/GB = $5.00/mês
  - PITR logs: ~$1.00/mês

EBS (100GB volumes):
  - Snapshots: 100GB × $0.05/GB = $5.00/mês
  - Cross-region: 100GB × $0.02/GB = $2.00 (uma vez)
  - Cross-region storage: 100GB × $0.05/GB = $5.00/mês
  - Incrementais: ~40% após primeiros = ~$4.00/mês

Total production: ~$24.00/mês
```

### **Otimização de Custos**
- ✅ Use retention menor em staging (7 dias vs 30+)
- ✅ Desabilite cross-region em staging
- ✅ Snapshots EBS são incrementais (economiza muito)
- ✅ Delete backups manualmente se não precisar mais
- ✅ Use AWS Cost Explorer para monitorar

---

## 🔐 Segurança

### **Encryption**
- ✅ Snapshots RDS: Encrypted at rest (mesmo KMS key do RDS)
- ✅ Snapshots EBS: Encrypted at rest (mesmo KMS key do EBS)
- ✅ Cross-region: Encryption mantida
- ✅ In-transit: TLS 1.2+ para todas transferências

### **Access Control**
- ✅ IAM Role dedicado: `tx01-backup-role-<env>`
- ✅ Least privilege: Apenas permissões necessárias
- ✅ Service-linked role: AWS Backup gerenciado
- ✅ Backup vault access: Apenas IAM roles autorizados

### **Compliance**
- ✅ **Retention policies:** Configurável por ambiente
- ✅ **Audit logs:** CloudTrail registra todas ações
- ✅ **Immutable backups:** Não podem ser modificados após criação
- ✅ **Tags:** Rastreabilidade completa (Project, Environment, BackupType)

---

## 📊 Monitoramento

### **Métricas Importantes**

1. **Backup Success Rate**
   - CloudWatch Metric: `AWS/Backup`
   - Threshold: <95% = alerta

2. **Backup Duration**
   - Esperado: 10-30 min (RDS), 5-15 min (EBS)
   - >60 min = investigar

3. **Storage Growth**
   - Monitore custos mensais
   - Snapshots devem ser incrementais

### **Alertas**

Configure no CloudWatch:
```yaml
BackupJobFailed:
  Metric: AWS/Backup.BackupJobsFailed
  Threshold: >= 1
  Action: SNS topic → Slack

BackupVaultFull:
  Metric: AWS/Backup.NumberOfRecoveryPoints
  Threshold: >= 30 (staging) ou >= 90 (prod)
  Action: Alert ops team
```

### **Dashboards**

Grafana dashboard sugerido:
- Backup job success/failure rate
- Storage consumed by backups
- Time to complete backups
- Recovery point age (último backup válido)

---

## 📚 Workflows Disponíveis

### **1. 🗄️ Configure Backup Automation**
- **Quando:** Setup inicial ou mudança de política
- **O que faz:** Cria vault, plan, IAM roles, tags
- **Frequência:** Uma vez (depois só ajustes)

### **2. ♻️ Restore from Backup**
- **Quando:** DR, teste, rollback
- **O que faz:** Restaura RDS ou EBS de recovery point
- **Frequência:** Conforme necessário + testes mensais

---

## 🎯 Checklist Pós-Configuração

```markdown
- [ ] Backup automation configurado via workflow
- [ ] Primeira execução de backup validada
- [ ] Recovery points visíveis no AWS Console
- [ ] Cross-region habilitado (se production)
- [ ] Restore testado com sucesso (pelo menos uma vez)
- [ ] Documentação atualizada com endpoints
- [ ] Time treinado em processo de restore
- [ ] Alertas CloudWatch configurados
- [ ] Runbook de DR documentado
- [ ] Custos monitorados (AWS Cost Explorer)
```

---

## 🆘 Troubleshooting

### **Backup job failed**
```bash
# Check backup job logs
aws backup describe-backup-job --backup-job-id <job-id>

# Common causes:
# - IAM role permissions
# - Resource not tagged correctly
# - Backup window too short
```

### **Restore taking too long**
```bash
# Check restore job status
aws backup describe-restore-job --restore-job-id <job-id>

# RDS restore time depends on:
# - Database size
# - Instance type
# - IOPS provisioned
```

### **Cross-region copy failed**
```bash
# Validate backup vault exists in target region
aws backup describe-backup-vault \
  --backup-vault-name tx01-backup-vault-stg-replica \
  --region us-west-2

# Check IAM role has cross-region permissions
```

---

## 📖 Referências

- [AWS Backup Documentation](https://docs.aws.amazon.com/aws-backup/)
- [RDS Backup Best Practices](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_CommonTasks.BackupRestore.html)
- [EBS Snapshot Best Practices](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-creating-snapshot.html)
- [Disaster Recovery Strategies](https://docs.aws.amazon.com/whitepapers/latest/disaster-recovery-workloads-on-aws/disaster-recovery-options-in-the-cloud.html)

---

<div align="center">

**🔒 Seu ambiente está protegido!**

*Lembre-se: Backup sem teste de restore é apenas esperança. Teste regularmente!*

</div>
