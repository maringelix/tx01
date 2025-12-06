# Manual AWS Cleanup Script
# Run this after destroy-environment.yml workflow fails

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("stg", "prd")]
    [string]$Environment,
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun = $false
)

$ErrorActionPreference = "Continue"
$region = "us-east-1"
$clusterName = "tx01-eks-$Environment"
$vpcName = "tx01-vpc-$Environment"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "MANUAL AWS CLEANUP - $Environment" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

if ($DryRun) {
    Write-Host "WARNING: DRY RUN MODE - No resources will be deleted" -ForegroundColor Yellow
    Write-Host ""
}

# Step 1: Delete EKS Cluster
Write-Host "Step 1: Deleting EKS Cluster..." -ForegroundColor Green
try {
    $cluster = aws eks describe-cluster --name $clusterName --region $region 2>$null | ConvertFrom-Json
    if ($cluster) {
        Write-Host "  Found cluster: $clusterName"
        
        # Delete nodegroups
        Write-Host "  Deleting nodegroups..."
        $nodegroups = (aws eks list-nodegroups --cluster-name $clusterName --region $region | ConvertFrom-Json).nodegroups
        foreach ($ng in $nodegroups) {
            Write-Host "    - $ng"
            if (-not $DryRun) {
                aws eks delete-nodegroup --cluster-name $clusterName --nodegroup-name $ng --region $region 2>$null
            }
        }
        
        if ($nodegroups.Count -gt 0) {
            Write-Host "  Waiting for nodegroups to delete (max 10 min)..."
            for ($i = 1; $i -le 20; $i++) {
                Start-Sleep -Seconds 30
                $remaining = (aws eks list-nodegroups --cluster-name $clusterName --region $region 2>$null | ConvertFrom-Json).nodegroups
                if ($remaining.Count -eq 0) {
                    Write-Host "  ✅ All nodegroups deleted" -ForegroundColor Green
                    break
                }
                Write-Host "    Waiting... ($i/20) - $($remaining.Count) nodegroups remaining"
            }
        }
        
        # Delete addons
        Write-Host "  Deleting addons..."
        $addons = (aws eks list-addons --cluster-name $clusterName --region $region 2>$null | ConvertFrom-Json).addons
        foreach ($addon in $addons) {
            Write-Host "    - $addon"
            if (-not $DryRun) {
                aws eks delete-addon --cluster-name $clusterName --addon-name $addon --region $region 2>$null
            }
        }
        
        Start-Sleep -Seconds 30
        
        # Delete cluster
        Write-Host "  Deleting cluster: $clusterName"
        if (-not $DryRun) {
            aws eks delete-cluster --name $clusterName --region $region 2>$null
        }
        
        Write-Host "  Waiting for cluster deletion (max 10 min)..."
        for ($i = 1; $i -le 20; $i++) {
            Start-Sleep -Seconds 30
            $exists = aws eks describe-cluster --name $clusterName --region $region 2>$null
            if (-not $exists) {
                Write-Host "  ✅ Cluster deleted" -ForegroundColor Green
                break
            }
            Write-Host "    Waiting... ($i/20)"
        }
    } else {
        Write-Host "  ✅ Cluster not found" -ForegroundColor Green
    }
} catch {
    Write-Host "  ⚠️  Error: $_" -ForegroundColor Yellow
}

# Step 2: Force delete Auto Scaling Groups
Write-Host "`nStep 2: Deleting Auto Scaling Groups..." -ForegroundColor Green
try {
    $asgs = (aws autoscaling describe-auto-scaling-groups --region $region | ConvertFrom-Json).AutoScalingGroups | Where-Object { $_.AutoScalingGroupName -like "*tx01*" }
    foreach ($asg in $asgs) {
        Write-Host "  - $($asg.AutoScalingGroupName)"
        if (-not $DryRun) {
            aws autoscaling delete-auto-scaling-group --auto-scaling-group-name $asg.AutoScalingGroupName --force-delete --region $region 2>$null
        }
    }
    if ($asgs.Count -eq 0) {
        Write-Host "  ✅ No ASGs found" -ForegroundColor Green
    } else {
        Start-Sleep -Seconds 60
    }
} catch {
    Write-Host "  ⚠️  Error: $_" -ForegroundColor Yellow
}

