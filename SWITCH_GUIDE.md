# 🔄 Guia de Switch Entre EC2 e EKS

## 📋 Resumo

Este guia explica como alternar entre os modos EC2 e EKS no ambiente tx01.

---

## ⚠️ **IMPORTANTE - Use o Workflow V2**

Existem 2 workflows disponíveis:
- ❌ **switch-environment.yml** (v1) - OBSOLETO - tenta gerenciar ALB manualmente
- ✅ **switch-environment-v2.yml** (v2) - RECOMENDADO - deixa o Ingress Controller trabalhar

**Use sempre o V2!**

URL: https://github.com/maringelix/tx01/actions/workflows/switch-environment-v2.yml

---

## 🏗️ **Arquitetura**

### **Modo EC2:**
```
Internet → ALB (tx01-alb-stg) → Target Group (EC2) → 2x EC2 instances (porta 8080)
```
- ALB criado pelo Terraform
- Target Group tipo `instance`
- EC2 executam containers Docker

### **Modo EKS:**
```
Internet → ALB (gerenciado pelo Ingress Controller) → Target Group (IP) → Pods (porta 80)
```
- ALB criado automaticamente pelo AWS Load Balancer Controller
- Target Group tipo `ip` (gerenciado automaticamente)
- Pods executam containers no Kubernetes

---

## 🔄 **Como Funciona o Switch**

### **EC2 → EKS:**

1. ✅ Escala deployment EKS para 2 réplicas
2. ⏳ Aguarda pods ficarem prontos (5 min timeout)
3. 📋 Verifica status do Ingress
4. 🛑 Para as instâncias EC2 (para economizar)
5. ✅ Aplicação agora responde via ALB do Ingress

**Resultado:**
- EC2: **stopped** (não cobra por instância, só por storage)
- EKS: **2 pods running**
- Custo: ~$138/mês

### **EKS → EC2:**

1. 📉 Escala deployment EKS para 0 réplicas
2. ▶️  Inicia as instâncias EC2
3. ⏳ Aguarda instâncias ficarem running
4. ✅ Aplicação agora responde via ALB original

**Resultado:**
- EC2: **running** (2 instâncias)
- EKS: **0 pods** (nodes continuam ligados)
- Custo: ~$50/mês (EC2) + ~$88/mês (EKS nodes idle) = ~$138/mês

---

## 🎯 **Executar o Switch**

### **1. Acessar o workflow:**
```
https://github.com/maringelix/tx01/actions/workflows/switch-environment-v2.yml
```

### **2. Clicar em "Run workflow"**

### **3. Selecionar parâmetros:**
- **Environment:** `stg` ou `prd`
- **Mode:** 
  - `ec2` - Ativa EC2, desativa EKS
  - `eks` - Ativa EKS, desativa EC2

### **4. Confirmar "Run workflow"**

⏱️ **Tempo estimado:**
- EC2 → EKS: ~3-5 minutos
- EKS → EC2: ~2-3 minutos

---

## 📊 **Verificar Status**

### **Após switch para EKS:**

O workflow mostrará algo como:
```
✅ Pods are ready

📋 Pods status:
NAME                        READY   STATUS    RESTARTS   AGE   IP
tx01-app-58d844d8bd-abc12   1/1     Running   0          2m    10.0.11.123
tx01-app-58d844d8bd-xyz34   1/1     Running   0          2m    10.0.11.124

📋 Ingress status:
NAME           CLASS   HOSTS   ADDRESS                                           PORTS
tx01-ingress   alb     *       k8s-default-tx01ingr-abc123.us-east-1.elb.amazonaws.com   80

✅ ALB managed by Ingress Controller is ready
   DNS: k8s-default-tx01ingr-abc123.us-east-1.elb.amazonaws.com
```

**Acesse via:** `http://k8s-default-tx01ingr-abc123.us-east-1.elb.amazonaws.com`

⚠️ **Nota:** O DNS do ALB do Ingress pode levar 2-3 minutos para propagar e health checks passarem.

### **Após switch para EC2:**

```
✅ EC2 instances are now running

🎯 Your application is now running on EC2!
   Access via: http://tx01-alb-stg-1968751478.us-east-1.elb.amazonaws.com
```

**Acesse via:** `http://tx01-alb-stg-1968751478.us-east-1.elb.amazonaws.com`

---

## ❓ **Por Que Existem 2 ALBs?**

### **ALB 1: tx01-alb-stg** (Terraform)
- Criado pelo Terraform
- Usado para EC2 instances
- Target Group tipo `instance`
- Permanece ativo mesmo com EKS

