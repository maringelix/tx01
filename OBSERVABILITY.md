# Grafana Stack Installation Guide

Este guia mostra como instalar e configurar o Grafana Stack (Prometheus + Grafana + Loki) no cluster EKS para observabilidade completa.

## 📊 Componentes

- **Prometheus**: Coleta de métricas (CPU, memória, requests, etc.)
- **Grafana**: Visualização de dashboards
- **Loki**: Agregação de logs
- **Promtail**: Coleta de logs dos pods
- **AlertManager**: Gerenciamento de alertas

## 🚀 Instalação Rápida

### Opção 1: Script Automatizado

```bash
# Clone o repositório
git clone https://github.com/maringelix/tx01.git
cd tx01

# Configure kubectl para o EKS
aws eks update-kubeconfig --name tx01-eks-stg --region us-east-1

# Execute o script
chmod +x k8s/install-grafana-stack.sh
./k8s/install-grafana-stack.sh
```

### Opção 2: Instalação Manual

```bash
# 1. Adicionar repositórios Helm
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# 2. Criar namespace
kubectl create namespace monitoring

# 3. Instalar Prometheus + Grafana
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set grafana.adminPassword=admin \
  --set grafana.service.type=LoadBalancer

# 4. Instalar Loki
helm install loki grafana/loki-stack \
  --namespace monitoring \
  --set promtail.enabled=true
```

## 🔐 Acesso ao Grafana

### Via LoadBalancer (Recomendado para Produção)

```bash
# Obter URL do LoadBalancer
kubectl get svc -n monitoring kube-prometheus-stack-grafana

# Credenciais padrão
Username: admin
Password: admin
```

### Via Port-Forward (Desenvolvimento Local)

```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80

# Acesse: http://localhost:3000
```

## 📈 Dashboards Prontos

O kube-prometheus-stack já vem com dashboards pré-configurados:

### Kubernetes Dashboards
- **Cluster Overview**: Visão geral do cluster
- **Nodes**: Métricas de CPU, memória, disco por node
- **Pods**: Métricas por pod e namespace
- **Deployments**: Status e métricas de deployments

### Application Dashboards
- **API Performance**: Request rate, latência, errors
- **Database**: Conexões, queries, cache hits
- **Ingress/ALB**: Tráfego, response codes, latência

## 🎯 Importar Dashboards Customizados

### Node.js Application Dashboard

1. Acesse Grafana > Dashboards > Import
2. Use o ID: `11159` (Node.js Application Dashboard)
3. Selecione o Prometheus data source
4. Click Import

### PostgreSQL Dashboard

1. Dashboards > Import
2. ID: `9628` (PostgreSQL Database)
3. Configure a conexão com o RDS
4. Import

### Kubernetes Cluster Dashboard

1. Dashboards > Import
2. ID: `15757` (Kubernetes Views Global)
3. Selecione Prometheus
4. Import

## 🔔 Configurar Alertas

### Alertas Críticos Recomendados

Edite o arquivo `prometheus-alerts.yaml`:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: critical-alerts
  namespace: monitoring
spec:
  groups:
  - name: critical
    interval: 30s
    rules:
    # Pod não está rodando
    - alert: PodNotRunning
      expr: kube_pod_status_phase{phase!="Running"} > 0
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "Pod {{ $labels.pod }} not running"
        
    # Alto uso de CPU
    - alert: HighCPUUsage
      expr: rate(container_cpu_usage_seconds_total[5m]) > 0.8
      for: 10m
      labels:
        severity: warning
      annotations:
        summary: "High CPU usage on {{ $labels.pod }}"
        
    # Alto uso de memória
    - alert: HighMemoryUsage
      expr: container_memory_usage_bytes / container_spec_memory_limit_bytes > 0.9
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High memory usage on {{ $labels.pod }}"
        
    # Database down
    - alert: DatabaseDown
      expr: up{job="rds"} == 0
      for: 1m
      labels:
        severity: critical
      annotations:
        summary: "Database is down"
        
    # Alto número de erros HTTP
    - alert: HighErrorRate
      expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "High error rate detected"
```

Aplicar alertas:

```bash
kubectl apply -f prometheus-alerts.yaml
```

## 📊 Verificar Status

```bash
# Verificar pods
kubectl get pods -n monitoring

# Ver logs do Grafana
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana

# Ver logs do Prometheus
kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus

# Status do Helm
helm list -n monitoring
```

## 🔍 Queries Prometheus Úteis

### CPU Usage por Pod
```promql
rate(container_cpu_usage_seconds_total{namespace="default"}[5m])
```

### Memória Usage por Pod
```promql
container_memory_usage_bytes{namespace="default"}
```

### HTTP Request Rate
```promql
rate(http_requests_total[5m])
```

### Database Connections
```promql
pg_stat_database_numbackends{datname="tx01_db"}
```

### Pod Restart Count
```promql
kube_pod_container_status_restarts_total
```

## 🗑️ Desinstalar

```bash
# Remover instalações Helm
helm uninstall kube-prometheus-stack -n monitoring
helm uninstall loki -n monitoring

# Remover namespace (cuidado: remove tudo)
kubectl delete namespace monitoring
```

## 💰 Custos

O Grafana Stack é **gratuito** (open source), mas considera custos AWS:

- **EBS Volumes**: ~$0.10/GB/mês
  - Prometheus: 10GB = $1.00/mês
  - Grafana: 5GB = $0.50/mês
  - Loki: 10GB = $1.00/mês
- **LoadBalancer**: ~$18/mês (se usar LoadBalancer para Grafana)

**Total estimado**: ~$2.50/mês (sem LoadBalancer) ou ~$20.50/mês (com LoadBalancer)

**Dica**: Use `port-forward` em desenvolvimento para economizar o LoadBalancer.

## 🎓 Próximos Passos

1. ✅ Instalar Grafana Stack
2. 📊 Importar dashboards prontos
3. 🔔 Configurar alertas críticos
4. 📧 Integrar com SNS/Email para notificações
5. 📈 Criar dashboards customizados para sua aplicação
6. 📝 Adicionar métricas customizadas no código

## 📚 Recursos

- [Prometheus Docs](https://prometheus.io/docs/)
- [Grafana Dashboards](https://grafana.com/grafana/dashboards/)
- [Loki Documentation](https://grafana.com/docs/loki/latest/)
- [AlertManager Guide](https://prometheus.io/docs/alerting/latest/alertmanager/)