# Step 3: Terminate EC2 instances
Write-Host "`nStep 3: Terminating EC2 instances..." -ForegroundColor Green
try {
    $instances = (aws ec2 describe-instances --filters "Name=tag:eks:cluster-name,Values=$clusterName" "Name=instance-state-name,Values=running,pending,stopping,stopped" --region $region | ConvertFrom-Json).Reservations.Instances
    $instanceIds = $instances | ForEach-Object { $_.InstanceId }
    
    if ($instanceIds.Count -gt 0) {
        Write-Host "  Found $($instanceIds.Count) instances"
        foreach ($id in $instanceIds) {
            Write-Host "    - $id"
        }
        if (-not $DryRun) {
            aws ec2 terminate-instances --instance-ids $instanceIds --region $region 2>$null
        }
        Start-Sleep -Seconds 60
    } else {
        Write-Host "  ✅ No instances found" -ForegroundColor Green
    }
} catch {
    Write-Host "  ⚠️  Error: $_" -ForegroundColor Yellow
}

# Step 4: Delete Launch Templates
Write-Host "`nStep 4: Deleting Launch Templates..." -ForegroundColor Green
try {
    $lts = (aws ec2 describe-launch-templates --filters "Name=tag:Project,Values=tx01" --region $region 2>$null | ConvertFrom-Json).LaunchTemplates
    foreach ($lt in $lts) {
        Write-Host "  - $($lt.LaunchTemplateName) ($($lt.LaunchTemplateId))"
        if (-not $DryRun) {
            aws ec2 delete-launch-template --launch-template-id $lt.LaunchTemplateId --region $region 2>$null
        }
    }
    if ($lts.Count -eq 0) {
        Write-Host "  ✅ No launch templates found" -ForegroundColor Green
    }
} catch {
    Write-Host "  ⚠️  Error: $_" -ForegroundColor Yellow
}

# Step 5: Delete Network Interfaces
Write-Host "`nStep 5: Deleting Network Interfaces..." -ForegroundColor Green
Start-Sleep -Seconds 60  # Wait for instances to fully terminate
try {
    $enis = (aws ec2 describe-network-interfaces --filters "Name=status,Values=available" --region $region 2>$null | ConvertFrom-Json).NetworkInterfaces | Where-Object { 
        $_.TagSet | Where-Object { $_.Key -eq "cluster.k8s.amazonaws.com/name" -and $_.Value -eq $clusterName }
    }
    
    foreach ($eni in $enis) {
        Write-Host "  - $($eni.NetworkInterfaceId)"
        if (-not $DryRun) {
            aws ec2 delete-network-interface --network-interface-id $eni.NetworkInterfaceId --region $region 2>$null
        }
    }
    if ($enis.Count -eq 0) {
        Write-Host "  ✅ No ENIs found" -ForegroundColor Green
    }
} catch {
    Write-Host "  ⚠️  Error: $_" -ForegroundColor Yellow
}

# Step 6: Get VPC ID
Write-Host "`nStep 6: Getting VPC information..." -ForegroundColor Green
$vpcId = $null
try {
    $vpc = (aws ec2 describe-vpcs --filters "Name=tag:Name,Values=$vpcName" --region $region 2>$null | ConvertFrom-Json).Vpcs[0]
    if ($vpc) {
        $vpcId = $vpc.VpcId
        Write-Host "  Found VPC: $vpcId ($vpcName)" -ForegroundColor Cyan
    } else {
        Write-Host "  ✅ VPC not found" -ForegroundColor Green
    }
} catch {
    Write-Host "  ⚠️  Error: $_" -ForegroundColor Yellow
}

