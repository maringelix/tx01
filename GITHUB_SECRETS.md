# Guia de Configuração de GitHub Secrets

Este arquivo documenta todos os secrets necessários para o CI/CD funcionar corretamente.

## 🔐 Secrets Obrigatórios

### AWS Credentials
Necessários para deploy da infraestrutura e push para ECR.

#### 1. AWS_ACCESS_KEY_ID
- **Tipo**: Secret
- **Descrição**: Chave de acesso ID da AWS
- **Como obter**:
  1. Acesse [AWS Console](https://console.aws.amazon.com/)
  2. IAM → Users → Seu usuário
  3. Security credentials
  4. Create access key
  5. Command Line Interface (CLI)
  6. Copie o "Access Key ID"

#### 2. AWS_SECRET_ACCESS_KEY
- **Tipo**: Secret
- **Descrição**: Chave de acesso secreta da AWS
- **Como obter**:
  1. Mesmos passos acima
  2. Copie o "Secret Access Key"

### GitHub Container Registry (Opcional)
Se quiser usar GHCR em vez de ECR público.

#### GITHUB_TOKEN
- **Tipo**: Automático (disponível por padrão)
- **Descrição**: Token de autenticação do GitHub

## 🛠️ Como Adicionar Secrets

### Via GitHub UI
1. Vá para seu repositório
2. Settings → Secrets and variables → Actions
3. Click em "New repository secret"
4. Nome: `AWS_ACCESS_KEY_ID`
5. Value: Cole sua chave
6. Add secret
7. Repita para `AWS_SECRET_ACCESS_KEY`

### Via GitHub CLI
```bash
# Login no GitHub CLI (primeira vez)
gh auth login

# Adicionar secret
gh secret set AWS_ACCESS_KEY_ID --body "your-access-key-id"
gh secret set AWS_SECRET_ACCESS_KEY --body "your-secret-access-key"

# Listar secrets
gh secret list
```

## ⚙️ Configuração dos Workflows

### docker-build.yml
- Acionado em push para `main` ou `develop`
- Constrói imagem Docker
- Escaneia vulnerabilidades
- Faz push para GHCR e ECR

### terraform-validate.yml
- Acionado em push ou PR para `main` ou `develop`
- Valida sintaxe Terraform
- Executa TFLint
- Gera plano (enviado como comentário no PR)

### deploy.yml
- Staging: Deploy automático em push para `main`
- Production: Deploy manual via workflow_dispatch
- Requires AWS_ACCESS_KEY_ID e AWS_SECRET_ACCESS_KEY

## 🔒 Segurança dos Secrets

✅ **Boas práticas:**
- Nunca comite secrets no repositório
- Use IAM users específicos para CI/CD
- Rotacione chaves regularmente
- Use minimal permissions (princípio do menor privilégio)
- Revogue access keys não utilizadas

## 📋 Checklist de Setup

- [ ] AWS_ACCESS_KEY_ID adicionado
- [ ] AWS_SECRET_ACCESS_KEY adicionado
- [ ] Credenciais testadas com `aws sts get-caller-identity`
- [ ] Repositório GitHub criado
- [ ] Workflows visíveis em ".github/workflows"
- [ ] Branch protection rules configuradas (opcional)
- [ ] Ambientes (staging/production) criados (opcional)

## 🧪 Testar Secrets

```bash
# Clonar repositório
git clone https://github.com/seu-usuario/tx01.git
cd tx01

# Fazer pequena mudança
echo "# Test" >> README.md

# Commit e push
git add .
git commit -m "test: trigger workflows"
git push origin main

# Verificar Actions
# Abra https://github.com/seu-usuario/tx01/actions
```

## 🚨 Troubleshooting

### Erro: "InvalidClientTokenId"
- Chave de acesso inválida ou expirada
- Gere uma nova chave no IAM

### Erro: "UnauthorizedOperation"
- Usuário IAM sem permissões suficientes
- Adicione policy: `AdministratorAccess` ou role específica

### Erro: "AccessDenied"
- Verifique permissões IAM do usuário
- Necessário: EC2, VPC, IAM, ECR, ALB, WAF, CloudWatch

## 📚 Referências

- [GitHub Secrets Documentation](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [AWS IAM User Guide](https://docs.aws.amazon.com/iam/)
- [AWS Access Keys](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html)
