# Metrics Server - Instalação Condicional

## 📋 Visão Geral

O **Metrics Server** é instalado **condicionalmente** baseado no tipo de instância EKS configurado em `terraform.tfvars`.

## 🎯 Lógica Condicional

### ✅ **Instala Metrics Server**
- `t3.small` (2 vCPU, 2GB RAM) - 11 pods/node
- `t3.medium` (2 vCPU, 4GB RAM) - 17 pods/node  
- `t3.large` (2 vCPU, 8GB RAM) - 35 pods/node
- **Qualquer outro tipo maior**

### ⚠️ **NÃO Instala Metrics Server**
- `t3.micro` (2 vCPU, 1GB RAM) - **4 pods/node apenas**
- Limitação: Pod density muito baixo
- Metrics Server consome 2-3 pod slots + ~200MB RAM

## 🔧 Como Funciona no Workflow

### **Step 1: Check if Metrics Server should be installed**
```bash
# Lê o instance type do terraform.tfvars
INSTANCE_TYPE=$(grep "eks_node_instance_type" terraform/stg/terraform.tfvars | awk -F'"' '{print $2}')

# t3.micro = skip
# outros = install
```

### **Step 2: Install Metrics Server (conditional)**
```yaml
- name: Install Metrics Server
  if: steps.check-metrics.outputs.should_install == 'true'
  run: |
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

### **Step 3: Check if HPA should be deployed (conditional)**
```bash
# Verifica se metrics-server está rodando
METRICS_SERVER=$(kubectl get deployment metrics-server -n kube-system --ignore-not-found -o name)

# Se não encontrou = skip HPA
# Se encontrou = deploy HPA
```

### **Step 4: Deploy HPA (conditional)**
```yaml
- name: Deploy HPA
  if: steps.check-hpa.outputs.should_deploy == 'true'
  run: kubectl apply -f k8s/hpa.yaml
```

## 📊 Impacto nas Capacidades

### **Com Metrics Server (t3.small+)**
- ✅ HPA funciona automaticamente
- ✅ `kubectl top nodes` disponível
- ✅ `kubectl top pods` disponível
- ✅ Autoscaling baseado em CPU/Memory
- ❌ Consome ~200MB RAM
- ❌ Usa 2-3 pod slots

### **Sem Metrics Server (t3.micro)**
- ❌ HPA **não é deployado**
- ❌ `kubectl top` não funciona
- ✅ Mais pod slots para aplicação
- ✅ Economiza ~200MB RAM
- ✅ Escala manual com `kubectl scale deployment tx01-app --replicas=N`

## 🎛️ Escalabilidade Manual (t3.micro)

### **Aumentar replicas:**
```bash
kubectl scale deployment tx01-app --replicas=2 -n default
```

### **Diminuir replicas:**
```bash
kubectl scale deployment tx01-app --replicas=1 -n default
```

### **Verificar status:**
```bash
kubectl get pods -n default -l app=tx01
```

## 🔄 Mudança de Instance Type

### **Cenário: Upgrade de t3.micro → t3.small**

1. **Atualizar terraform.tfvars:**
   ```hcl
   eks_node_instance_type = "t3.small"
   ```

2. **Executar provision:**
   ```bash
   # GitHub Actions: eks-deploy.yml → provision
   ```

3. **Resultado automático:**
   - ✅ Metrics Server será instalado
   - ✅ HPA será deployado
   - ✅ Autoscaling ativado

### **Cenário: Downgrade de t3.small → t3.micro**

1. **Atualizar terraform.tfvars:**
   ```hcl
   eks_node_instance_type = "t3.micro"
   ```

2. **Executar provision:**
   ```bash
   # GitHub Actions: eks-deploy.yml → provision
   ```

3. **Resultado automático:**
   - ⚠️ Metrics Server **não** será instalado
   - ⚠️ HPA **não** será deployado
   - ℹ️ Escala manual necessária

## 🚨 Avisos no GitHub Actions

### **t3.micro detectado:**
```
⚠️ Skipping Metrics Server installation for t3.micro (pod density constraints)
⚠️ Skipping HPA deployment (Metrics Server not available for t3.micro)
```

### **t3.small+ detectado:**
```
✅ Will install Metrics Server for t3.small
✅ Will deploy HPA (Metrics Server available)
```

## 📝 Configuração Atual (Staging)

```hcl
# terraform/stg/terraform.tfvars
eks_node_instance_type = "t3.micro"
eks_node_desired_size  = 4
```

**Status:** Metrics Server e HPA **não serão instalados** nos próximos deploys automáticos.

## 🎓 Recomendações

### **Para Produção:**
- ✅ Use **mínimo t3.small** (2GB RAM)
- ✅ Metrics Server + HPA são **essenciais**
- ✅ Autoscaling baseado em métricas

### **Para Testes/Dev (t3.micro):**
- ⚠️ Aceite limitações de pod density
- ⚠️ Escale manualmente conforme necessário
- ⚠️ Monitore com `kubectl get pods` ao invés de `kubectl top`

## 🔗 Referências

- [T3_MICRO_OPTIMIZATIONS.md](T3_MICRO_OPTIMIZATIONS.md) - Limitações detalhadas
- [AWS EKS Pod Networking](https://docs.aws.amazon.com/eks/latest/userguide/pod-networking.html)
- [Metrics Server GitHub](https://github.com/kubernetes-sigs/metrics-server)
