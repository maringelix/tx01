# Migração EKS - Guia Completo

## 📋 Visão Geral

Este guia descreve o processo de migração da aplicação TX01 de EC2 para Amazon EKS (Elastic Kubernetes Service), mantendo o ALB, RDS e Secrets Manager existentes.

## 🎯 Objetivos

- ✅ Provisionar cluster EKS com node groups gerenciados
- ✅ Reutilizar infraestrutura existente (ALB, RDS, Secrets Manager, ECR)
- ✅ Permitir switch entre EC2 e EKS para otimização de custos
- ✅ Implementar auto-scaling horizontal de pods (HPA)
- ✅ Manter zero downtime durante operações

## 💰 Comparativo de Custos

### Ambiente Staging

| Componente | EC2 Mode | EKS Mode | Both Active |
|------------|----------|----------|-------------|
| Compute | 2x t2.micro ($16) | EKS Control Plane ($73) + 2x t3.small ($30) | $119 |
| ALB | $16 | $16 | $16 |
| RDS | $13 | $13 | $13 |
| NAT Gateway | $32 | $32 | $32 |
| Data Transfer | ~$5 | ~$8 | ~$8 |
| **Total/mês** | **~$82** | **~$172** | **~$188** |

> **Nota**: Custos reais podem variar. EKS oferece melhor escalabilidade e gerenciamento.

## 🏗️ Arquitetura

### Arquitetura Híbrida (EC2 + EKS)

```
                          ┌─────────────────┐
                          │   Route 53 /    │
                          │  CloudFront     │
                          └────────┬────────┘
                                   │
                          ┌────────▼────────┐
                          │       ALB       │
                          │  (Compartilhado)│
                          └────┬──────┬─────┘
                               │      │
                ┌──────────────┘      └──────────────┐
                │                                     │
        ┌───────▼────────┐                   ┌───────▼────────┐
        │  Target Group  │                   │  Target Group  │
        │      EC2       │                   │      EKS       │
        │  Priority: 50  │                   │  Priority: 50  │
        └───────┬────────┘                   └───────┬────────┘
                │                                     │
        ┌───────▼────────┐                   ┌───────▼────────┐
        │  2x EC2 t2.micro│                  │  EKS Cluster   │
        │  + Docker       │                  │  2x t3.small   │
        │  Container      │                  │  + Pods        │
        └───────┬────────┘                   └───────┬────────┘
                │                                     │
                └─────────────┬───────────────────────┘
                              │
                     ┌────────▼────────┐
                     │  RDS PostgreSQL │
                     │  (Compartilhado)│
                     └────────┬────────┘
                              │
                     ┌────────▼────────┐
                     │ Secrets Manager │
                     │  (Compartilhado)│
                     └─────────────────┘
```

## 📦 Componentes Criados

### 1. Terraform Module (terraform/modules/eks.tf)

**Recursos provisionados:**
- EKS Cluster (v1.28)
- EKS Node Group (managed, auto-scaling)
- IAM Roles (cluster + nodes)
- Security Groups com regras para ALB
- OIDC Provider para IRSA
- IAM Role para AWS Load Balancer Controller
- CloudWatch Log Group

### 2. Kubernetes Manifests (k8s/)

| Arquivo | Descrição |
|---------|-----------|
| `deployment.yaml` | Define pods da aplicação com health checks e resource limits |
| `service.yaml` | ClusterIP service para comunicação interna |
| `ingress.yaml` | Ingress com anotações para ALB Controller |
| `hpa.yaml` | Horizontal Pod Autoscaler (2-10 replicas, CPU 70%, Memory 80%) |
| `serviceaccount.yaml` | Service Account com IRSA para Secrets Manager |
| `secret.yaml` | Kubernetes secret com credenciais do RDS |

### 3. GitHub Actions Workflows

#### eks-deploy.yml

**Actions suportadas:**
- `provision`: Cria cluster EKS e instala Load Balancer Controller
- `deploy`: Deploy da aplicação no EKS
- `destroy`: Remove cluster EKS

**Steps principais:**
1. Terraform apply com `enable_eks=true`
2. Instalação do AWS Load Balancer Controller via Helm
3. Criação de secrets no Kubernetes
4. Deploy de Deployment, Service, Ingress e HPA
5. Verificação de health dos pods

#### switch-environment.yml

**Modos suportados:**
- `ec2`: Ativa apenas EC2, para EKS (replicas=0)
- `eks`: Ativa apenas EKS, desliga EC2 instances
- `both`: Ambos ativos com load balancing 50/50

