#!/bin/bash
#
# Manual Observability Stack Installation
# Faster than GitHub Actions workflow
#

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Installing Plan 3 - Ultra MICRO Observability Stack"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check prerequisites
echo "🔍 Checking prerequisites..."
command -v kubectl >/dev/null 2>&1 || { echo "❌ kubectl not found"; exit 1; }
command -v helm >/dev/null 2>&1 || { echo "❌ helm not found. Install: https://helm.sh/docs/intro/install/"; exit 1; }
kubectl cluster-info >/dev/null 2>&1 || { echo "❌ Cannot connect to cluster"; exit 1; }
echo "✅ Prerequisites OK"
echo ""

# Capacity check
echo "🔍 Checking cluster capacity..."
READY_NODES=$(kubectl get nodes --no-headers | grep -c " Ready " || echo 0)
TOTAL_PODS=$(kubectl get pods -A --no-headers --field-selector=status.phase!=Succeeded,status.phase!=Failed | wc -l)
POD_CAPACITY=$((READY_NODES * 4))
FREE_SLOTS=$((POD_CAPACITY - TOTAL_PODS))

echo "   Ready Nodes: $READY_NODES"
echo "   Total Pods: $TOTAL_PODS"
echo "   Pod Capacity: $POD_CAPACITY"
echo "   Free Slots: $FREE_SLOTS"
echo ""

if [ $FREE_SLOTS -lt 3 ]; then
  echo "❌ Insufficient capacity (need 3+ free slots)"
  exit 1
fi
echo "✅ Sufficient capacity"
echo ""

# Clean old resources
echo "🧹 Cleaning old LoadBalancer services..."
kubectl delete svc -n monitoring kube-prometheus-stack-grafana --ignore-not-found=true 2>/dev/null || true
echo "✅ Cleanup done"
echo ""

# Add Helm repo
echo "📦 Adding Helm repository..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update
echo "✅ Helm repo ready"
echo ""

# Install stack
echo "🚀 Installing kube-prometheus-stack..."
echo "   This will take ~5-10 minutes..."
echo ""

helm upgrade --install kube-prometheus-stack \
  prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --values k8s/prometheus-micro-values.yaml \
  --set grafana.adminPassword=admin \
  --set prometheus-node-exporter.enabled=false \
  --set nodeExporter.enabled=false \
  --timeout=15m

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Installation Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 Deployed Resources:"
kubectl get pods -n monitoring
echo ""
echo "🌐 Access Grafana:"
echo "   kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80"
echo "   Then open: http://localhost:3000"
echo "   User: admin"
echo "   Password: admin"
echo ""
