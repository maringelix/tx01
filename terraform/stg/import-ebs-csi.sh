#!/bin/bash

# Import EBS CSI Driver resources to Terraform state
# Run this from terraform/stg directory

echo "🔧 Importing EBS CSI Driver resources to Terraform state..."

# Import EBS CSI Driver addon
echo "📦 Importing EBS CSI Driver addon..."
terraform import 'module.infrastructure.aws_eks_addon.ebs_csi_driver[0]' tx01-eks-stg:aws-ebs-csi-driver

# Import IAM Role
echo "🔐 Importing IAM Role..."
terraform import 'module.infrastructure.aws_iam_role.ebs_csi_driver[0]' tx01-eks-ebs-csi-driver

# Import IAM Policy Attachment
echo "📋 Importing IAM Policy Attachment..."
terraform import 'module.infrastructure.aws_iam_role_policy_attachment.ebs_csi_driver_policy[0]' tx01-eks-ebs-csi-driver/arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy

# Import OIDC Provider (if not already imported)
OIDC_ID=$(aws eks describe-cluster --name tx01-eks-stg --region us-east-1 --query 'cluster.identity.oidc.issuer' --output text | cut -d '/' -f 5)
echo "🔑 Importing OIDC Provider..."
terraform import "module.infrastructure.aws_iam_openid_connect_provider.eks[0]" "arn:aws:iam::894222083614:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/${OIDC_ID}"

echo "✅ Import completed!"
echo ""
echo "🎯 Next steps:"
echo "   1. Run: terraform plan"
echo "   2. Verify no changes are needed"
echo "   3. Commit the updated state"
