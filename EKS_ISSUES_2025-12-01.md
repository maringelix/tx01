# Problemas e Soluções - EKS Cluster TX01

## Data: 01/12/2025

### ⚠️ Problemas Identificados

#### 1. IAM Principal sem permissões Kubernetes RBAC
**Sintoma:**
```
Your current IAM principal doesn't have access to Kubernetes objects on this cluster.
This may be due to the current user or role not having Kubernetes RBAC permissions to 
describe cluster resources or not having an entry in the cluster's auth config map.
```

**Causa:** O usuário IAM `devops-tx01` não estava mapeado no ConfigMap `aws-auth` do Kubernetes, que controla o acesso RBAC ao cluster.

**Solução Imediata:**
```bash
kubectl patch configmap aws-auth -n kube-system --patch @"
data:
  mapRoles: |
    - rolearn: arn:aws:iam::894222083614:role/tx01-eks-node-role-stg
      groups:
      - system:bootstrappers
      - system:nodes
      username: system:node:{{EC2PrivateDNSName}}
  mapUsers: |
    - userarn: arn:aws:iam::894222083614:user/devops-tx01
      username: devops-tx01
      groups:
      - system:masters
"@
```

**Solução Permanente (Terraform):**
- Criado resource `kubernetes_config_map` em `terraform/modules/eks.tf`
- Adicionadas variáveis `iam_user_arn` e `iam_user_name` 
- ConfigMap agora é provisionado automaticamente com mapeamento de IAM roles (nodes) e users (admin)

---

#### 2. Kubernetes Version 1.28 Não Suportada
**Sintoma:**
```
⚠️ The Kubernetes version on your cluster is no longer supported by Amazon EKS.
Upgrade your Kubernetes cluster to a supported version.
```

**Causa:** A versão 1.28 do Kubernetes atingiu o fim do suporte pela AWS EKS.

**Versões Suportadas (Dezembro 2025):**
- ✅ Kubernetes 1.31 (mais recente)
- ✅ Kubernetes 1.30
- ✅ Kubernetes 1.29
- ❌ Kubernetes 1.28 (não suportada)

**Solução:**
- Atualizado `terraform/modules/eks.tf` linha 7: `version = "1.31"`
- Próxima aplicação do Terraform criará cluster com versão suportada

---

### 📋 Arquivos Modificados

#### 1. `terraform/modules/eks.tf`
- **Linha 7:** Atualizada versão de `1.28` → `1.31`
- **Linhas 283-318:** Adicionado resource `kubernetes_config_map` para aws-auth

#### 2. `terraform/modules/variables.tf`
- **Linhas 151-162:** Adicionadas variáveis:
  ```hcl
  variable "iam_user_arn" {
    description = "ARN of the IAM user to grant Kubernetes access"
    type        = string
    default     = ""
  }

  variable "iam_user_name" {
    description = "Name of the IAM user to grant Kubernetes access"
    type        = string
    default     = ""
  }
  ```

#### 3. `terraform/modules/provider.tf` (NOVO)
- Adicionado provider Kubernetes para gerenciar recursos K8s via Terraform
- Configurado para autenticar usando AWS CLI (`aws eks get-token`)

#### 4. `terraform/stg/variables.tf`
- **Linhas 77-88:** Adicionadas mesmas variáveis de IAM user

#### 5. `terraform/stg/terraform.tfvars`
- **Linhas 17-18:** Configurados valores:
  ```hcl
  iam_user_arn  = "arn:aws:iam::894222083614:user/devops-tx01"
  iam_user_name = "devops-tx01"
  ```

#### 6. `terraform/stg/main.tf`
- **Linhas 42-44:** Passadas variáveis IAM para o módulo

---

### ✅ Status Atual

**Cluster EKS:**
- Nome: `tx01-eks-stg`
- Status: `ACTIVE`
- Versão: `1.28` (precisa upgrade)
- Endpoint: `https://EABBBD15677D0612BC141D01FE71992B.gr7.us-east-1.eks.amazonaws.com`

**Nodes:**
- 2 nodes t3.small em zonas us-east-1a e us-east-1b
- Status: `Ready`
- Container Runtime: containerd 1.7.27

