# 📝 EKS Upgrade Notes - Dezembro 2025

## 🎯 Atualização Realizada

### Versões Atualizadas

| Componente | Versão Anterior | Versão Nova | Status |
|------------|----------------|-------------|--------|
| Kubernetes | 1.28 (Extended Support) | **1.32** (Standard Support) | ✅ |
| kubectl | 1.28.0 | **1.32.0** | ✅ |
| Kubernetes Provider | ~> 2.24 | **~> 2.35** | ✅ |
| AWS Load Balancer Controller | latest | **1.10.1** | ✅ |
| VPC CNI Add-on | - | **v1.19.0-eksbuild.1** | ✅ Novo |
| kube-proxy Add-on | - | **v1.32.0-eksbuild.2** | ✅ Novo |
| CoreDNS Add-on | - | **v1.11.3-eksbuild.2** | ✅ Novo |

### ⚠️ Motivo da Atualização

**Kubernetes 1.28 entrou em Extended Support em Novembro 2024:**
- Standard Support: Agosto 2023 - Novembro 2024
- Extended Support: Novembro 2024 - Novembro 2025
- **Custo adicional**: Extended Support cobra extra por cluster/hora
- **Risco**: Após Novembro 2025, auto-upgrade forçado

**Kubernetes 1.32 está em Standard Support:**
- Lançamento: Dezembro 2024
- End of Standard Support: Março 2026
- End of Extended Support: Março 2027
- **Sem custo adicional** até Março 2026

## 🚀 Novas Funcionalidades

### 1. Nova Action: `plan` no eks-deploy.yml

Agora você pode fazer **Terraform Plan** antes de aplicar:

```bash
# No GitHub Actions
Action: plan
Environment: stg ou prd
```

Isso permite validar mudanças antes de aplicar no EKS.

### 2. EKS Add-ons Gerenciados

Adicionados 3 add-ons gerenciados pela AWS:
- **VPC CNI**: Networking de pods
- **kube-proxy**: Proxy de rede do Kubernetes
- **CoreDNS**: Resolução DNS no cluster

**Benefícios:**
- ✅ Atualizações automáticas de segurança
- ✅ Compatibilidade garantida com a versão do EKS
- ✅ Reduz manutenção manual

## 📋 Configurações Atualizadas

### terraform.tfvars

Novos parâmetros adicionados em `stg` e `prd`:

```hcl
# EKS Configuration
enable_eks              = false  # Set to true when ready to provision EKS
eks_node_instance_type  = "t3.medium"  # Minimum recommended for EKS nodes
eks_node_desired_size   = 2
eks_node_min_size       = 1
eks_node_max_size       = 4
```

### Instance Type Recomendado

- ❌ `t3.micro`: Muito pequeno para EKS nodes
- ✅ `t3.medium`: **Mínimo recomendado** (2 vCPU, 4GB RAM)
- ✅ `t3.large`: Para workloads maiores

## 🔄 Fluxo de Deploy EKS

### 1. Terraform Plan (Novo!)

```bash
# Via GitHub Actions
Actions → ☸️ EKS Deploy
Environment: stg
Action: plan
```

Valida as mudanças sem aplicar.

### 2. Provision (Criar Cluster)

```bash
# Via GitHub Actions
Actions → ☸️ EKS Deploy
Environment: stg
Action: provision
```

Isso vai:
1. ✅ Criar cluster EKS 1.32
2. ✅ Criar node group com t3.medium
3. ✅ Instalar add-ons (VPC CNI, kube-proxy, CoreDNS)
4. ✅ Configurar OIDC provider
5. ✅ Instalar AWS Load Balancer Controller 1.10.1
6. ✅ Configurar kubeconfig

### 3. Deploy (Aplicação)

```bash
# Via GitHub Actions
Actions → ☸️ EKS Deploy
Environment: stg
Action: deploy
```

Isso vai:
1. ✅ Aplicar manifests K8s
2. ✅ Criar ingress conectado ao ALB existente
3. ✅ Configurar secrets (database, ECR)
4. ✅ Deploy da aplicação TX01

