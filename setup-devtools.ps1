# Setup Development Tools for TX01/DX01 Projects
# Run as Administrator if needed for some installations

Write-Host "[*] Setting up development environment for TX01/DX01..." -ForegroundColor Cyan
Write-Host ""

# Function to check if a command exists
function Test-Command {
    param($Command)
    $null = Get-Command $Command -ErrorAction SilentlyContinue
    return $?
}

# Track what needs to be installed
$toInstall = @()

Write-Host "[CHECK] Checking installed tools..." -ForegroundColor Yellow
Write-Host ""

# Check AWS CLI
if (Test-Command aws) {
    $awsVersion = aws --version 2>&1
    Write-Host "[OK] AWS CLI: $awsVersion" -ForegroundColor Green
} else {
    Write-Host "[MISSING] AWS CLI: Not installed" -ForegroundColor Red
    $toInstall += @{Name="AWS CLI"; Package="Amazon.AWSCLI"}
}

# Check Terraform
if (Test-Command terraform) {
    $tfVersion = terraform --version | Select-Object -First 1
    Write-Host "[OK] Terraform: $tfVersion" -ForegroundColor Green
} else {
    Write-Host "[MISSING] Terraform: Not installed" -ForegroundColor Red
    $toInstall += @{Name="Terraform"; Package="Hashicorp.Terraform"}
}

# Check kubectl
if (Test-Command kubectl) {
    $kubectlVersion = kubectl version --client --short 2>&1 | Select-Object -First 1
    Write-Host "[OK] kubectl: $kubectlVersion" -ForegroundColor Green
} else {
    Write-Host "[MISSING] kubectl: Not installed" -ForegroundColor Red
    $toInstall += @{Name="kubectl"; Package="Kubernetes.kubectl"}
}

# Check Docker
if (Test-Command docker) {
    $dockerVersion = docker --version
    Write-Host "[OK] Docker: $dockerVersion" -ForegroundColor Green
} else {
    Write-Host "[MISSING] Docker: Not installed" -ForegroundColor Red
    Write-Host "[WARN] Docker Desktop needs manual installation: https://www.docker.com/products/docker-desktop/" -ForegroundColor Yellow
}

# Check Git
if (Test-Command git) {
    $gitVersion = git --version
    Write-Host "[OK] Git: $gitVersion" -ForegroundColor Green
} else {
    Write-Host "[MISSING] Git: Not installed" -ForegroundColor Red
    $toInstall += @{Name="Git"; Package="Git.Git"}
}

# Check Node.js
if (Test-Command node) {
    $nodeVersion = node --version
    Write-Host "[OK] Node.js: $nodeVersion" -ForegroundColor Green
} else {
    Write-Host "[MISSING] Node.js: Not installed" -ForegroundColor Red
    $toInstall += @{Name="Node.js"; Package="OpenJS.NodeJS.LTS"}
}

# Check npm (usually comes with Node.js)
if (Test-Command npm) {
    $npmVersion = npm --version
    Write-Host "[OK] npm: v$npmVersion" -ForegroundColor Green
} else {
    Write-Host "[MISSING] npm: Not installed (comes with Node.js)" -ForegroundColor Red
}

# Check Python (optional but useful for AWS CLI v2 and scripts)
if (Test-Command python) {
    $pythonVersion = python --version
    Write-Host "[OK] Python: $pythonVersion" -ForegroundColor Green
} else {
    Write-Host "[WARN] Python: Not installed (optional)" -ForegroundColor Yellow
}

# Check Make (optional, useful for Makefile)
if (Test-Command make) {
    $makeVersion = make --version | Select-Object -First 1
    Write-Host "[OK] Make: $makeVersion" -ForegroundColor Green
} else {
    Write-Host "[WARN] Make: Not installed (optional, Makefile will not work)" -ForegroundColor Yellow
}

# Check jq (JSON processor, useful for AWS/kubectl)
if (Test-Command jq) {
    $jqVersion = jq --version
    Write-Host "[OK] jq: $jqVersion" -ForegroundColor Green
} else {
    Write-Host "[WARN] jq: Not installed (optional but recommended)" -ForegroundColor Yellow
    $toInstall += @{Name="jq"; Package="jqlang.jq"}
}

# Check helm (Kubernetes package manager)
if (Test-Command helm) {
    $helmVersion = helm version --short
    Write-Host "[OK] Helm: $helmVersion" -ForegroundColor Green
} else {
    Write-Host "[WARN] Helm: Not installed (needed for Prometheus/Grafana)" -ForegroundColor Yellow
    $toInstall += @{Name="Helm"; Package="Helm.Helm"}
}

Write-Host ""
Write-Host "========================================================================" -ForegroundColor Cyan

# Install missing tools
if ($toInstall.Count -gt 0) {
    Write-Host ""
    Write-Host "[INSTALL] Installing $($toInstall.Count) missing tools..." -ForegroundColor Yellow
    Write-Host ""
    
    foreach ($tool in $toInstall) {
        Write-Host "Installing $($tool.Name)..." -ForegroundColor Cyan
        try {
            winget install --id $($tool.Package) --silent --accept-source-agreements --accept-package-agreements
            Write-Host "[OK] $($tool.Name) installed successfully" -ForegroundColor Green
        } catch {
            Write-Host "[ERROR] Failed to install $($tool.Name): $_" -ForegroundColor Red
        }
        Write-Host ""
    }
    
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "[IMPORTANT] Close and reopen your terminal to refresh PATH" -ForegroundColor Yellow
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "[OK] All essential tools are already installed!" -ForegroundColor Green
    Write-Host ""
}

# Additional setup instructions
Write-Host "[NEXT STEPS]:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Configure AWS CLI:" -ForegroundColor White
Write-Host "   aws configure" -ForegroundColor Gray
Write-Host "   # Enter your AWS Access Key ID and Secret" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Install Docker Desktop manually (if needed):" -ForegroundColor White
Write-Host "   https://www.docker.com/products/docker-desktop/" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Install Node.js dependencies:" -ForegroundColor White
Write-Host "   cd dx01" -ForegroundColor Gray
Write-Host "   npm run install:all" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Initialize Terraform:" -ForegroundColor White
Write-Host "   cd tx01/terraform/stg" -ForegroundColor Gray
Write-Host "   terraform init" -ForegroundColor Gray
Write-Host ""
Write-Host "5. Configure kubectl for EKS:" -ForegroundColor White
Write-Host "   aws eks update-kubeconfig --region us-east-1 --name tx01-eks-stg" -ForegroundColor Gray
Write-Host ""

Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "[COMPLETE] Setup complete! Run this script again to verify installations." -ForegroundColor Green
Write-Host ""
