# Guia de Deploy Rápido

Instruções passo-a-passo para fazer deploy da infraestrutura.

## 📋 Pré-requisitos

- [ ] Conta AWS criada
- [ ] AWS CLI instalado: `aws --version`
- [ ] Terraform instalado: `terraform --version`
- [ ] Git instalado
- [ ] Credenciais AWS configuradas

### Configurar AWS Credentials

```bash
# Opção 1: Interactive (recomendado)
aws configure
# Será pedido:
# AWS Access Key ID: [cole sua chave]
# AWS Secret Access Key: [cole sua chave secreta]
# Default region name: us-east-1
# Default output format: json

# Opção 2: Environment variables
export AWS_ACCESS_KEY_ID="seu-access-key"
export AWS_SECRET_ACCESS_KEY="sua-secret-key"
export AWS_DEFAULT_REGION="us-east-1"

# Testar configuração
aws sts get-caller-identity
```

## 🚀 Deploy Staging (Recomendado primeiro)

```bash
# 1. Navegar para diretório staging
cd terraform/stg

# 2. Inicializar Terraform
terraform init

# 3. Verificar o que será criado
terraform plan -out=tfplan

# 4. Aplicar configuração
terraform apply tfplan

# 5. Aguarde 3-5 minutos enquanto as instâncias são criadas

# 6. Obter outputs
terraform output
```

## 🌐 Acessar Aplicação Staging

```bash
# Obter URL do ALB
ALB_DNS=$(terraform output -raw alb_dns_name)
echo "Acesse: http://$ALB_DNS"

# Ou no navegador
# Copie o valor de alb_dns_name do output acima
```

## 🏭 Deploy Production

```bash
# 1. Navegar para diretório production
cd ../prd

# 2. Inicializar Terraform
terraform init

# 3. Verificar o que será criado
terraform plan -out=tfplan

# 4. Aplicar configuração
terraform apply tfplan

# 5. Obter outputs
terraform output
```

## 🐳 Atualizar Imagem Docker

```bash
# 1. Fazer mudanças em docker/Dockerfile
vim docker/Dockerfile

# 2. Build local (opcional para testar)
docker build -t tx01-nginx:test docker/

# 3. Commit e push
git add docker/Dockerfile
git commit -m "update: improve nginx config"
git push origin main

# 4. GitHub Actions automaticamente:
#    - Constrói nova imagem
#    - Escaneia vulnerabilidades  
#    - Faz push para ECR
#    - Você pode fazer redeploy das instâncias

# 5. Para atualizar as instâncias existentes:
cd terraform/stg
terraform apply  # Irá atualizar com nova imagem (via user_data)
```

## 📊 Monitoramento

```bash
# Ver health dos targets do ALB
aws elbv2 describe-target-health \
  --target-group-arn $(terraform output -raw target_group_arn)

# Logs das instâncias
aws logs tail /aws/ec2/tx01-stg --follow

# Conectar via SSH (obter IP)
EC2_IP=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=tx01-ec2-1-stg" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)
ssh -i /caminho/para/chave.pem ubuntu@$EC2_IP
```

## 🧹 Cleanup

```bash
# Para evitar custos, sempre destrua quando terminar de testar

# Staging
cd terraform/stg
terraform destroy

# Production (cuidado!)
cd ../prd
terraform destroy
```

## 🔧 Troubleshooting

### Erro: "Credentials not found"
```bash
aws configure  # Configure suas credenciais novamente
```

### Erro: "Quota exceeded"
```bash
# Você pode ter atingido cota de instâncias na região
# Tente outra região ou contacte AWS support
```

### Instâncias não iniciam containers
```bash
# SSH na instância e verificar
ssh -i chave.pem ubuntu@IP_PUBLICO
tail -f /var/log/cloud-init-output.log
docker logs nginx
```

### ALB retorna 502
```bash
# Verifique se os containers estão rodando
aws ec2 describe-instances --query 'Reservations[0].Instances[0].InstanceId'
# SSH e rode: docker ps
```

## 📈 Próximos Passos

1. **Configurar HTTPS**
   - Adicione certificado ACM
   - Configure listener HTTPS no ALB

2. **Setup CI/CD no GitHub**
   - Adicione AWS_ACCESS_KEY_ID secret
   - Adicione AWS_SECRET_ACCESS_KEY secret
   - Push para main e veja Actions rodarem

3. **Escalar**
   - Aumente `instance_count` em terraform.tfvars
   - Aumente `rate_limit` no WAF

4. **Backup**
   - Configure S3 backend para Terraform state
   - Configure snapshot automático de EBS

## 🧰 Bootstrap: Criar S3 bucket e DynamoDB para Terraform state

Recomendo criar um "bootstrap" para o backend remoto (S3 + DynamoDB lock) antes de aplicar os módulos de `stg` e `prd`.

1. Edite `terraform/bootstrap/variables.tf` e defina um nome único para o bucket (`bucket_name`). O nome do bucket deve ser globalmente único na AWS.

2. Inicialize e aplique o bootstrap (vai criar o bucket S3 e a tabela DynamoDB):

```bash
cd terraform/bootstrap
terraform init
terraform apply -auto-approve
```

3. Ao final, pegue os outputs:

```bash
terraform output s3_bucket_name
terraform output dynamodb_table_name
```

4. Configure o backend remoto nas pastas de ambiente (`terraform/stg` e `terraform/prd`). Exemplo de `backend` que você pode adicionar no topo de `terraform/stg/main.tf` (ou em um arquivo `backend.tf`):

```hcl
terraform {
   backend "s3" {
      bucket         = "<SEU_BUCKET_AQUI>"
      key            = "tx01/stg/terraform.tfstate"
      region         = "us-east-1"
      encrypt        = true
      dynamodb_table = "<SUA_TABELA_LOCKS_AQUI>"
   }
}
```

5. Em seguida, inicialize o backend no diretório do ambiente (isto migrará o state local para o S3):

```bash
cd ../stg
terraform init
terraform plan
terraform apply
```

Observações:
- Se preferir não editar o código, você pode passar as configurações de backend via linha de comando `terraform init -backend-config="bucket=..." -backend-config="key=..." -backend-config="region=..." -backend-config="dynamodb_table=..."`.
- Defina `force_destroy` com cuidado no bootstrap — atualmente o `terraform/bootstrap` usa `force_destroy = true` por padrão para facilitar testes; altere para `false` em produção.


## 💡 Dicas

- Use `terraform plan` antes de `apply`
- Sempre teste em staging primeiro
- Mantenha .gitignore atualizado
- Use environment variables para valores sensíveis
- Implemente branch protection rules no GitHub
