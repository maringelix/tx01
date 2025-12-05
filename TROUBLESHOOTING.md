# Troubleshooting Avançado

Guia para resolver problemas comuns na infraestrutura TX01.

## 🔧 Problemas Comuns

### 1. Erro: "InvalidUserID.NotFound"

**Causa**: Credenciais AWS inválidas ou não configuradas

**Solução**:
```bash
# Verificar credenciais
aws sts get-caller-identity

# Reconfigurar
aws configure

# Listar credenciais configuradas
cat ~/.aws/credentials

# Ou usar environment variables
export AWS_ACCESS_KEY_ID="seu-id"
export AWS_SECRET_ACCESS_KEY="sua-chave"
export AWS_DEFAULT_REGION="us-east-1"
```

### 2. Erro: "Quota Exceeded"

**Causa**: Limite de recursos alcançado na AWS

**Solução**:
```bash
# Verificar quotas
aws service-quotas get-service-quota \
  --service-code ec2 \
  --quota-code L-1216C47A

# Aumentar quota (requer approval)
aws service-quotas request-service-quota-increase \
  --service-code ec2 \
  --quota-code L-1216C47A \
  --desired-value 10

# Listar todos os recursos
aws ec2 describe-instances --query 'Reservations[].Instances[].[InstanceId,State.Name,Tags[?Key==`Name`].Value|[0]]' --output table
```

### 3. Erro: "ECR Repository Not Found"

**Causa**: Terraform ainda não criou o repositório ECR

**Solução**:
```bash
# Garantir que apply foi executado
cd terraform/stg
terraform apply

# Verificar repositório
aws ecr describe-repositories --repository-names tx01-nginx

# Listar todos os repositórios
aws ecr describe-repositories
```

### 4. Nginx retorna erro 502

**Causa**: Containers não estão rodando nas instâncias EC2

**Solução**:
```bash
# 1. Verificar health dos targets
aws elbv2 describe-target-health \
  --target-group-arn $(cd terraform/stg && terraform output -raw target_group_arn 2>/dev/null)

# 2. Obter IP da instância
EC2_IP=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=tx01-ec2-1-stg" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

# 3. SSH e diagnosticar
ssh -i sua-chave.pem ubuntu@$EC2_IP

# 4. Dentro da instância:
sudo systemctl status docker
docker ps
docker logs nginx
tail -f /var/log/cloud-init-output.log
```

### 5. Erro: "AccessDenied"

**Causa**: Permissões IAM insuficientes

**Solução**:
```bash
# Verificar permissões do usuário
aws iam get-user --user-name seu-usuario

# Listar políticas
aws iam list-attached-user-policies --user-name seu-usuario

# Adicionar permissão (como admin)
aws iam attach-user-policy \
  --user-name seu-usuario \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

### 6. Terraform State Corrompido

**Causa**: Arquivo tfstate corrompido ou obsoleto

**Solução**:
```bash
# Fazer backup
cp terraform/stg/terraform.tfstate terraform/stg/terraform.tfstate.backup

# Reininicializar
cd terraform/stg
rm -rf .terraform terraform.tfstate*

# Reimporter estado
terraform init
terraform plan

# Se necessário, recriar recursos
terraform destroy
terraform apply
```

## 🔍 Diagnosticar Problemas

### Ver Logs do EC2

```bash
# Logs cloud-init (inicialização)
aws ec2 describe-instances \
  --instance-ids i-xxxxx \
  --query 'Reservations[0].Instances[0].[PublicIpAddress]' \
  --output text

# SSH e ver logs
ssh ubuntu@IP
tail -f /var/log/cloud-init-output.log
tail -f /var/log/cloud-init.log
```

### Ver Logs do Docker

```bash
# Dentro da instância EC2
docker logs nginx -f
docker logs nginx --tail=50

# Ver histórico de containers
docker ps -a

# Inspecionar container
docker inspect nginx
```

### Ver Logs do ALB

```bash
# Ativar logs de acesso (opcional)
aws elbv2 modify-load-balancer-attributes \
  --load-balancer-arn $(cd terraform/stg && terraform output -raw alb_arn) \
  --attributes Key=access_logs.s3.enabled,Value=false

# Ver logs do CloudWatch
aws logs describe-log-groups --log-group-name-prefix /aws/alb