### 4. Switch Environment

```bash
# Via GitHub Actions
Actions → 🔄 Switch Environment
Environment: stg
Mode: eks
```

Isso vai:
1. ✅ Desregistrar EC2 instances do ALB
2. ✅ Registrar EKS pods no ALB
3. ✅ Parar EC2 instances (economia de custo)

### 5. Destroy (Remover EKS)

```bash
# Via GitHub Actions
Actions → ☸️ EKS Deploy
Environment: stg
Action: destroy
```

Isso vai:
1. ✅ Limpar recursos Kubernetes
2. ✅ Remover Load Balancer Controller
3. ✅ Destruir add-ons
4. ✅ Destruir node group
5. ✅ Destruir cluster EKS
6. ✅ **Não afeta EC2 instances**

## ⚠️ Pontos de Atenção

### 1. Custo Adicional

**Novo custo com EKS:**
- EKS Control Plane: **$0.10/hora** = ~$73/mês
- EKS Nodes (2x t3.medium): **$0.0416/hora cada** = ~$60/mês
- **Total adicional: ~$133/mês**

**Economia ao desligar EC2:**
- 2x EC2 t3.micro: ~$17/mês (Free Tier por 12 meses)
- Líquido: **~$116/mês adicional**

### 2. Ordem de Provisionamento

**IMPORTANTE**: Sempre provisionar nesta ordem:

1. ✅ Infraestrutura base (VPC, ALB, RDS, ECR) - **Já feito**
2. ✅ EKS Provision - **Novo**
3. ✅ EKS Deploy - **Novo**
4. ✅ Switch Environment - **Quando quiser migrar**

### 3. Rollback para EC2

Se precisar voltar para EC2:

```bash
# Via GitHub Actions
Actions → 🔄 Switch Environment
Environment: stg
Mode: ec2
```

Isso vai:
1. ✅ Desregistrar EKS pods do ALB
2. ✅ Registrar EC2 instances no ALB
3. ✅ Iniciar EC2 instances

### 4. Target Groups

O switch-environment gerencia 2 target groups:
- `tx01-tg-stg`: Para EC2 instances (porta 8080)
- `tx01-tg-eks-stg`: Para EKS pods (porta 80)

O ALB listener aponta para um ou outro conforme o modo.

## 🧪 Validação Pós-Deploy

### Verificar Cluster

```bash
aws eks list-clusters --region us-east-1

aws eks describe-cluster --name tx01-eks-stg --region us-east-1
```

### Verificar Nodes

```bash
kubectl get nodes -o wide

kubectl describe nodes
```

### Verificar Add-ons

```bash
aws eks list-addons --cluster-name tx01-eks-stg --region us-east-1

aws eks describe-addon --cluster-name tx01-eks-stg --addon-name vpc-cni --region us-east-1
```

### Verificar ALB Controller

```bash
kubectl get deployment -n kube-system aws-load-balancer-controller

kubectl logs -n kube-system deployment/aws-load-balancer-controller --tail=20
```

### Verificar Aplicação

```bash
kubectl get pods

kubectl get svc

kubectl get ingress

kubectl describe ingress tx01-ingress
```

## 📚 Referências

- [AWS EKS Versions](https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html)
- [EKS Add-ons](https://docs.aws.amazon.com/eks/latest/userguide/eks-add-ons.html)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)

## 🎯 Próximos Passos Recomendados

1. **Testar em STG primeiro**
   - Fazer plan
   - Provision
   - Deploy
   - Validar aplicação
   - Testar switch entre EC2 e EKS

2. **Monitorar custos**
   - AWS Cost Explorer
   - Configurar alarmes de billing

3. **Considerar otimizações futuras**
   - Spot instances para nodes
   - Fargate para workloads específicos
   - Cluster Autoscaler ou Karpenter

4. **Implementar em PRD**
   - Após validação completa em STG
   - Planejar janela de manutenção
   - Documentar rollback

---

**Data da Atualização**: Dezembro 3, 2025  
**Versão**: 1.32  
**Status**: ✅ Pronto para uso
