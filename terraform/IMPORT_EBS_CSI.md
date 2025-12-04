# 📦 Importação do EBS CSI Driver para Terraform

## 📋 Visão Geral

Este guia documenta como importar os recursos do **EBS CSI Driver** que foram criados manualmente para o gerenciamento do Terraform, mantendo o ambiente profissional e totalmente como código.

## 🎯 Recursos Adicionados ao Terraform

### 1. **OIDC Provider** (`aws_iam_openid_connect_provider.eks`)
- Necessário para IRSA (IAM Roles for Service Accounts)
- Permite que pods do Kubernetes assumam IAM roles
- **Localização:** `terraform/modules/eks.tf`

### 2. **IAM Role** (`aws_iam_role.ebs_csi_driver`)
- Role usada pelo EBS CSI Driver
- Configurada com trust policy para OIDC
- **Nome:** `tx01-eks-ebs-csi-driver`

### 3. **IAM Policy Attachment** (`aws_iam_role_policy_attachment.ebs_csi_driver_policy`)
- Anexa `AmazonEBSCSIDriverPolicy` à role
- Permite criação/gerenciamento de volumes EBS

### 4. **EKS Addon** (`aws_eks_addon.ebs_csi_driver`)
- Addon `aws-ebs-csi-driver` versão `v1.53.0-eksbuild.1`
- Vinculado à service account via `service_account_role_arn`

## 🚀 Como Importar

### Opção 1: Via GitHub Actions (Recomendado)

1. Acesse: https://github.com/maringelix/tx01/actions/workflows/terraform-import-ebs-csi.yml
2. Clique em **"Run workflow"**
3. Selecione o environment: `stg`
4. Clique em **"Run workflow"** (botão verde)
5. Aguarde ~2 minutos
6. Verifique o output - deve mostrar ✅ para cada recurso importado

### Opção 2: Localmente (Requer Terraform instalado)

#### Windows (PowerShell):
```powershell
cd terraform/stg
.\import-ebs-csi.ps1
```

#### Linux/macOS (Bash):
```bash
cd terraform/stg
chmod +x import-ebs-csi.sh
./import-ebs-csi.sh
```

## ✅ Verificação Pós-Import

Após o import, você deve:

1. **Verificar o Terraform Plan:**
   ```bash
   cd terraform/stg
   terraform plan
   ```
   
   **Resultado esperado:** "No changes. Your infrastructure matches the configuration."

2. **Verificar recursos no state:**
   ```bash
   terraform state list | grep -E "ebs_csi|oidc"
   ```
   
   **Deve mostrar:**
   - `module.infrastructure.aws_iam_openid_connect_provider.eks[0]`
   - `module.infrastructure.aws_iam_role.ebs_csi_driver[0]`
   - `module.infrastructure.aws_iam_role_policy_attachment.ebs_csi_driver_policy[0]`
   - `module.infrastructure.aws_eks_addon.ebs_csi_driver[0]`

## 🔄 Workflow de Observabilidade Atualizado

O workflow `deploy-observability.yml` foi atualizado para:

1. ✅ **Verificar** se o EBS CSI Driver existe
2. ✅ **Criar automaticamente** se não existir
3. ✅ **Aguardar** ficar ACTIVE antes de continuar
4. ✅ **Idempotente** - pode rodar múltiplas vezes

Isso garante que novos ambientes (como `prd`) terão o EBS CSI Driver instalado automaticamente.

## 💡 Benefícios

### Antes (Manual):
- ❌ Recursos criados fora do Terraform
- ❌ Estado dessinc
ronizado
- ❌ Difícil de replicar em outros ambientes
- ❌ Não versionado

### Depois (Terraform):
- ✅ Tudo como código
- ✅ State sincronizado
- ✅ Fácil de replicar
- ✅ Versionado no Git
- ✅ Profissional e auditável

## 🛡️ Segurança

- **IRSA (IAM Roles for Service Accounts):** Pods não usam credenciais fixas
- **Least Privilege:** Role tem apenas as permissões necessárias
- **OIDC:** Autenticação segura via tokens JWT

## 📝 Próximos Passos para PRD

Quando criar o ambiente de produção:

1. O EKS cluster será criado via Terraform (já inclui EBS CSI Driver)
2. OU o workflow de observabilidade instalará automaticamente
3. Não precisa fazer nada manual! 🎉

## 🔧 Troubleshooting

### Erro: "Resource already imported"
**Solução:** Normal! Significa que o recurso já está no state. Continue.

### Erro: "Resource not found"
**Solução:** Verifique se os recursos existem na AWS:
```bash
aws eks describe-addon --cluster-name tx01-eks-stg --addon-name aws-ebs-csi-driver --region us-east-1
aws iam get-role --role-name tx01-eks-ebs-csi-driver
```

### Terraform Plan mostra mudanças após import
**Causa:** Pequenas diferenças de configuração
**Solução:** Revise as mudanças e aplique se necessário:
```bash
terraform apply
```

## 📚 Referências

- [EBS CSI Driver Documentation](https://github.com/kubernetes-sigs/aws-ebs-csi-driver)
- [EKS IRSA Documentation](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)
- [Terraform Import](https://www.terraform.io/docs/cli/import/index.html)

## ✨ Commits Relacionados

- `cc8e2d2` - feat(terraform): Add EBS CSI Driver and OIDC provider
- `1cd931a` - feat(workflow): Add Terraform import workflow
- `416eef7` - feat(observability): Add automatic EBS CSI Driver installation

---

**Status:** ✅ Pronto para import  
**Ambiente:** STG  
**Data:** 2025-12-04
