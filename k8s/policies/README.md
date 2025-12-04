# 🛡️ OPA Gatekeeper - Policy as Code

## 📋 Overview

OPA Gatekeeper implementa **Policy-as-Code** no cluster Kubernetes usando **Rego** (Open Policy Agent).

**Benefícios:**
- ✅ Garante compliance e segurança **antes** do deploy
- ✅ Previne configurações inseguras no cluster
- ✅ Auditoria contínua de recursos existentes
- ✅ Métricas no Prometheus + Dashboard no Grafana

---

## 🚀 Deploy

### **Opção 1: Workflow Dedicado**
Use o workflow `deploy-gatekeeper.yml`:

```yaml
Environment: stg/prd
Action: install/upgrade/uninstall
Enforcement Mode:
  - dryrun: Apenas reporta violações (STG recomendado)
  - enforce: Bloqueia recursos non-compliant (PRD recomendado)
```

### **Opção 2: Com Observability Stack**
Use o workflow `deploy-observability.yml`:

```yaml
Environment: stg/prd
Action: install
Install OPA Gatekeeper: true  ✅
Gatekeeper Mode: dryrun/enforce
```

---

## 📋 Políticas Implementadas

### **1. K8sRequiredResourceLimits**
**Arquivo:** `templates/required-resource-limits.yaml`

**O que faz:** Garante que todos os containers tenham CPU e memory limits/requests definidos.

**Rego:**
```rego
violation[{"msg": msg}] {
  container := input.review.object.spec.containers[_]
  not container.resources.limits.cpu
  msg := sprintf("Container '%v' must have CPU limit", [container.name])
}
```

**Exemplo de violação:**
```yaml
# ❌ Bloqueado/Reportado
spec:
  containers:
  - name: app
    image: nginx
    # FALTANDO: resources.limits e requests
```

**Exemplo compliant:**
```yaml
# ✅ Permitido
spec:
  containers:
  - name: app
    image: nginx
    resources:
      limits:
        cpu: "500m"
        memory: "512Mi"
      requests:
        cpu: "250m"
        memory: "256Mi"
```

---

### **2. K8sRequiredLabels**
**Arquivo:** `templates/required-labels.yaml`

**O que faz:** Exige labels obrigatórias em Deployments, Services, Pods.

**Labels requeridas:**
- `app`: Nome da aplicação (formato: lowercase-with-dashes)
- `environment`: stg, prd, dev
- `managed-by`: terraform, helm, kubectl

**Exemplo de violação:**
```yaml
# ❌ Bloqueado
metadata:
  name: my-app
  labels:
    app: MyApp  # ❌ não segue regex
    # ❌ FALTANDO: environment, managed-by
```

**Exemplo compliant:**
```yaml
# ✅ Permitido
metadata:
  name: my-app
  labels:
    app: my-app
    environment: stg
    managed-by: helm
```

---

### **3. K8sBlockPrivileged**
**Arquivo:** `templates/block-privileged.yaml`

**O que faz:** Bloqueia containers privilegiados.

**Exemplo de violação:**
```yaml
# ❌ Bloqueado
spec:
  containers:
  - name: app
    securityContext:
      privileged: true  # ❌ Não permitido
```

---

### **4. K8sRequireProbes**
**Arquivo:** `templates/require-probes.yaml`

**O que faz:** Exige readinessProbe e livenessProbe em Deployments/StatefulSets.

**Exemplo compliant:**
```yaml
# ✅ Permitido
spec:
  containers:
  - name: app
    livenessProbe:
      httpGet:
        path: /health
        port: 8080
    readinessProbe:
      httpGet:
        path: /ready
        port: 8080
```

---

### **5. K8sAllowedRegistries**
**Arquivo:** `templates/allowed-registries.yaml`

**O que faz:** Só permite imagens de registries aprovados.

**Registries permitidos:**
- `894222083614.dkr.ecr.us-east-1.amazonaws.com/` (seu ECR)
- `docker.io/library/` (Docker Hub oficial)
- `quay.io/`
- `ghcr.io/` (GitHub Container Registry)

**Exemplo de violação:**
```yaml
# ❌ Bloqueado
spec:
  containers:
  - name: app
    image: random-registry.com/untrusted:latest
```

---

### **6. K8sBlockNodePort**
**Arquivo:** `templates/block-nodeport.yaml`

**O que faz:** Bloqueia Services tipo NodePort, força LoadBalancer/ClusterIP.

---

### **7. K8sRequireSecurityContext**
**Arquivo:** `templates/require-security-context.yaml`

**O que faz:** Exige security context em containers:
- `runAsNonRoot: true`
- `readOnlyRootFilesystem: true`
- `allowPrivilegeEscalation: false`

**Exemplo compliant:**
```yaml
# ✅ Permitido
spec:
  containers:
  - name: app
    securityContext:
      runAsNonRoot: true
      readOnlyRootFilesystem: true
      allowPrivilegeEscalation: false
```

---

## 🎯 Enforcement Modes

### **dryrun** (Recomendado para STG)
- ✅ Reporta violações nos logs
- ✅ Não bloqueia recursos
- ✅ Métricas aparecem no Grafana
- ✅ Ideal para testar políticas

### **enforce** (Recomendado para PRD)
- 🚫 Bloqueia recursos non-compliant
- ✅ Força compliance no deploy
- ✅ Retorna erro explicativo

---

