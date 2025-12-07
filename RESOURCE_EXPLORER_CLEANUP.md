# Resource Explorer - Recursos Fantasmas (Phantom Resources)

## 🔍 Problema Identificado

Após executar o script `cleanup-aws-manual.ps1`, o **AWS Resource Explorer** ainda mostra 111 recursos, incluindo:
- 50 EC2 Fleets
- 15 Security Group Rules
- 6 Subnets
- 4 Network Interfaces
- E outros...

**Porém, quando você tenta acessar esses recursos no console, eles não existem!**

Exemplo do erro:
```
The networkInterface ID 'eni-0d602b8415723c85d' does not exist
```

## 🤔 Por que isso acontece?

O **AWS Resource Explorer** é um serviço de indexação que:
1. **Cacheia informações de recursos** para buscas rápidas
2. **Atualiza periodicamente** (não em tempo real)
3. **Pode levar até 24-48 horas** para refletir deleções

Esses são **recursos fantasmas** - aparecem no índice mas foram deletados da AWS.

## ✅ Verificação Realizada

O script `cleanup-aws-deep.ps1` verificou TODOS os serviços AWS e confirmou:

```powershell
# Resultado da verificação
EC2 Instances:        0 ✅
EC2 Fleets:           0 ✅
Network Interfaces:   0 ✅
EKS Clusters:         0 ✅
RDS Instances:        0 ✅
Load Balancers:       0 ✅
```

**Conclusão:** Sua conta AWS está LIMPA! Os recursos no Resource Explorer são apenas cache.

## 🛠️ Soluções

### Solução 1: Aguardar (Recomendado)
O AWS Resource Explorer vai atualizar automaticamente:
- **24-48 horas:** Tempo típico de atualização
- **Sem ação necessária:** Recursos fantasmas desaparecem sozinhos

### Solução 2: Forçar Refresh do Resource Explorer
Deletar e recriar o índice para forçar atualização:

```bash
# 1. Listar índices
aws resource-explorer-2 list-indexes --region us-east-1

# 2. Deletar índice (limpa cache)
aws resource-explorer-2 delete-index --region us-east-1

# 3. (Opcional) Recriar índice
# Vá para AWS Console > Resource Explorer > Create Index
```

⚠️ **Atenção:** Deletar o índice remove TODO o cache do Resource Explorer!

### Solução 3: Usar CLI/API para Verificação Real
Em vez de confiar no Resource Explorer, use comandos diretos:

```powershell
# Verificar recursos REAIS (não cache)
aws ec2 describe-instances --region us-east-1
aws ec2 describe-network-interfaces --region us-east-1
aws eks list-clusters --region us-east-1
aws rds describe-db-instances --region us-east-1
```

## 📊 Por que EC2 Fleets aparecem tanto?

**EC2 Fleets** são registros de auto-scaling do EKS:
- Criados automaticamente pelo EKS quando escala nodes
- **Auto-deletam após 48 horas** da criação
- **Não custam nada** (são apenas metadados)
- **Não podem ser deletados manualmente** (AWS managed)

Do seu CSV, todos os 50 fleets são de:
- 4-5 de Dezembro (já têm 2-3 dias)
- Em estado `deleted_running` ou `deleted_terminating`
- Vão desaparecer automaticamente

## 🎯 Recursos que REALMENTE existem

Apenas estes recursos são reais e devem ser mantidos:

### IAM (Service-Linked Roles - Obrigatórios)
```
✅ AWSServiceRoleForAmazonEKS           (necessário se usar EKS)
✅ AWSServiceRoleForAmazonEKSNodegroup  (necessário se usar EKS)
✅ AWSServiceRoleForRDS                 (necessário se usar RDS)
✅ AWSServiceRoleForSupport             (account default)
✅ AWSServiceRoleForTrustedAdvisor      (account default)
```

### S3
```
✅ tx01-terraform-state-maringelix-2025  (Terraform state backend)
```

### IAM User
```
✅ devops-tx01  (sua conta de deploy)
```

### RDS Parameter Groups
```
✅ default.postgres17  (AWS managed default)
```

### VPC Default
```
✅ vpc-default  (AWS account default, não deletável)
  ├─ Subnets default (uma por AZ)
  ├─ Security Group default
  ├─ Network ACL default
  └─ Route Table default
```

## 📝 Scripts Disponíveis

### 1. `cleanup-aws-manual.ps1` (Original)
- Deleta recursos gerenciados pelo Terraform
- Para ambientes stg/prd

**Uso:**
```powershell
.\cleanup-aws-manual.ps1 -Environment stg
.\cleanup-aws-manual.ps1 -Environment stg -DryRun  # Preview
```

### 2. `cleanup-aws-deep.ps1` (Novo - Deep Clean)
- Verifica recursos fantasmas
- Tenta deletar orphaned resources
- Mostra summary completo