**Funcionamento:**
1. Identifica Target Groups (EC2 e EKS)
2. Ajusta prioridades das rules no ALB listener
3. Escala deployments (EC2 start/stop, EKS scale)
4. Valida health dos targets

## 🚀 Processo de Migração

### Passo 1: Provisionar EKS Cluster

```bash
# Via GitHub Actions
1. Ir em Actions → EKS Deploy
2. Selecionar:
   - environment: stg
   - action: provision
3. Run workflow

# Ou via Terraform local
cd terraform/stg
terraform plan -var="enable_eks=true"
terraform apply -var="enable_eks=true"
```

**Tempo estimado**: 15-20 minutos (criação do cluster)

**Validação**:
```bash
aws eks list-clusters --region us-east-1
aws eks describe-cluster --name tx01-eks-stg --region us-east-1
```

### Passo 2: Deploy da Aplicação no EKS

```bash
# Via GitHub Actions
1. Ir em Actions → EKS Deploy
2. Selecionar:
   - environment: stg
   - action: deploy
3. Run workflow
```

**O que acontece:**
1. Configura kubectl com credenciais do cluster
2. Cria ECR registry secret
3. Busca credenciais do RDS no Secrets Manager
4. Cria Kubernetes secret com DB credentials
5. Aplica Deployment (2 pods iniciais)
6. Aplica Service (ClusterIP)
7. Aplica Ingress (cria Target Group automaticamente)
8. Aplica HPA (auto-scaling)
9. Aguarda pods ficarem ready

**Tempo estimado**: 3-5 minutos

**Validação**:
```bash
kubectl get pods
kubectl get svc
kubectl get ingress
kubectl get hpa
kubectl logs -l app=tx01
```

### Passo 3: Testar EKS em Paralelo com EC2

Neste ponto, ambos estarão ativos (mode: both):

```bash
# Via GitHub Actions
1. Ir em Actions → Switch Environment
2. Selecionar:
   - environment: stg
   - mode: both
3. Run workflow
```

**Validação**:
- Acessar ALB DNS: http://tx01-alb-stg-XXXXXXXXXX.us-east-1.elb.amazonaws.com
- Refreshar várias vezes - deve alternar entre EC2 e EKS (load balancing)
- Verificar métricas no CloudWatch

### Passo 4: Migrar Tráfego para EKS

Quando estiver confiante:

```bash
# Via GitHub Actions
1. Ir em Actions → Switch Environment
2. Selecionar:
   - environment: stg
   - mode: eks
3. Run workflow
```

**O que acontece:**
1. Escala EKS deployment para 2 replicas
2. Aguarda pods ficarem healthy
3. Para EC2 instances (stop, não terminate)
4. Ajusta prioridade do ALB: EKS=50, EC2=100

**Rollback rápido (se necessário)**:
```bash
# Voltar para EC2
1. Ir em Actions → Switch Environment
2. Selecionar mode: ec2
3. Run workflow (leva ~2 minutos)
```

## 🔍 Monitoramento

### Métricas do EKS

```bash
# Pods
kubectl top pods
kubectl get hpa

# Logs
kubectl logs -l app=tx01 --tail=100 -f

# Events
kubectl get events --sort-by='.lastTimestamp'
```

### CloudWatch

- **Log Group**: `/aws/eks/tx01-eks-stg/cluster`
- **Métricas**: EKS cluster logs (API, audit, authenticator)

### ALB Target Health

```bash
aws elbv2 describe-target-health \
  --target-group-arn <TG_ARN> \
  --region us-east-1
```

## 🛠️ Troubleshooting

### Pods não iniciam

```bash
# Ver motivo
kubectl describe pod <POD_NAME>

# Logs do pod
kubectl logs <POD_NAME>

# Eventos do namespace
kubectl get events
```

**Causas comuns:**
- Image pull error: Verificar ECR secret
- CrashLoopBackOff: Verificar env vars (DB credentials)
- Pending: Verificar resources (CPU/memory)

### Conexão com RDS falha

```bash
# Verificar secret
kubectl get secret tx01-db-credentials -o yaml

# Verificar se pod tem credenciais
kubectl exec -it <POD_NAME> -- env | grep DB_

# Testar conectividade
kubectl exec -it <POD_NAME> -- nc -zv <RDS_ENDPOINT> 5432
```

**Soluções:**
1. Verificar security group do RDS permite EKS subnets
2. Verificar se secret foi criado corretamente
3. Verificar SSL está habilitado no código

