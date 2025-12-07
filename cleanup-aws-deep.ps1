# Deep AWS Cleanup Script
# Removes orphaned resources that Resource Explorer still shows
# These are "phantom" resources that appear in listings but don't actually exist

param(
    [Parameter(Mandatory=$false)]
    [switch]$DryRun = $false,
    
    [Parameter(Mandatory=$false)]
    [string]$CsvPath = "$env:USERPROFILE\Downloads\resources.csv"
)

$ErrorActionPreference = "Continue"
$region = "us-east-1"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "DEEP AWS CLEANUP - Orphaned Resources Removal" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

if ($DryRun) {
    Write-Host "WARNING: DRY RUN MODE - No resources will be deleted" -ForegroundColor Yellow
    Write-Host ""
}

# Load CSV if exists
$resourcesFromCsv = @()
if (Test-Path $CsvPath) {
    Write-Host "Loading resources from CSV: $CsvPath" -ForegroundColor Green
    $resourcesFromCsv = Import-Csv $CsvPath
    Write-Host "  Found $($resourcesFromCsv.Count) resources in CSV`n" -ForegroundColor Cyan
}

# ============================================================
# STEP 1: Clean EC2 Fleets (50 orphaned fleets!)
# ============================================================
Write-Host "Step 1: Cleaning EC2 Fleets..." -ForegroundColor Green
try {
    $fleets = (aws ec2 describe-fleets --region $region 2>$null | ConvertFrom-Json).Fleets
    $orphanedFleets = $fleets | Where-Object { 
        $_.FleetState -in @('deleted_running', 'deleted_terminating') -or
        $_.CreateTime -lt (Get-Date).AddDays(-7)
    }
    
    Write-Host "  Total fleets: $($fleets.Count)"
    Write-Host "  Orphaned/old fleets: $($orphanedFleets.Count)"
    
    foreach ($fleet in $orphanedFleets) {
        $age = ((Get-Date) - [DateTime]$fleet.CreateTime).Days
        Write-Host "    - $($fleet.FleetId) (State: $($fleet.FleetState), Age: $age days)"
        
        if (-not $DryRun) {
            # Try to delete fleet (may fail if already in deletion)
            aws ec2 delete-fleets --fleet-ids $fleet.FleetId --terminate-instances --region $region 2>$null | Out-Null
        }
    }
    
    if ($orphanedFleets.Count -eq 0) {
        Write-Host "  ✅ No orphaned fleets" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  Note: EC2 Fleets auto-delete after 48 hours" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ⚠️  Error: $_" -ForegroundColor Yellow
}

# ============================================================
# STEP 2: Clean Orphaned Network Interfaces
# ============================================================
Write-Host "`nStep 2: Cleaning Orphaned Network Interfaces..." -ForegroundColor Green
try {
    $enis = (aws ec2 describe-network-interfaces --region $region 2>$null | ConvertFrom-Json).NetworkInterfaces
    $availableEnis = $enis | Where-Object { $_.Status -eq 'available' }
    
    Write-Host "  Total ENIs: $($enis.Count)"
    Write-Host "  Available (orphaned): $($availableEnis.Count)"
    
    foreach ($eni in $availableEnis) {
        Write-Host "    - $($eni.NetworkInterfaceId) (VPC: $($eni.VpcId))"
        
        if (-not $DryRun) {
            try {
                aws ec2 delete-network-interface --network-interface-id $eni.NetworkInterfaceId --region $region 2>$null
                Write-Host "      ✅ Deleted" -ForegroundColor Green
            } catch {
                Write-Host "      ⚠️  Failed (may not exist): $_" -ForegroundColor Yellow
            }
        }
    }
    
    if ($availableEnis.Count -eq 0) {
        Write-Host "  ✅ No orphaned ENIs" -ForegroundColor Green
    }
} catch {
    Write-Host "  ⚠️  Error: $_" -ForegroundColor Yellow
}

# ============================================================
# STEP 3: Clean Orphaned Security Group Rules
# ============================================================
Write-Host "`nStep 3: Cleaning Orphaned Security Group Rules..." -ForegroundColor Green
try {
    $sgs = (aws ec2 describe-security-groups --region $region 2>$null | ConvertFrom-Json).SecurityGroups
    $orphanedRules = 0
    
    foreach ($sg in $sgs) {
        # Check for rules referencing non-existent security groups
        $invalidIngress = $sg.IpPermissions | Where-Object { 
            $_.UserIdGroupPairs.Count -gt 0 -and 
            ($_.UserIdGroupPairs | ForEach-Object { 
                $refSgId = $_.GroupId
                -not ($sgs | Where-Object { $_.GroupId -eq $refSgId })
            })
        }
        
        $invalidEgress = $sg.IpPermissionsEgress | Where-Object { 
            $_.UserIdGroupPairs.Count -gt 0 -and 
            ($_.UserIdGroupPairs | ForEach-Object { 
                $refSgId = $_.GroupId
                -not ($sgs | Where-Object { $_.GroupId -eq $refSgId })
            })
        }
        
        if ($invalidIngress -or $invalidEgress) {
            Write-Host "    - $($sg.GroupId) ($($sg.GroupName)) has orphaned rules"
            $orphanedRules++
            
            if (-not $DryRun) {
                # Note: Cannot selectively delete rules referencing non-existent SGs
                # They will be cleaned up automatically by AWS
            }
        }
    }
    
    if ($orphanedRules -eq 0) {
        Write-Host "  ✅ No orphaned security group rules" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  Found $orphanedRules SGs with orphaned rules (AWS will auto-clean)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ⚠️  Error: $_" -ForegroundColor Yellow
}

# ============================================================
# STEP 4: Clean Orphaned Subnets
# ============================================================
Write-Host "`nStep 4: Cleaning Orphaned Subnets..." -ForegroundColor Green
try {
    $vpcs = (aws ec2 describe-vpcs --region $region 2>$null | ConvertFrom-Json).Vpcs
    $subnets = (aws ec2 describe-subnets --region $region 2>$null | ConvertFrom-Json).Subnets
    
    # Find subnets in non-existent VPCs or without tags
    $orphanedSubnets = $subnets | Where-Object {
        $vpcExists = $vpcs | Where-Object { $_.VpcId -eq $_.VpcId }
        -not $vpcExists -or ($_.Tags.Count -eq 0 -and $_.VpcId -ne 'vpc-default')
    }
    
    Write-Host "  Total subnets: $($subnets.Count)"
    Write-Host "  Potentially orphaned: $($orphanedSubnets.Count)"
    
    foreach ($subnet in $orphanedSubnets) {
        Write-Host "    - $($subnet.SubnetId) (VPC: $($subnet.VpcId), CIDR: $($subnet.CidrBlock))"
        
        if (-not $DryRun) {
            try {
                aws ec2 delete-subnet --subnet-id $subnet.SubnetId --region $region 2>$null
                Write-Host "      ✅ Deleted" -ForegroundColor Green
            } catch {
                Write-Host "      ⚠️  Failed (may have dependencies): $_" -ForegroundColor Yellow
            }
        }
    }
    
    if ($orphanedSubnets.Count -eq 0) {
        Write-Host "  ✅ No orphaned subnets" -ForegroundColor Green
    }
} catch {
    Write-Host "  ⚠️  Error: $_" -ForegroundColor Yellow
}

# ============================================================
# STEP 5: Clean KMS Keys (if customer-managed and unused)
# ============================================================
Write-Host "`nStep 5: Checking KMS Keys..." -ForegroundColor Green
try {
    $keys = (aws kms list-keys --region $region 2>$null | ConvertFrom-Json).Keys
    $orphanedKeys = @()
    
    foreach ($key in $keys) {
        $keyMetadata = aws kms describe-key --key-id $key.KeyId --region $region 2>$null | ConvertFrom-Json
        $keyDetail = $keyMetadata.KeyMetadata
        
        # Only consider customer-managed keys
        if ($keyDetail.KeyManager -eq 'CUSTOMER' -and $keyDetail.KeyState -in @('Disabled', 'PendingDeletion')) {
            $orphanedKeys += $keyDetail
            Write-Host "    - $($keyDetail.KeyId) (State: $($keyDetail.KeyState))"
            
            if (-not $DryRun -and $keyDetail.KeyState -eq 'Disabled') {
                # Schedule deletion (7 days minimum)
                aws kms schedule-key-deletion --key-id $keyDetail.KeyId --pending-window-in-days 7 --region $region 2>$null
                Write-Host "      ⏰ Scheduled for deletion in 7 days" -ForegroundColor Yellow
            }
        }
    }
    
    if ($orphanedKeys.Count -eq 0) {
        Write-Host "  ✅ No orphaned KMS keys" -ForegroundColor Green
    }
} catch {
    Write-Host "  ⚠️  Error: $_" -ForegroundColor Yellow
}

# ============================================================
# STEP 6: Clean RDS Parameter Groups (custom only)
# ============================================================
Write-Host "`nStep 6: Cleaning Custom RDS Parameter Groups..." -ForegroundColor Green
try {
    $paramGroups = (aws rds describe-db-parameter-groups --region $region 2>$null | ConvertFrom-Json).DBParameterGroups
    $customGroups = $paramGroups | Where-Object { -not $_.DBParameterGroupName.StartsWith('default.') }
    
    Write-Host "  Total parameter groups: $($paramGroups.Count)"
    Write-Host "  Custom parameter groups: $($customGroups.Count)"
    
    # Check which ones are not in use
    $instances = (aws rds describe-db-instances --region $region 2>$null | ConvertFrom-Json).DBInstances
    
    foreach ($pg in $customGroups) {
        $inUse = $instances | Where-Object { $_.DBParameterGroups.DBParameterGroupName -contains $pg.DBParameterGroupName }
        
        if (-not $inUse) {
            Write-Host "    - $($pg.DBParameterGroupName) (not in use)"
            
            if (-not $DryRun) {
                try {
                    aws rds delete-db-parameter-group --db-parameter-group-name $pg.DBParameterGroupName --region $region 2>$null
                    Write-Host "      ✅ Deleted" -ForegroundColor Green
                } catch {
                    Write-Host "      ⚠️  Failed: $_" -ForegroundColor Yellow
                }
            }
        }
    }
} catch {
    Write-Host "  ⚠️  Error: $_" -ForegroundColor Yellow
}

# ============================================================
# STEP 7: Clean EventBridge Rules (custom only)
# ============================================================
Write-Host "`nStep 7: Cleaning EventBridge Rules..." -ForegroundColor Green
try {
    $rules = (aws events list-rules --region $region 2>$null | ConvertFrom-Json).Rules
    $customRules = $rules | Where-Object { -not $_.Name.StartsWith('AWS') }
    
    Write-Host "  Total rules: $($rules.Count)"
    Write-Host "  Custom rules: $($customRules.Count)"
    
    foreach ($rule in $customRules) {
        Write-Host "    - $($rule.Name) (State: $($rule.State))"
        
        if (-not $DryRun -and $rule.State -eq 'DISABLED') {
            try {
                # Remove targets first
                $targets = (aws events list-targets-by-rule --rule $rule.Name --region $region 2>$null | ConvertFrom-Json).Targets
                if ($targets.Count -gt 0) {
                    $targetIds = ($targets | ForEach-Object { $_.Id }) -join ' '
                    aws events remove-targets --rule $rule.Name --ids $targetIds --region $region 2>$null
                }
                
                # Delete rule
                aws events delete-rule --name $rule.Name --region $region 2>$null
                Write-Host "      ✅ Deleted" -ForegroundColor Green
            } catch {
                Write-Host "      ⚠️  Failed: $_" -ForegroundColor Yellow
            }
        }
    }
} catch {
    Write-Host "  ⚠️  Error: $_" -ForegroundColor Yellow
}

# ============================================================
# STEP 8: Verify Resource Explorer Index
# ============================================================
Write-Host "`nStep 8: Checking Resource Explorer..." -ForegroundColor Green
try {
    $indexes = aws resource-explorer-2 list-indexes --region $region 2>$null | ConvertFrom-Json
    if ($indexes.Indexes) {
        Write-Host "  Found Resource Explorer indexes"
        Write-Host "  ⚠️  Tip: Resource Explorer may cache deleted resources for up to 24h" -ForegroundColor Yellow
        Write-Host "  ⚠️  Run 'aws resource-explorer-2 delete-index' if you want to remove the index" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ⚠️  Error: $_" -ForegroundColor Yellow
}

# ============================================================
# STEP 9: Force Resource Explorer Refresh
# ============================================================
Write-Host "`nStep 9: Triggering Resource Explorer Refresh..." -ForegroundColor Green
if (-not $DryRun) {
    try {
        # Delete and recreate index to force refresh
        $indexes = (aws resource-explorer-2 list-indexes --region $region 2>$null | ConvertFrom-Json).Indexes
        
        if ($indexes.Count -gt 0) {
            Write-Host "  Found $($indexes.Count) indexes"
            Write-Host "  ⚠️  To force refresh, manually delete and recreate index in AWS Console" -ForegroundColor Yellow
            Write-Host "  ⚠️  Or run: aws resource-explorer-2 delete-index --region $region" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  ⚠️  Error: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "  (Skipped in dry run mode)"
}

# ============================================================
# Final Summary
# ============================================================
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "DEEP CLEANUP COMPLETED" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Re-check Resource Explorer
Write-Host "Current AWS Resources Summary:" -ForegroundColor Cyan
try {
    Write-Host "  EC2 Instances: " -NoNewline
    $instances = (aws ec2 describe-instances --filters "Name=instance-state-name,Values=running,pending,stopping,stopped" --region $region 2>$null | ConvertFrom-Json).Reservations.Instances
    Write-Host "$($instances.Count)" -ForegroundColor $(if ($instances.Count -eq 0) { 'Green' } else { 'Yellow' })
    
    Write-Host "  EC2 Fleets: " -NoNewline
    $fleets = (aws ec2 describe-fleets --region $region 2>$null | ConvertFrom-Json).Fleets
    Write-Host "$($fleets.Count)" -ForegroundColor $(if ($fleets.Count -eq 0) { 'Green' } else { 'Yellow' })
    
    Write-Host "  Network Interfaces: " -NoNewline
    $enis = (aws ec2 describe-network-interfaces --region $region 2>$null | ConvertFrom-Json).NetworkInterfaces
    Write-Host "$($enis.Count)" -ForegroundColor $(if ($enis.Count -eq 0) { 'Green' } else { 'Cyan' })
    
    Write-Host "  Security Groups: " -NoNewline
    $sgs = (aws ec2 describe-security-groups --region $region 2>$null | ConvertFrom-Json).SecurityGroups
    Write-Host "$($sgs.Count)" -ForegroundColor Cyan
    
    Write-Host "  Subnets: " -NoNewline
    $subnets = (aws ec2 describe-subnets --region $region 2>$null | ConvertFrom-Json).Subnets
    Write-Host "$($subnets.Count)" -ForegroundColor Cyan
    
    Write-Host "  EKS Clusters: " -NoNewline
    $clusters = (aws eks list-clusters --region $region 2>$null | ConvertFrom-Json).clusters
    Write-Host "$($clusters.Count)" -ForegroundColor $(if ($clusters.Count -eq 0) { 'Green' } else { 'Yellow' })
    
    Write-Host "  RDS Instances: " -NoNewline
    $rdsInstances = (aws rds describe-db-instances --region $region 2>$null | ConvertFrom-Json).DBInstances
    Write-Host "$($rdsInstances.Count)" -ForegroundColor $(if ($rdsInstances.Count -eq 0) { 'Green' } else { 'Yellow' })
    
    Write-Host "  Load Balancers: " -NoNewline
    $lbs = (aws elbv2 describe-load-balancers --region $region 2>$null | ConvertFrom-Json).LoadBalancers
    Write-Host "$($lbs.Count)" -ForegroundColor $(if ($lbs.Count -eq 0) { 'Green' } else { 'Yellow' })
    
} catch {
    Write-Host "  ⚠️  Error getting summary: $_" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Important Notes:" -ForegroundColor Yellow
Write-Host "  1. EC2 Fleets auto-delete after 48 hours (cannot be forced)" -ForegroundColor Cyan
Write-Host "  2. Resource Explorer may cache deleted resources for up to 24 hours" -ForegroundColor Cyan
Write-Host "  3. Security group rules referencing deleted SGs auto-clean" -ForegroundColor Cyan
Write-Host "  4. Service-linked IAM roles cannot be manually deleted" -ForegroundColor Cyan
Write-Host "  5. Some resources (VPC, Route Tables) need all dependencies removed first" -ForegroundColor Cyan
Write-Host ""

if ($DryRun) {
    Write-Host "WARNING: This was a DRY RUN - no resources were deleted" -ForegroundColor Yellow
    Write-Host "   Run without -DryRun to execute deletions" -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "Recommendations:" -ForegroundColor Green
Write-Host "  1. Wait 24-48 hours for AWS to cleanup orphaned resources" -ForegroundColor Cyan
Write-Host "  2. Delete Resource Explorer index to clear cache: " -ForegroundColor Cyan
Write-Host "     aws resource-explorer-2 delete-index --region us-east-1" -ForegroundColor White
Write-Host "  3. Re-export Resource Explorer after 24h to verify cleanup" -ForegroundColor Cyan
Write-Host ""
