# TX01 - Quick Reference Guide

Guia rápido de referência para operações comuns.

## 🎯 Checklist Inicial

```
□ Clonar repositório
□ Configurar AWS credentials (aws configure)
□ Revisar terraform/stg/terraform.tfvars
□ Revisar docker/Dockerfile
□ Testar Dockerfile localmente (opcional)
□ Adicionar AWS_ACCESS_KEY_ID ao GitHub Secrets
□ Adicionar AWS_SECRET_ACCESS_KEY ao GitHub Secrets
□ Fazer primeiro deployment em Staging
□ Testar acesso via ALB DNS
□ Deploy em Production (quando pronto)
```

## 📋 Comandos Essenciais

### Terraform

```bash
# Inicializar
cd terraform/stg && terraform init

# Ver mudanças propostas
terraform plan -out=tfplan

# Aplicar mudanças
terraform apply tfplan

# Destruir infraestrutura
terraform destroy -auto-approve

# Ver outputs
terraform output

# Ver outputs específicos
terraform output alb_dns_name
terraform output ecr_repository_url
terraform output instance_public_ips
```

### Makefile

```bash
# Ver todos os comandos disponíveis
make help

# Inicializar ambiente
make init ENV=stg

# Validar configuração
make validate ENV=stg

# Planejar mudanças
make plan ENV=stg

# Aplicar mudanças
make apply ENV=stg

# Destruir infraestrutura
make destroy ENV=stg

# Ver outputs
make outputs ENV=stg

# Conectar via SSH
make ssh-stg
```

### Docker

```bash
# Build local
docker build -t tx01-nginx:latest docker/

# Run local
docker run -d -p 8080:80 --name test-nginx tx01-nginx:latest

# Test
curl localhost:8080/health

# Stop e remove
docker stop test-nginx && docker rm test-nginx
```

### AWS CLI

```bash
# Verificar credenciais
aws sts get-caller-identity

# Listar instâncias EC2
aws ec2 describe-instances --query 'Reservations[].Instances[].[InstanceId,State.Name,Tags[?Key==`Name`].Value|[0]]' --output table

# Ver repository ECR
aws ecr describe-repositories --repository-names tx01-nginx

# Listar imagens ECR
aws ecr describe-images --repository-name tx01-nginx

# Ver health dos targets
aws elbv2 describe-target-health --target-group-arn <ARN>

# Ver logs CloudWatch
aws logs tail /aws/ec2/tx01-stg --follow
```

## 🚀 Workflows Comuns

### Deploy Staging

```bash
cd terraform/stg
terraform init
terraform plan
terraform apply

# Obter DNS do ALB
terraform output alb_dns_name
```

### Deploy Production

```bash
cd terraform/prd
terraform init
terraform plan
terraform apply
```

### Atualizar Imagem Docker

```bash
# 1. Editar Dockerfile
vim docker/Dockerfile

# 2. Commit e push (triggers CI/CD)
git add docker/
git commit -m "update: dockerfile changes"
git push origin main

# 3. Aguardar GitHub Actions completar
# 4. Redeploy instâncias (opcional via terraform apply)
```

### Destruir Infraestrutura

```bash
# Staging
cd terraform/stg && terraform destroy

# Production
cd terraform/prd && terraform destroy
```

## 🔍 Troubleshooting Rápido

| Problema | Solução |
|----------|---------|
| `InvalidUserID.NotFound` | Verifique credentials: `aws sts get-caller-identity` |
| `ECR not found` | Execute `terraform apply` primeiro |
| `ALB return 502` | Verifique logs: `aws logs tail /aws/ec2/tx01-stg --follow` |
| `Container not running` | SSH e rode: `docker ps`, `docker logs nginx` |
| `Terraform state locked` | Execute: `terraform force-unlock <lock-id>` |

## 📊 Monitoramento

```bash
# Health check
curl http://<ALB_DNS>/health

# Nginx status
curl http://<ALB_DNS>/nginx_status

# Logs em tempo real
aws logs tail /aws/ec2/tx01-stg --follow

# Ver métricas ALB
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name TargetResponseTime \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 300 \
  --statistics Average
```

## 🔐 Segurança

- ✅ Nunca commite secrets ou credenciais
- ✅ Use AWS_ACCESS_KEY_ID e AWS_SECRET_ACCESS_KEY como secrets
- ✅ Revogue access keys regularmente
- ✅ Use princípio do menor privilégio
- ✅ Revise Security Groups quando necessário

## 💻 Variáveis de Ambiente

```bash
# Para deployment local
export AWS_REGION=us-east-1
export TF_VAR_environment=stg
export TF_VAR_docker_image_tag=latest

# Para CI/CD (GitHub Actions)
AWS_ACCESS_KEY_ID = seu-id
AWS_SECRET_ACCESS_KEY = sua-chave
```

## 📞 Suporte Rápido

- **Documentação completa**: `README.md`
- **Deploy passo-a-passo**: `DEPLOYMENT_GUIDE.md`
- **Resolução de problemas**: `TROUBLESHOOTING.md`
- **GitHub Secrets setup**: `GITHUB_SECRETS.md`
- **Status implementação**: `IMPLEMENTATION_STATUS.txt`

## 🎯 Próximos Passos

1. **Imediato**: `./quickstart.sh check`
2. **Primeiro deploy**: `cd terraform/stg && terraform apply`
3. **Testar**: `curl http://<ALB_DNS>`
4. **Production**: `cd terraform/prd && terraform apply`
5. **Monitorar**: `aws logs tail /aws/ec2/tx01-stg --follow`