**Pods:**
- 2 pods `tx01-app` rodando
- Status: `Running` (1/1)
- IPs: 10.0.11.229 e 10.0.10.188

**IAM/RBAC:**
- ✅ Usuário `devops-tx01` adicionado ao ConfigMap aws-auth
- ✅ Grupo: `system:masters` (acesso total)
- ✅ Problema de permissões resolvido

---

### 🔧 Próximos Passos

#### Opção 1: Upgrade In-Place (Recomendado para Produção)
```bash
# 1. Fazer backup do cluster
aws eks describe-cluster --name tx01-eks-stg --region us-east-1 > cluster-backup.json

# 2. Upgrade para 1.29 (incremental)
aws eks update-cluster-version --name tx01-eks-stg --kubernetes-version 1.29 --region us-east-1

# 3. Aguardar upgrade completar (15-30 minutos)
aws eks describe-update --name tx01-eks-stg --update-id <update-id> --region us-east-1

# 4. Upgrade node group
aws eks update-nodegroup-version --cluster-name tx01-eks-stg \
  --nodegroup-name tx01-ng-stg --region us-east-1

# 5. Repetir para 1.30, depois 1.31
```

**⚠️ Downtime:** ~30-60 minutos durante rolling update dos nodes

---

#### Opção 2: Recreate Cluster via Terraform (Mais Rápido)
```bash
# 1. Salvar dados importantes (se houver)
kubectl get all --all-namespaces -o yaml > cluster-state-backup.yaml

# 2. Destroy cluster atual
cd terraform/stg
terraform destroy -target=module.infrastructure.aws_eks_cluster.main \
                 -target=module.infrastructure.aws_eks_node_group.main

# 3. Aplicar com nova versão (1.31)
terraform apply

# 4. Reconfigurar kubeconfig
aws eks update-kubeconfig --name tx01-eks-stg --region us-east-1

# 5. Reinstalar ALB Controller
# (executar workflow eks-deploy.yml action=provision)

# 6. Redeploy aplicação
# (executar workflow eks-deploy.yml action=deploy)
```

**✅ Vantagens:** 
- Mais rápido (15-20 minutos)
- Garante configuração limpa
- ConfigMap aws-auth já será criado corretamente

**⚠️ Downtime:** ~20 minutos (cluster indisponível durante recreate)

---

### 📊 Comparação de Opções

| Aspecto | Upgrade In-Place | Recreate Cluster |
|---------|-----------------|------------------|
| **Tempo Total** | 60-90 minutos | 20-30 minutos |
| **Downtime** | 30-60 minutos | 20 minutos |
| **Risco** | Baixo | Médio |
| **Rollback** | Difícil | Fácil (Terraform) |
| **Estado Preservado** | Sim | Não |
| **ConfigMap aws-auth** | Manual | Automático |
| **Melhor para** | Produção | Dev/Staging |

---

### 🎯 Recomendação

Como estamos em **ambiente staging** e o cluster foi criado recentemente (3 horas atrás):

**✅ RECOMENDADO: Opção 2 (Recreate)**

**Motivos:**
1. Cluster novo sem dados críticos
2. Mais rápido e simples
3. ConfigMap aws-auth será criado automaticamente
4. Testa o fluxo completo de provisionamento

---

### 📝 Comandos Úteis

```bash
# Verificar versões disponíveis
aws eks describe-addon-versions --kubernetes-version 1.31 --region us-east-1

# Verificar permissões RBAC atuais
kubectl auth can-i '*' '*' --all-namespaces

# Listar recursos do cluster
kubectl api-resources

# Verificar logs do ALB Controller
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Testar conectividade com a aplicação
kubectl run test-pod --image=busybox --rm -it -- wget -O- http://tx01-app:80/api/health
```

---

### 🔗 Referências

- [Amazon EKS Kubernetes Versions](https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html)
- [EKS Cluster Upgrades](https://docs.aws.amazon.com/eks/latest/userguide/update-cluster.html)
- [Managing users or IAM roles for your cluster](https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html)
- [aws-auth ConfigMap Reference](https://docs.aws.amazon.com/eks/latest/userguide/auth-configmap.html)

---

**Commit:** 03a66c7  
**Data:** 01/12/2025  
**Autor:** DevOps Team
