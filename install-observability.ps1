# Manual Observability Stack Installation - PowerShell Version
# Faster than GitHub Actions workflow

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "📊 Installing Plan 3 - Ultra MICRO Observability Stack" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

# Check prerequisites
Write-Host "🔍 Checking prerequisites..." -ForegroundColor Yellow

if (!(Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Host "❌ kubectl not found" -ForegroundColor Red
    exit 1
}

if (!(Get-Command helm -ErrorAction SilentlyContinue)) {
    Write-Host "❌ helm not found. Install from: https://helm.sh/docs/intro/install/" -ForegroundColor Red
    Write-Host ""
    Write-Host "Quick install (Windows):" -ForegroundColor Yellow
    Write-Host "  choco install kubernetes-helm" -ForegroundColor White
    Write-Host "  or download from https://github.com/helm/helm/releases" -ForegroundColor White
    exit 1
}

try {
    kubectl cluster-info | Out-Null
} catch {
    Write-Host "❌ Cannot connect to cluster" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Prerequisites OK" -ForegroundColor Green
Write-Host ""

# Capacity check
Write-Host "🔍 Checking cluster capacity..." -ForegroundColor Yellow

$READY_NODES = (kubectl get nodes --no-headers | Select-String "Ready" | Measure-Object).Count
$TOTAL_PODS = (kubectl get pods -A --no-headers --field-selector=status.phase!=Succeeded,status.phase!=Failed | Measure-Object).Count
$POD_CAPACITY = $READY_NODES * 4
$FREE_SLOTS = $POD_CAPACITY - $TOTAL_PODS

Write-Host "   Ready Nodes: $READY_NODES" -ForegroundColor White
Write-Host "   Total Pods: $TOTAL_PODS" -ForegroundColor White
Write-Host "   Pod Capacity: $POD_CAPACITY" -ForegroundColor White
Write-Host "   Free Slots: $FREE_SLOTS" -ForegroundColor White
Write-Host ""

if ($FREE_SLOTS -lt 3) {
    Write-Host "❌ Insufficient capacity (need 3+ free slots)" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Sufficient capacity" -ForegroundColor Green
Write-Host ""

# Clean old resources
Write-Host "🧹 Cleaning old LoadBalancer services..." -ForegroundColor Yellow
kubectl delete svc -n monitoring kube-prometheus-stack-grafana --ignore-not-found=true 2>$null
Write-Host "✅ Cleanup done" -ForegroundColor Green
Write-Host ""

# Add Helm repo
Write-Host "📦 Adding Helm repository..." -ForegroundColor Yellow
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>$null
helm repo update | Out-Null
Write-Host "✅ Helm repo ready" -ForegroundColor Green
Write-Host ""

# Install stack
Write-Host "🚀 Installing kube-prometheus-stack..." -ForegroundColor Cyan
Write-Host "   This will take ~5-10 minutes..." -ForegroundColor Yellow
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
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host "✅ Installation Complete!" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host ""

Write-Host "📊 Deployed Resources:" -ForegroundColor Cyan
kubectl get pods -n monitoring

Write-Host ""
Write-Host "🌐 Access Grafana:" -ForegroundColor Cyan
Write-Host "   kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80" -ForegroundColor Yellow
Write-Host "   Then open: http://localhost:3000" -ForegroundColor White
Write-Host "   User: admin" -ForegroundColor White
Write-Host "   Password: admin" -ForegroundColor White
Write-Host ""