### ALB não roteia para EKS

```bash
# Verificar ingress
kubectl get ingress -o yaml

# Verificar se target group foi criado
aws elbv2 describe-target-groups --region us-east-1 | grep k8s-default-tx01

# Verificar targets registrados
aws elbv2 describe-target-health --target-group-arn <TG_ARN>
```

**Soluções:**
1. Verificar Load Balancer Controller está rodando: `kubectl get pods -n kube-system | grep aws-load-balancer`
2. Verificar annotations do ingress
3. Verificar logs do controller: `kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller`

### HPA não escala

```bash
# Verificar métricas disponíveis
kubectl top pods

# Verificar HPA status
kubectl describe hpa tx01-hpa
```

**Causas comuns:**
- Metrics Server não instalado (EKS já vem com ele)
- Pods sem resource requests definidos
- CPU/memory abaixo do threshold

## 🔒 Segurança

### IRSA (IAM Roles for Service Accounts)

O Service Account `tx01-sa` pode assumir IAM role para acessar:
- Secrets Manager
- ECR
- CloudWatch Logs (futuro)

### Network Policies

Considerar implementar Network Policies para:
- Restringir tráfego entre namespaces
- Permitir apenas pods específicos acessarem RDS
- Bloquear egress não autorizado

### Pod Security Standards

Recomendações:
- Não rodar containers como root
- Usar read-only filesystem
- Definir security context
- Scan de vulnerabilidades nas imagens

## 💡 Otimizações Futuras

### 1. Spot Instances para Nodes

```hcl
capacity_type = "SPOT"
instance_types = ["t3.small", "t3a.small", "t2.small"]
```

**Economia**: Até 70% no custo dos nodes

### 2. Cluster Autoscaler

Instalar Cluster Autoscaler para ajustar número de nodes automaticamente:

```bash
helm repo add autoscaler https://kubernetes.github.io/autoscaler
helm install cluster-autoscaler autoscaler/cluster-autoscaler \
  --set autoDiscovery.clusterName=tx01-eks-stg \
  --set awsRegion=us-east-1
```

### 3. Fargate para Jobs

Para workloads temporários, considerar Fargate:
- Sem gerenciamento de nodes
- Pay-per-pod (mais caro, mas serverless)

### 4. Service Mesh (Istio/LinkerD)

Para observabilidade avançada:
- Circuit breaking
- Retry policies
- Traffic splitting (canary deployments)
- Distributed tracing

### 5. GitOps com ArgoCD

Deploy contínuo com ArgoCD:
- Sync automático do Git para cluster
- Rollback visual
- Multi-cluster management

## 📊 Checklist de Validação

Antes de migrar produção:

- [ ] EKS cluster criado e healthy
- [ ] Pods startam sem erros
- [ ] Conectividade com RDS OK
- [ ] ALB roteia tráfego para EKS
- [ ] Health checks passando
- [ ] HPA funciona (testar com carga)
- [ ] Logs disponíveis no CloudWatch
- [ ] Métricas visíveis (CPU, memory, network)
- [ ] Rollback para EC2 testado
- [ ] Documentação atualizada
- [ ] Time treinado nos comandos kubectl

## 🎓 Comandos Úteis

```bash
# Context do cluster
aws eks update-kubeconfig --name tx01-eks-stg --region us-east-1

# Ver todos recursos
kubectl get all

# Logs em tempo real
kubectl logs -l app=tx01 -f --tail=50

# Executar comando no pod
kubectl exec -it <POD> -- /bin/sh

# Port forward (debug local)
kubectl port-forward svc/tx01-service 8080:80

# Escalar manualmente
kubectl scale deployment tx01-app --replicas=5

# Restart deployment (zero downtime)
kubectl rollout restart deployment tx01-app

# Ver histórico de deploys
kubectl rollout history deployment tx01-app

# Rollback para versão anterior
kubectl rollout undo deployment tx01-app

# Deletar pod específico (será recriado)
kubectl delete pod <POD_NAME>
```

## 📞 Suporte

Em caso de problemas:

1. Verificar logs: `kubectl logs -l app=tx01`
2. Verificar events: `kubectl get events --sort-by='.lastTimestamp'`
3. Verificar GitHub Actions logs
4. Verificar CloudWatch Logs
5. Consultar [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

**Última atualização**: $(date +%Y-%m-%d)
**Versão**: 1.0.0
**Autor**: DevOps Team