# Ver logs em tempo real
aws logs tail /aws/alb/tx01-stg --follow
```

### Ver Logs do WAF

```bash
# Listar regras do WAF
aws wafv2 list-web-acls --scope REGIONAL

# Ver métricas
aws cloudwatch get-metric-statistics \
  --namespace AWS/WAFV2 \
  --metric-name BlockedRequests \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 300 \
  --statistics Sum

# Ver logs do WAF
aws logs tail /aws/waf/tx01-stg --follow
```

## 🚨 Health Checks

### Verificar ALB Health

```bash
# Script para diagnosticar health
#!/bin/bash

ALB_DNS=$(cd terraform/stg && terraform output -raw alb_dns_name)
HEALTH_CHECK=$(curl -s -o /dev/null -w "%{http_code}" http://$ALB_DNS/health)

echo "ALB: $ALB_DNS"
echo "Health Check: $HEALTH_CHECK"

if [ "$HEALTH_CHECK" == "200" ]; then
    echo "✓ ALB is healthy"
else
    echo "✗ ALB health check failed"
fi
```

### Verificar Conectividade

```bash
# Testar conectividade ao ALB
ALB_DNS=$(cd terraform/stg && terraform output -raw alb_dns_name)

# HTTP
curl -v http://$ALB_DNS

# Health endpoint
curl -v http://$ALB_DNS/health

# DNS
nslookup $ALB_DNS
dig $ALB_DNS
```

## 📊 Monitoramento com CloudWatch

### Criar Alarme

```bash
# Alarme para alta taxa de erro
aws cloudwatch put-metric-alarm \
  --alarm-name tx01-high-error-rate \
  --alarm-description "Alert when error rate is high" \
  --metric-name HTTPCode_Target_5XX_Count \
  --namespace AWS/ApplicationELB \
  --statistic Sum \
  --period 300 \
  --threshold 10 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2

# Listar alarmes
aws cloudwatch describe-alarms
```

### Dashboard

```bash
# Criar dashboard
aws cloudwatch put-dashboard \
  --dashboard-name tx01-monitoring \
  --dashboard-body file://dashboard-config.json
```

## 🚨 EKS Nodes Failing to Join Cluster (Orphan Nodes)

### Sintomas

- Instância EC2 está `running` mas não aparece em `kubectl get nodes`
- Health checks da instância passam (2/2 ou 3/3)
- ASG mostra `desiredSize=X` mas Kubernetes tem menos nodes
- SSM Agent não responde (`InvalidInstanceId` error)

### Diagnóstico Rápido

Use o script automatizado:

```bash
# Listar EC2 instances do cluster
aws ec2 describe-instances \
  --filters "Name=tag:eks:cluster-name,Values=tx01-eks-stg" \
            "Name=instance-state-name,Values=running" \
  --query 'Reservations[*].Instances[*].[InstanceId,PrivateIpAddress,LaunchTime]' \
  --output table

# Listar nodes do Kubernetes
kubectl get nodes -o wide

# Comparar IPs para encontrar orphan
# Use o script para diagnosticar:
./troubleshoot-eks-node.sh i-XXXXXXXXXXXXXXXXX
```

### Diagnóstico Manual

```bash
# 1. Verificar status da instância
aws ec2 describe-instance-status --instance-ids i-XXXXXXXXXXXXXXXXX

# 2. Verificar se node existe no Kubernetes
kubectl get nodes -o json | jq -r '.items[].status.addresses[] | select(.type=="InternalIP") | .address'

# 3. Tentar conectar via SSM
aws ssm send-command \
  --instance-ids i-XXXXXXXXXXXXXXXXX \
  --document-name "AWS-RunShellScript" \
  --parameters "commands=systemctl status kubelet --no-pager"

# 4. Se SSM funcionar, verificar logs
aws ssm start-session --target i-XXXXXXXXXXXXXXXXX
# Dentro da sessão:
sudo tail -100 /var/log/cloud-init-output.log
sudo journalctl -u kubelet -n 100 --no-pager
sudo systemctl status containerd
```

### Causas Comuns

1. **SSM Agent não iniciou**: Falha no bootstrap, IAM role incorreto
2. **Kubelet falhou**: Erro de configuração, problema de rede
3. **Containerd não rodando**: Falha no serviço, dependências faltando
4. **Conectividade**: Node não consegue alcançar control plane do EKS
5. **IAM Role**: Instância sem permissões necessárias

### Solução

**Se SSM Agent NÃO responde:**
```bash
# Terminar a instância (ASG vai criar outra)
aws ec2 terminate-instances --instance-ids i-XXXXXXXXXXXXXXXXX --region us-east-1

# Aguardar ASG criar nova instância
watch kubectl get nodes

# Verificar que nova instância juntou ao cluster
kubectl get nodes -o wide
```

**Se SSM Agent responde:**
```bash
# Conectar e diagnosticar
aws ssm start-session --target i-XXXXXXXXXXXXXXXXX

# Executar diagnóstico no node
sudo /home/ec2-user/diagnose-node.sh

# Verificar logs específicos
sudo journalctl -u kubelet -f
sudo journalctl -u containerd -f
sudo tail -f /var/log/cloud-init-output.log
```

### Prevenção

- Use o script `troubleshoot-eks-node.sh` para detectar orphans rapidamente
- Monitor node count: `kubectl get nodes --no-headers | wc -l` vs ASG desired size
- CloudWatch Alarm para node count mismatch
- Verifique user_data script do Terraform para erros de bootstrap

### Exemplo Real (2025-12-05)

```bash
# Problema: 8 EC2 instances, mas apenas 7 Kubernetes nodes
$ kubectl get nodes | wc -l
7

$ aws ec2 describe-instances --filters "Name=tag:eks:cluster-name,Values=tx01-eks-stg" | jq '.Reservations[].Instances[].InstanceId' | wc -l
8

# Orphan identificado: i-0a4427835cdae5d85 (10.0.10.241)
$ ./troubleshoot-eks-node.sh i-0a4427835cdae5d85
# Resultado: SSM Agent not responding

# Solução: Terminar instância
$ aws ec2 terminate-instances --instance-ids i-0a4427835cdae5d85
# ASG criou nova instância que juntou ao cluster com sucesso
```

## 🔄 Redeploy e Rollback

### Rollback de Imagem Docker

```bash
# Listar versões de imagem no ECR
aws ecr describe-images \
  --repository-name tx01-nginx \
  --query 'imageDetails[*].[imagePushedAt,imageTags]' \
  --output table

# Voltar para versão anterior
ECR_URL=$(cd terraform/stg && terraform output -raw ecr_repository_url)

# Fazer pull da versão anterior
docker pull $ECR_URL:v1.0.0

# Retaguejar como latest
docker tag $ECR_URL:v1.0.0 $ECR_URL:latest
docker push $ECR_URL:latest

# Redeploy (instâncias irão puxar nova imagem via user_data)
cd terraform/stg
terraform apply
```

### Rollback de Infraestrutura

```bash
# Com Terraform state backup
cd terraform/stg

# Listar histórico de mudanças
terraform show

# Voltar para versão anterior (se usar git)
git checkout HEAD~1 terraform/stg/

# Reaplicar
terraform apply
```

## 🧪 Teste de Carga

### Teste com Apache Bench

```bash
# Instalar
sudo apt-get install apache2-utils

# Teste de carga
ab -n 1000 -c 50 http://seu-alb-dns/

# Teste com rate limiting
ab -n 100 -c 100 http://seu-alb-dns/
```

### Teste com Locust

```bash
# Instalar
pip install locust

# Executar
locust -f locustfile.py --host=http://seu-alb-dns
```

## 📋 Checklist de Verificação

- [ ] AWS credentials configuradas
- [ ] Terraform init executado
- [ ] terraform plan revisado
- [ ] terraform apply aplicado
- [ ] Todos os recursos criados (EC2, ALB, WAF, ECR)
- [ ] Instâncias EC2 em estado "running"
- [ ] Targets do ALB em "healthy"
- [ ] WAF está protegendo o ALB
- [ ] Imagem Docker no ECR
- [ ] Containers rodando nas instâncias
- [ ] Logs aparecendo no CloudWatch
- [ ] Health checks passando
- [ ] Application acessível via ALB DNS

## 📞 Suporte

Para problemas não listados aqui:

1. Verifique os logs do CloudWatch
2. Consulte a documentação oficial:
   - [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
   - [AWS Documentation](https://docs.aws.amazon.com)
3. Abra uma issue no GitHub
4. Contacte AWS Support (se tiver plano)
