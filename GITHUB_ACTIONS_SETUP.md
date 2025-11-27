# 🔐 GitHub Actions Setup - AWS Credentials & Secrets

Este guia orienta como configurar credenciais AWS no GitHub para o Terraform CI/CD funcionar corretamente.

## 📋 Pré-requisitos

- ✅ Conta AWS com usuário IAM `devops-tx01` (já criado)
- ✅ Permissões IAM aplicadas (via `AWS_IAM_POLICY.json`)
- ✅ Acesso de administrador no GitHub repositório `maringelix/tx01`

---

## 🔑 Opção 1: GitHub Actions com IAM User + Access Keys (Simples)

### Passo 1: Gerar Access Keys para `devops-tx01`

1. Acesse **AWS Console** → IAM → Users → `devops-tx01`
2. Aba **Security credentials** → **Access keys** → **Create access key**
3. Escolha **Application running outside AWS**
4. Copie:
   - `Access Key ID`
   - `Secret Access Key`

⚠️ **NUNCA compartilhe essas chaves. Guarde-as com segurança.**

### Passo 2: Adicionar Secrets no GitHub

1. Acesse seu repositório: **https://github.com/maringelix/tx01**
2. **Settings** → **Secrets and variables** → **Actions**
3. Clique **New repository secret** e adicione:

```
Name: AWS_ACCESS_KEY_ID
Value: <Cole aqui seu Access Key ID>
```

```
Name: AWS_SECRET_ACCESS_KEY
Value: <Cole aqui seu Secret Access Key>
```

### Passo 3: Atualizar o Workflow

Edite `.github/workflows/terraform-deploy.yml` e substitua:

```yaml
- name: 🔑 Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    aws-region: ${{ env.AWS_REGION }}
```

**Vantagem:** Simples de configurar  
**Desvantagem:** Credenciais em texto (menos seguro)

---

## 🚀 Opção 2: GitHub Actions com OIDC (Recomendado - Profissional)

### O que é OIDC?

OpenID Connect permite que GitHub Actions assuma uma role IAM **temporária** sem armazenar credenciais permanentes. É mais seguro.

### Passo 1: Criar IAM Role para GitHub Actions

Execute este comando AWS CLI (com credenciais admin):

```bash
aws iam create-role \
  --role-name GitHubActionsRole \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Federated": "arn:aws:iam::894222083614:oidc-provider/token.actions.githubusercontent.com"
        },
        "Action": "sts:AssumeRoleWithWebIdentity",
        "Condition": {
          "StringEquals": {
            "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
          },
          "StringLike": {
            "token.actions.githubusercontent.com:sub": "repo:maringelix/tx01:ref:refs/heads/main"
          }
        }
      }
    ]
  }'
```

### Passo 2: Anexar Policy à Role

```bash
aws iam attach-role-policy \
  --role-name GitHubActionsRole \
  --policy-arn arn:aws:iam::894222083614:policy/devops-tx01
```

### Passo 3: Adicionar Secret no GitHub

1. **Settings** → **Secrets and variables** → **Actions**
2. **New repository secret:**

```
Name: AWS_ROLE_TO_ASSUME
Value: arn:aws:iam::894222083614:role/GitHubActionsRole
```

### Passo 4: Workflow já está configurado!

O arquivo `.github/workflows/terraform-deploy.yml` já usa OIDC por padrão.

**Vantagem:** Mais seguro, sem credenciais permanentes  
**Desvantagem:** Requer config extra de OIDC (vale a pena para produção)

---

## 🧪 Testar o Workflow

### Teste 1: Plan em Staging

1. Acesse **GitHub** → **Actions**
2. Selecione **🚀 Terraform Deploy (STG/PRD)**
3. **Run workflow**
4. Escolha:
   - Environment: `stg`
   - Action: `plan`
5. Clique **Run workflow**

Verifique se o plano foi gerado sem erros.

### Teste 2: Apply em Staging

Repita o teste 1, mas escolha `apply` em **Action**.

---

## 📊 Ambientes (Environment) no GitHub

Opcionalmente, configure ambientes separados para STG e PRD com aprovadores:

1. **Settings** → **Environments** → **New environment**
2. Nome: `stg` (ou `prd`)
3. **Required reviewers**: adicione seus colaboradores
4. **Deployment branches**: `main` (or specific branches)

Agora ao fazer deploy em PRD, será necessária aprovação manual de um reviewer.

---

## 🛠️ Comandos Manuais (para referência)

Se precisar rodar Terraform localmente:

```bash
# Staging
cd terraform/stg
terraform init
terraform plan
terraform apply

# Production
cd terraform/prd
terraform init
terraform plan
terraform apply
```

---

## 🚨 Segurança - Checklist

- [ ] Credenciais AWS estão em GitHub **Secrets** (não em arquivos)
- [ ] Access Keys possuem permissões mínimas (via `AWS_IAM_POLICY.json`)
- [ ] OIDC está configurado (Opção 2 - profissional)
- [ ] Workflow tem aprovação manual para PRD
- [ ] State está em S3 com versioning (já feito)
- [ ] Logs de deploy são salvos no GitHub (rastreabilidade)

---

## 🆘 Troubleshooting

### Erro: "User is not authorized to perform"
→ Verifique se a policy `AWS_IAM_POLICY.json` foi aplicada ao usuário IAM

### Erro: "S3 backend not found"
→ Bootstrap não foi executado. Rode primeiro:
```bash
cd terraform/bootstrap && terraform apply
```

### Erro: "Assume role failed"
→ OIDC Trust Relationship incorreta. Verifique ARN da role.

---

## 📚 Referências

- [AWS OIDC Provider](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
- [Terraform Backend S3](https://www.terraform.io/language/settings/backends/s3)
- [GitHub Actions Environments](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment)

---

**Próximo passo:** Escolha uma opção acima e configure. Qualquer dúvida, execute as instruções e avise do resultado! 🚀