if ($vpcId) {
    # Step 7: Delete Security Groups (multiple passes)
    Write-Host "`nStep 7: Deleting Security Groups (3 passes)..." -ForegroundColor Green
    for ($pass = 1; $pass -le 3; $pass++) {
        Write-Host "  Pass $pass/3..."
        
        try {
            $sgs = (aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$vpcId" --region $region | ConvertFrom-Json).SecurityGroups | Where-Object { $_.GroupName -ne "default" }
            
            # First, revoke all rules
            foreach ($sg in $sgs) {
                Write-Host "    Revoking rules: $($sg.GroupId)"
                
                # Ingress
                if ($sg.IpPermissions.Count -gt 0) {
                    $ingressJson = $sg.IpPermissions | ConvertTo-Json -Depth 10
                    $tempFile = [System.IO.Path]::GetTempFileName()
                    $ingressJson | Out-File -FilePath $tempFile -Encoding UTF8
                    if (-not $DryRun) {
                        aws ec2 revoke-security-group-ingress --group-id $sg.GroupId --ip-permissions file://$tempFile --region $region 2>$null
                    }
                    Remove-Item $tempFile -Force
                }
                
                # Egress
                if ($sg.IpPermissionsEgress.Count -gt 0) {
                    $egressJson = $sg.IpPermissionsEgress | ConvertTo-Json -Depth 10
                    $tempFile = [System.IO.Path]::GetTempFileName()
                    $egressJson | Out-File -FilePath $tempFile -Encoding UTF8
                    if (-not $DryRun) {
                        aws ec2 revoke-security-group-egress --group-id $sg.GroupId --ip-permissions file://$tempFile --region $region 2>$null
                    }
                    Remove-Item $tempFile -Force
                }
            }
            
            Start-Sleep -Seconds 5
            
            # Then delete security groups
            foreach ($sg in $sgs) {
                Write-Host "    Deleting: $($sg.GroupId)"
                if (-not $DryRun) {
                    aws ec2 delete-security-group --group-id $sg.GroupId --region $region 2>$null
                }
            }
            
            Start-Sleep -Seconds 5
        } catch {
            Write-Host "    ⚠️  Error in pass $pass : $_" -ForegroundColor Yellow
        }
    }

    # Step 8: Delete Subnets
    Write-Host "`nStep 8: Deleting Subnets..." -ForegroundColor Green
    try {
        $subnets = (aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpcId" --region $region | ConvertFrom-Json).Subnets
        foreach ($subnet in $subnets) {
            Write-Host "  - $($subnet.SubnetId) ($($subnet.CidrBlock))"
            if (-not $DryRun) {
                aws ec2 delete-subnet --subnet-id $subnet.SubnetId --region $region 2>$null
            }
        }
    } catch {
        Write-Host "  ⚠️  Error: $_" -ForegroundColor Yellow
    }

    # Step 9: Delete Route Tables
    Write-Host "`nStep 9: Deleting Route Tables..." -ForegroundColor Green
    try {
        $routeTables = (aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$vpcId" --region $region | ConvertFrom-Json).RouteTables | Where-Object { 
            -not ($_.Associations | Where-Object { $_.Main -eq $true })
        }
        foreach ($rt in $routeTables) {
            Write-Host "  - $($rt.RouteTableId)"
            if (-not $DryRun) {
                aws ec2 delete-route-table --route-table-id $rt.RouteTableId --region $region 2>$null
            }
        }
    } catch {
        Write-Host "  ⚠️  Error: $_" -ForegroundColor Yellow
    }

    # Step 10: Delete Internet Gateway
    Write-Host "`nStep 10: Deleting Internet Gateway..." -ForegroundColor Green
    try {
        $igws = (aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$vpcId" --region $region | ConvertFrom-Json).InternetGateways
        foreach ($igw in $igws) {
            Write-Host "  - $($igw.InternetGatewayId)"
            if (-not $DryRun) {
                aws ec2 detach-internet-gateway --internet-gateway-id $igw.InternetGatewayId --vpc-id $vpcId --region $region 2>$null
                aws ec2 delete-internet-gateway --internet-gateway-id $igw.InternetGatewayId --region $region 2>$null
            }
        }
    } catch {
        Write-Host "  ⚠️  Error: $_" -ForegroundColor Yellow
    }

    # Step 11: Delete VPC
    Write-Host "`nStep 11: Deleting VPC..." -ForegroundColor Green
    try {
        if (-not $DryRun) {
            aws ec2 delete-vpc --vpc-id $vpcId --region $region 2>$null
        }
        Write-Host "  ✅ VPC deletion initiated: $vpcId" -ForegroundColor Green
    } catch {
        Write-Host "  ⚠️  Error: $_" -ForegroundColor Yellow
    }
}

# Step 12: Delete CloudWatch Log Groups
Write-Host "`nStep 12: Deleting CloudWatch Log Groups..." -ForegroundColor Green
try {
    $logGroups = (aws logs describe-log-groups --region $region | ConvertFrom-Json).logGroups | Where-Object { 
        $_.logGroupName -like "*/aws/rds/instance/tx01-db-$Environment/*" -or 
        $_.logGroupName -like "*/aws/eks/tx01-eks-$Environment/*"
    }
    foreach ($lg in $logGroups) {
        Write-Host "  - $($lg.logGroupName)"
        if (-not $DryRun) {
            aws logs delete-log-group --log-group-name $lg.logGroupName --region $region 2>$null
        }
    }
    if ($logGroups.Count -eq 0) {
        Write-Host "  ✅ No log groups found" -ForegroundColor Green
    }
} catch {
    Write-Host "  ⚠️  Error: $_" -ForegroundColor Yellow
}

# Step 13: Delete Secrets Manager secrets
Write-Host "`nStep 13: Deleting Secrets Manager secrets..." -ForegroundColor Green
try {
    $secrets = (aws secretsmanager list-secrets --region $region | ConvertFrom-Json).SecretList | Where-Object { $_.Name -like "*tx01*" }
    foreach ($secret in $secrets) {
        Write-Host "  - $($secret.Name)"
        if (-not $DryRun) {
            aws secretsmanager delete-secret --secret-id $secret.Name --force-delete-without-recovery --region $region 2>$null
        }
    }
    if ($secrets.Count -eq 0) {
        Write-Host "  ✅ No secrets found" -ForegroundColor Green
    }
} catch {
    Write-Host "  ⚠️  Error: $_" -ForegroundColor Yellow
}

# Step 14: Delete RDS snapshots
Write-Host "`nStep 14: Deleting RDS snapshots..." -ForegroundColor Green
try {
    $snapshots = (aws rds describe-db-snapshots --region $region | ConvertFrom-Json).DBSnapshots | Where-Object { $_.DBInstanceIdentifier -like "*tx01-db-$Environment*" }
    foreach ($snapshot in $snapshots) {
        Write-Host "  - $($snapshot.DBSnapshotIdentifier)"
        if (-not $DryRun) {
            aws rds delete-db-snapshot --db-snapshot-identifier $snapshot.DBSnapshotIdentifier --region $region 2>$null
        }
    }
    if ($snapshots.Count -eq 0) {
        Write-Host "  ✅ No snapshots found" -ForegroundColor Green
    }
} catch {
    Write-Host "  ⚠️  Error: $_" -ForegroundColor Yellow
}

# Step 15: Delete EC2 Fleets (cleanup orphans)
Write-Host "`nStep 15: Deleting EC2 Fleets..." -ForegroundColor Green
try {
    $fleets = (aws ec2 describe-fleets --region $region | ConvertFrom-Json).Fleets | Where-Object { $_.FleetState -ne "deleted_terminating" -and $_.FleetState -ne "deleted_running" }
    Write-Host "  Found $($fleets.Count) fleets (will auto-delete after 48h)"
    # Fleets auto-delete, no action needed
} catch {
    Write-Host "  ⚠️  Error: $_" -ForegroundColor Yellow
}

# Final report
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "CLEANUP COMPLETED" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Preserved resources:" -ForegroundColor Yellow
Write-Host "  * S3: tx01-terraform-state-maringelix-2025"
Write-Host "  * DynamoDB: tx01-terraform-state-maringelix-2025-locks"
Write-Host ""
Write-Host "Service-linked IAM roles (cannot be deleted):" -ForegroundColor Yellow
Write-Host "  * AWSServiceRoleForAmazonEKS"
Write-Host "  * AWSServiceRoleForAmazonEKSNodegroup"
Write-Host "  * AWSServiceRoleForAutoScaling"
Write-Host "  * AWSServiceRoleForRDS"
Write-Host "  * AWSServiceRoleForElasticLoadBalancing"
Write-Host ""
Write-Host "Auto-cleanup resources (will expire):" -ForegroundColor Yellow
Write-Host "  * EC2 Fleets (48 hours)"
Write-Host "  * CloudWatch default resources"
Write-Host ""

if ($DryRun) {
    Write-Host "WARNING: This was a DRY RUN - no resources were deleted" -ForegroundColor Yellow
    Write-Host "   Run without -DryRun to execute deletions" -ForegroundColor Yellow
}
