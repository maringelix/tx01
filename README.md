# TX01 - Infraestrutura AWS com Terraform e CI/CD

Infraestrutura profissional de DevOps com 2 instâncias EC2, Docker, Nginx, ALB, WAF, ECR e CI/CD automatizado via GitHub Actions.

## 📋 Arquitetura

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
              │  ALB (us-east-1)│
              └────────┬────────┘
                       │
         ┌─────────────┴──────────────┐
         │                            │
    ┌────▼─────┐              ┌────▼─────┐
    │ EC2-1    │              │ EC2-2    │
    │ (Nginx)  │              │ (Nginx)  │
    │ Docker   │              │ Docker   │
    └────┬─────┘              └────┬─────┘
         │                         │
         └────────────┬───────────┘
                      │
                  ┌───▼────┐
                  │  ECR   │
                  │ (Image)│
                  └────────┘
```

## 🚀 Tecnologias

- **Terraform**: Infrastructure as Code
- **AWS**: VPC, EC2, ALB, WAF, ECR
- **Docker**: Nginx containerizado
- **GitHub Actions**: CI/CD Pipeline
- **CloudWatch**: Monitoramento e logs

## 📁 Estrutura do Projeto

```
tx01/
├── terraform/
│   ├── stg/                    # Configuração Staging
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars
│   ├── prd/                    # Configuração Production
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars
│   ├── modules/                # Módulos reutilizáveis
│   │   ├── vpc.tf
│   │   ├── security_groups.tf
│   │   ├── ec2.tf
│   │   ├── alb.tf
│   │   ├── ecr.tf
│   │   └── waf.tf
│   ├── provider.tf
│   ├── variables.tf
│   └── user_data.sh
├── docker/
│   ├── Dockerfile
│   ├── nginx.conf
│   ├── default.conf
│   └── .dockerignore
├── .github/workflows/
│   ├── docker-build.yml
│   ├── terraform-validate.yml
│   └── deploy.yml
└── README.md
```

## 🚀 Início Rápido

### 1. Clonar
```bash
git clone https://github.com/maringelix/tx01.git
cd tx01
```

### 2. Configurar AWS
```bash
aws configure
# Digite suas credenciais AWS
```

### 3. Deploy Staging
```bash
cd terraform/stg
terraform init
terraform plan
terraform apply
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