### **ALB 2: k8s-default-tx01ingr-*** (Ingress Controller)
- Criado automaticamente pelo AWS Load Balancer Controller
- Gerenciado pelo recurso Ingress do Kubernetes
- Target Group tipo `ip` (pods)
- Criado/destruído conforme Ingress existe

**É normal ter 2 ALBs!** Cada um serve um propósito diferente.

---

## 💰 **Custos**

| Modo | EC2 | EKS Control Plane | EKS Nodes | Total/mês |
|------|-----|-------------------|-----------|-----------|
| EC2 only | ✅ $50 (running) | ✅ $73 | ✅ $60 (idle) | ~$183 |
| EKS only | ⏸️ $8 (stopped) | ✅ $73 | ✅ $60 (active) | ~$141 |

**Economia real:**
- Para economizar de verdade, você precisa **destruir o cluster EKS** quando não usar
- Apenas escalar pods para 0 não economiza muito (nodes continuam rodando)
- Parar EC2 economiza ~$42/mês

---

## 🔧 **Troubleshooting**

### **Pods não ficam prontos:**
```bash
# Ver logs dos pods
kubectl logs -l app=tx01 --tail=50

# Ver eventos
kubectl get events --sort-by=.metadata.creationTimestamp

# Ver status detalhado
kubectl describe pods -l app=tx01
```

### **Ingress não cria ALB:**
```bash
# Ver logs do ALB Controller
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Ver status do Ingress
kubectl describe ingress tx01-ingress
```

### **Health checks falhando:**
```bash
# Verificar se pods respondem na porta 80
kubectl port-forward pod/tx01-app-xxx 8080:80

# No navegador: http://localhost:8080
```

### **EC2 não inicia:**
```bash
# Ver estado das instâncias
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=tx01-ec2-*-stg" \
  --query 'Reservations[].Instances[].[InstanceId,State.Name,StateReason.Message]'
```

---

## ✅ **Validações Antes do Switch**

### **Antes de EKS → EC2:**
- ✅ EC2 instances existem (não foram terminadas)
- ✅ ALB original (tx01-alb-stg) está ativo
- ✅ Target Group EC2 está saudável

### **Antes de EC2 → EKS:**
- ✅ Cluster EKS está ACTIVE
- ✅ Node group tem nodes disponíveis
- ✅ Deployment tx01-app existe
- ✅ Ingress tx01-ingress existe
- ✅ ALB Controller está rodando

---

## 📝 **Comandos Úteis**

### **Verificar estado atual:**
```bash
# EC2 instances
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=tx01-ec2-*-stg" "Name=instance-state-name,Values=running,stopped" \
  --query 'Reservations[].Instances[].[InstanceId,State.Name,Tags[?Key==`Name`].Value|[0]]' \
  --output table

# EKS deployment
kubectl get deployment tx01-app
kubectl get pods -l app=tx01

# Ingress
kubectl get ingress tx01-ingress -o wide
```

### **Switch manual (caso workflow falhe):**

**Para EKS:**
```bash
# Escalar pods
kubectl scale deployment tx01-app --replicas=2
kubectl wait --for=condition=ready pod -l app=tx01 --timeout=300s

# Parar EC2
aws ec2 stop-instances --instance-ids i-xxx i-yyy
```

**Para EC2:**
```bash
# Escalar pods para 0
kubectl scale deployment tx01-app --replicas=0

# Iniciar EC2
aws ec2 start-instances --instance-ids i-xxx i-yyy
aws ec2 wait instance-running --instance-ids i-xxx i-yyy
```

---

## 🎓 **Lições Aprendidas**

### **❌ O que NÃO fazer:**
1. **Não registre pods manualmente em target groups** - O Ingress Controller faz isso automaticamente
2. **Não crie target groups separados para EKS** - O Ingress Controller cria dinamicamente
3. **Não manipule listener rules manualmente** - O Ingress Controller gerencia isso
4. **Não use kubectl versão diferente do cluster** - Use v1.32.0 para cluster v1.32

### **✅ O que fazer:**
1. **Confie no Ingress Controller** - Deixe ele gerenciar ALB, target groups e routing
2. **Apenas escale os pods** - O resto é automático
3. **Monitore o Ingress** - `kubectl get ingress -w` mostra quando o ALB está pronto
4. **Use o workflow V2** - Mais simples, mais confiável

---

## 🔗 **Links Úteis**

- Workflow V2: https://github.com/maringelix/tx01/actions/workflows/switch-environment-v2.yml
- EKS Deploy: https://github.com/maringelix/tx01/actions/workflows/eks-deploy.yml
- ALB Controller Docs: https://kubernetes-sigs.github.io/aws-load-balancer-controller/

---

**Última atualização:** 2025-12-04