## 📊 Monitoramento

### **Métricas Prometheus**
Gatekeeper exporta métricas automaticamente:

```promql
# Total de violações (enforced)
sum(gatekeeper_violations{enforcement_action="deny"})

# Violações por constraint
sum by (constraint_name) (gatekeeper_violations)

# Duração de validação (p99)
histogram_quantile(0.99, sum(rate(gatekeeper_validation_request_duration_seconds_bucket[5m])) by (le))

# Taxa de requests de validação
sum(rate(gatekeeper_validation_request_count[5m]))
```

### **Dashboard Grafana**
Importe o dashboard: `k8s/grafana-dashboards/opa-gatekeeper-dashboard.json`

**Visualizações:**
- 🚨 Violações ativas (enforced vs dryrun)
- 📋 Número de templates e constraints
- 📊 Violações por constraint (gráficos de linha)
- 🥧 Distribuição de constraints por template
- ⏱️ Latência de validação (p50, p95, p99)
- 🔄 Taxa de requests de validação

**Para importar:**
1. Acesse Grafana: `kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80`
2. Navegue: Dashboards → Import
3. Upload: `k8s/grafana-dashboards/opa-gatekeeper-dashboard.json`

---

## 🧪 Testar Políticas

### **1. Ver constraints aplicadas**
```bash
kubectl get constraints -A
kubectl get constrainttemplates
```

### **2. Ver violações**
```bash
# Todas as violações
kubectl get constraints -A -o json | jq '.items[] | select(.status.totalViolations > 0)'

# Violações de uma constraint específica
kubectl get k8srequiredlabels must-have-labels-dryrun -o json | jq '.status.violations'
```

### **3. Testar com recurso inválido**
Crie `test-violation.yaml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-violation
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: test
  template:
    metadata:
      labels:
        app: test
        # ❌ FALTANDO: environment, managed-by
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        # ❌ FALTANDO: resources, probes, securityContext
```

```bash
kubectl apply -f test-violation.yaml

# Em dryrun: Deploy criado, mas violações registradas
# Em enforce: Deploy BLOQUEADO com erro explicativo
```

### **4. Testar com recurso válido**
Crie `test-compliant.yaml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-compliant
  namespace: default
  labels:
    app: test-app
    environment: stg
    managed-by: kubectl
spec:
  replicas: 1
  selector:
    matchLabels:
      app: test-app
  template:
    metadata:
      labels:
        app: test-app
        environment: stg
        managed-by: kubectl
    spec:
      containers:
      - name: nginx
        image: 894222083614.dkr.ecr.us-east-1.amazonaws.com/tx01:latest
        resources:
          limits:
            cpu: "500m"
            memory: "512Mi"
          requests:
            cpu: "250m"
            memory: "256Mi"
        livenessProbe:
          httpGet:
            path: /
            port: 80
        readinessProbe:
          httpGet:
            path: /
            port: 80
        securityContext:
          runAsNonRoot: true
          readOnlyRootFilesystem: true
          allowPrivilegeEscalation: false
```

```bash
kubectl apply -f test-compliant.yaml
# ✅ Deploy criado com sucesso (0 violações)
```

---

## 🔧 Troubleshooting

### **Constraints não sendo aplicadas**
```bash
# Verificar se Gatekeeper está rodando
kubectl get pods -n gatekeeper-system

# Ver logs
kubectl logs -n gatekeeper-system deployment/gatekeeper-controller-manager
kubectl logs -n gatekeeper-system deployment/gatekeeper-audit
```

### **Métricas não aparecem no Prometheus**
```bash
# Verificar ServiceMonitor
kubectl get servicemonitor -n gatekeeper-system

# Verificar se Prometheus está scrapando
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
# Acesse: http://localhost:9090/targets
# Procure por: gatekeeper-controller-manager-metrics
```

### **Ver configuração de uma constraint**
```bash
kubectl get k8srequiredlabels must-have-labels-dryrun -o yaml
```

---

## 📚 Referências

- [OPA Gatekeeper Docs](https://open-policy-agent.github.io/gatekeeper/)
- [Rego Language](https://www.openpolicyagent.org/docs/latest/policy-language/)
- [Gatekeeper Library](https://github.com/open-policy-agent/gatekeeper-library)
- [Kubernetes Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)

---

## 🎓 Aprendendo Rego

Rego é a linguagem de políticas do OPA. Exemplo básico:

```rego
package mypackage

# Regra simples: bloquear se privileged == true
violation[{"msg": msg}] {
  container := input.review.object.spec.containers[_]
  container.securityContext.privileged == true
  msg := sprintf("Container %v is privileged!", [container.name])
}
```

**Como ler:**
- `violation[...]` = lista de violações
- `container := ...` = itera sobre todos os containers
- `container.securityContext.privileged == true` = condição
- Se condição é true → violação é adicionada com mensagem

---

## 💰 Custo

**Gatekeeper:**
- Pods: 2 replicas (controller + audit)
- Resources: ~100MB memory, ~100m CPU cada
- **Custo**: ~$0/mês (já está dentro dos nodes EKS)

**Total com Observability Stack:**
- Grafana Stack: ~$2.50/mês (EBS volumes)
- Gatekeeper: $0/mês (sem recursos adicionais)
- **Total**: ~$2.50/mês

---

**🎯 Pronto para deploy!** Use o workflow `deploy-observability.yml` com `install_gatekeeper: true`
