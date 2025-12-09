# Unlock Terraform State (Remove stuck lock from DynamoDB)
# Use this when Terraform state is locked and you need to force unlock

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('stg','prd')]
    [string]$Environment = 'stg',
    
    [Parameter(Mandatory=$false)]
    [string]$LockID = ''
)

Write-Host "[*] Terraform State Unlock Tool" -ForegroundColor Cyan
Write-Host ""

$WorkingDir = "terraform/$Environment"

if (-not (Test-Path $WorkingDir)) {
    Write-Host "[ERROR] Directory not found: $WorkingDir" -ForegroundColor Red
    exit 1
}

Write-Host "[INFO] Environment: $Environment" -ForegroundColor White
Write-Host "[INFO] Working directory: $WorkingDir" -ForegroundColor White
Write-Host ""

# Change to terraform directory
Set-Location $WorkingDir

# If Lock ID not provided, try to detect it
if ([string]::IsNullOrEmpty($LockID)) {
    Write-Host "[INFO] Attempting to detect Lock ID..." -ForegroundColor Yellow
    
    # Try to init and capture error
    $initOutput = terraform init 2>&1 | Out-String
    
    # Try to plan to trigger lock error
    Write-Host "[INFO] Running plan to detect lock..." -ForegroundColor Yellow
    $planOutput = terraform plan 2>&1 | Out-String
    
    # Extract Lock ID from error message
    if ($planOutput -match 'ID:\s+([a-f0-9\-]+)') {
        $LockID = $matches[1]
        Write-Host "[FOUND] Lock ID: $LockID" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Could not detect Lock ID automatically" -ForegroundColor Red
        Write-Host "[INFO] Please provide Lock ID manually:" -ForegroundColor Yellow
        Write-Host "  .\unlock-terraform-state.ps1 -Environment stg -LockID <lock-id>" -ForegroundColor Gray
        exit 1
    }
}

Write-Host ""
Write-Host "[ACTION] Unlocking state with Lock ID: $LockID" -ForegroundColor Yellow
Write-Host ""

# Force unlock
Write-Host "[EXECUTING] terraform force-unlock $LockID" -ForegroundColor Cyan
Write-Host ""

# Run force-unlock (automatically answer 'yes')
echo "yes" | terraform force-unlock $LockID

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "[SUCCESS] State unlocked successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "[NEXT] You can now run:" -ForegroundColor Cyan
    Write-Host "  terraform plan" -ForegroundColor White
    Write-Host "  terraform apply" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "[ERROR] Failed to unlock state" -ForegroundColor Red
    Write-Host ""
    Write-Host "[ALTERNATIVE] Try unlocking via DynamoDB Console:" -ForegroundColor Yellow
    Write-Host "  1. Go to: https://console.aws.amazon.com/dynamodbv2/" -ForegroundColor Gray
    Write-Host "  2. Select table: tx01-terraform-state-maringelix-2025-locks" -ForegroundColor Gray
    Write-Host "  3. Explore items" -ForegroundColor Gray
    Write-Host "  4. Delete the item with LockID containing: tx01/$Environment/terraform.tfstate" -ForegroundColor Gray
}

Write-Host ""

# Return to original directory
Set-Location ..\..