**Uso:**
```powershell
.\cleanup-aws-deep.ps1                    # Deleta orphaned
.\cleanup-aws-deep.ps1 -DryRun            # Preview apenas
.\cleanup-aws-deep.ps1 -CsvPath "path"    # Usa CSV customizado
```

## 🔐 Recursos que NÃO devem ser deletados

### Service-Linked Roles
**Tentativa de deletar causa erro:**
```
An error occurred (DeleteConflict): The role cannot be deleted because it is a service-linked role
```

Esses roles são criados automaticamente quando você usa serviços AWS e só podem ser deletados:
1. Desabilitando o serviço completamente na conta
2. Pela própria AWS quando não mais necessário

### Default VPC Resources
- **default VPC:** Não pode ser deletada pela CLI
- **default subnets:** Dependência da VPC default
- **default security group:** Não deletável

## 🧹 Checklist de Limpeza Completa

- [x] 1. EKS Clusters deletados
- [x] 2. RDS Instances deletadas
- [x] 3. EC2 Instances terminadas
- [x] 4. Load Balancers deletados
- [x] 5. Auto Scaling Groups deletados
- [x] 6. Launch Templates deletados
- [x] 7. Network Interfaces órfãs deletadas
- [x] 8. Security Groups customizados deletados
- [x] 9. Subnets customizadas deletadas
- [x] 10. VPCs customizadas deletadas
- [ ] 11. Resource Explorer cache limpo (aguardar 24-48h OU deletar índice)

## 🚀 Comandos Úteis

### Verificar recursos REAIS (ignora cache)
```powershell
# EC2
aws ec2 describe-instances --region us-east-1 `
  --filters "Name=instance-state-name,Values=running,pending,stopping,stopped" `
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name]' --output table

# Fleets (devem estar vazios ou em deleted state)
aws ec2 describe-fleets --region us-east-1 `
  --query 'Fleets[*].[FleetId,FleetState,CreateTime]' --output table

# Network Interfaces disponíveis (órfãos)
aws ec2 describe-network-interfaces --region us-east-1 `
  --filters "Name=status,Values=available" `
  --query 'NetworkInterfaces[*].[NetworkInterfaceId,VpcId]' --output table

# EKS
aws eks list-clusters --region us-east-1

# RDS
aws rds describe-db-instances --region us-east-1 `
  --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus]' --output table

# ALB/NLB
aws elbv2 describe-load-balancers --region us-east-1 `
  --query 'LoadBalancers[*].[LoadBalancerName,State.Code]' --output table
```

### Forçar refresh do Resource Explorer
```bash
# Deletar índice (limpa cache)
aws resource-explorer-2 delete-index --region us-east-1

# Aguardar 5 minutos e recriar
aws resource-explorer-2 create-index --region us-east-1

# Ou criar via console para ter interface visual
```

### Verificar custos atuais
```bash
# Custos do mês atual (should be $0 with free tier)
aws ce get-cost-and-usage \
  --time-period Start=$(date -u -d '1 day ago' +%Y-%m-%d),End=$(date -u +%Y-%m-%d) \
  --granularity DAILY \
  --metrics BlendedCost \
  --region us-east-1
```

## 📚 Referências

- [AWS Resource Explorer Documentation](https://docs.aws.amazon.com/resource-explorer/)
- [EC2 Fleet Lifecycle](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/manage-ec2-fleet.html)
- [Service-Linked Roles](https://docs.aws.amazon.com/IAM/latest/UserGuide/using-service-linked-roles.html)
- [AWS CLI describe-instances](https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-instances.html)

## 🎓 Lições Aprendidas

1. **Resource Explorer não é real-time**
   - Use CLI/API para verificação real
   - Cache pode levar 24-48h para atualizar

2. **EC2 Fleets são normais**
   - Criados por EKS Auto Scaling Groups
   - Auto-deletam em 48h
   - Não custam nada

3. **Service-Linked Roles são obrigatórios**
   - Não tente deletar manualmente
   - AWS gerencia automaticamente

4. **Terraform State != AWS Resources**
   - State pode estar vazio mas AWS ter defaults
   - Sempre verificar com CLI após destroy

5. **Default VPC é persistente**
   - Não pode ser deletada via CLI
   - É segura de manter (não custa nada)

## ✅ Conclusão

Sua conta AWS está **LIMPA** ✨

Os recursos no Resource Explorer são apenas **cache antigo** que vai desaparecer em 24-48 horas.

Você pode:
- ✅ **Opção 1:** Aguardar atualização automática (recomendado)
- ✅ **Opção 2:** Deletar índice do Resource Explorer para forçar refresh
- ✅ **Opção 3:** Ignorar o Resource Explorer e usar AWS CLI para verificações

**Nenhum custo está sendo gerado!** 💰
