#!/bin/bash

# Grafana Stack Installation Script
# This script installs Prometheus, Grafana, and Loki on EKS

set -e

echo "🚀 Installing Grafana Stack on EKS..."

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Add Prometheus Community Helm repo
echo -e "${YELLOW}📦 Adding Helm repositories...${NC}"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Create monitoring namespace
echo -e "${YELLOW}📁 Creating monitoring namespace...${NC}"
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Install kube-prometheus-stack (Prometheus + Grafana)
echo -e "${YELLOW}📊 Installing Prometheus + Grafana...${NC}"
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.retention=7d \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=10Gi \
  --set grafana.adminPassword=admin \
  --set grafana.persistence.enabled=true \
  --set grafana.persistence.size=5Gi \
  --set grafana.service.type=LoadBalancer \
  --set alertmanager.enabled=true \
  --wait --timeout=10m

# Install Loki for logs
echo -e "${YELLOW}📝 Installing Loki...${NC}"
helm upgrade --install loki grafana/loki-stack \
  --namespace monitoring \
  --set loki.persistence.enabled=true \
  --set loki.persistence.size=10Gi \
  --set promtail.enabled=true \
  --set grafana.enabled=false \
  --wait --timeout=5m

# Get Grafana URL
echo -e "${GREEN}✅ Installation complete!${NC}"
echo ""
echo "📊 Grafana Access:"
echo "===================="

GRAFANA_URL=$(kubectl get svc -n monitoring kube-prometheus-stack-grafana -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

if [ -z "$GRAFANA_URL" ]; then
  echo "⚠️  LoadBalancer URL not ready yet. Run this command in a few minutes:"
  echo "   kubectl get svc -n monitoring kube-prometheus-stack-grafana"
else
  echo "🌐 URL: http://$GRAFANA_URL"
fi

echo ""
echo "🔐 Credentials:"
echo "   Username: admin"
echo "   Password: admin"
echo ""
echo "🎯 Port-forward alternative:"
echo "   kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80"
echo "   Then access: http://localhost:3000"
echo ""

# Wait for pods to be ready
echo -e "${YELLOW}⏳ Waiting for pods to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=prometheus -n monitoring --timeout=300s
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana -n monitoring --timeout=300s

echo -e "${GREEN}🎉 Grafana Stack is ready!${NC}"
echo ""
echo "📋 Useful commands:"
echo "   kubectl get all -n monitoring"
echo "   kubectl logs -n monitoring -l app.kubernetes.io/name=grafana"
echo "   helm list -n monitoring"
