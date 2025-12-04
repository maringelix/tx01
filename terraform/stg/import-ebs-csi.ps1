# Import EBS CSI Driver resources to Terraform state
# Run this from terraform/stg directory

Write-Host "🔧 Importing EBS CSI Driver resources to Terraform state..." -ForegroundColor Cyan

# Get OIDC ID first (needed for later)
$oidc = aws eks describe-cluster --name tx01-eks-stg --region us-east-1 --query 'cluster.identity.oidc.issuer' --output text
$oidcId = $oidc -replace 'https://oidc.eks.us-east-1.amazonaws.com/id/', ''
$accountId = aws sts get-caller-identity --query Account --output text

Write-Host "`n1️⃣ Importing OIDC Provider..." -ForegroundColor Yellow
terraform import "module.infrastructure.aws_iam_openid_connect_provider.eks[0]" "arn:aws:iam::${accountId}:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/${oidcId}"

Write-Host "`n2️⃣ Importing IAM Role..." -ForegroundColor Yellow
terraform import 'module.infrastructure.aws_iam_role.ebs_csi_driver[0]' tx01-eks-ebs-csi-driver

Write-Host "`n3️⃣ Importing IAM Policy Attachment..." -ForegroundColor Yellow
terraform import 'module.infrastructure.aws_iam_role_policy_attachment.ebs_csi_driver_policy[0]' tx01-eks-ebs-csi-driver/arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy

Write-Host "`n4️⃣ Importing EBS CSI Driver addon..." -ForegroundColor Yellow
terraform import 'module.infrastructure.aws_eks_addon.ebs_csi_driver[0]' tx01-eks-stg:aws-ebs-csi-driver

Write-Host "`n✅ Import completed!" -ForegroundColor Green -BackgroundColor DarkGreen

Write-Host "`n🎯 Next steps:" -ForegroundColor Cyan
Write-Host "   1. Run: terraform plan" -ForegroundColor Gray
Write-Host "   2. Verify no changes are needed" -ForegroundColor Gray
Write-Host "   3. If plan shows changes, run: terraform apply" -ForegroundColor Gray
Write-Host "   4. Commit the changes to Git" -ForegroundColor Gray
