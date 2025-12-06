# Manual Observability Stack Installation
# Plan 3 - Ultra MICRO optimized for Free Tier

Write-Host "Installing Plan 3 - Ultra MICRO Observability Stack" -ForegroundColor Cyan
Write-Host ""

# Check helm
if (!(Get-Command helm -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: helm not found" -ForegroundColor Red
    Write-Host "Install from: https://github.com/helm/helm/releases" -ForegroundColor Yellow
    exit 1
}

# Capacity check
Write-Host "Checking cluster capacity..." -ForegroundColor Yellow
$READY_NODES = (kubectl get nodes --no-headers | Select-String "Ready" | Measure-Object).Count
$TOTAL_PODS = (kubectl get pods -A --no-headers --field-selector=status.phase!=Succeeded,status.phase!=Failed | Measure-Object).Count
$FREE_SLOTS = ($READY_NODES * 4) - $TOTAL_PODS

Write-Host "Ready Nodes: $READY_NODES" -ForegroundColor White
Write-Host "Total Pods: $TOTAL_PODS" -ForegroundColor White
Write-Host "Free Slots: $FREE_SLOTS" -ForegroundColor White

if ($FREE_SLOTS -lt 3) {
    Write-Host "ERROR: Insufficient capacity (need 3+ free slots)" -ForegroundColor Red
    exit 1
}
Write-Host "OK: Sufficient capacity" -ForegroundColor Green
Write-Host ""

# Clean old resources
Write-Host "Cleaning old services..." -ForegroundColor Yellow
kubectl delete svc -n monitoring kube-prometheus-stack-grafana --ignore-not-found=true 2>$null
Write-Host ""

# Add Helm repo
Write-Host "Adding Helm repository..." -ForegroundColor Yellow
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>$null
helm repo update | Out-Null
Write-Host ""

# Install
Write-Host "Installing kube-prometheus-stack (this takes ~5-10 minutes)..." -ForegroundColor Cyan
Write-Host ""

helm upgrade --install kube-prometheus-stack `
  prometheus-community/kube-prometheus-stack `
  --namespace monitoring `
  --create-namespace `
  --values k8s/prometheus-micro-values.yaml `
  --set grafana.adminPassword=admin `
  --set prometheus-node-exporter.enabled=false `
  --set nodeExporter.enabled=false `
  --timeout=15m

Write-Host ""
Write-Host "Installation Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Deployed Resources:" -ForegroundColor Cyan
kubectl get pods -n monitoring
Write-Host ""
Write-Host "Access Grafana:" -ForegroundColor Cyan
Write-Host "  kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80" -ForegroundColor Yellow
Write-Host "  Open: http://localhost:3000" -ForegroundColor White
Write-Host "  User: admin / Password: admin" -ForegroundColor White
