#!/bin/bash
# Script para instalar AWS Load Balancer Controller no cluster EKS existente

set -e

CLUSTER_NAME="tx01-eks-stg"
REGION="us-east-1"
ENVIRONMENT="stg"

echo "=== Installing AWS Load Balancer Controller ==="

# Add Helm repo
echo "Adding Helm repository..."
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# Get cluster OIDC provider
echo "Getting OIDC provider..."
OIDC_PROVIDER=$(aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query "cluster.identity.oidc.issuer" --output text | sed -e "s/^https:\/\///")
echo "OIDC Provider: $OIDC_PROVIDER"

# Get IAM role ARN
echo "Getting IAM role ARN..."
ROLE_ARN=$(aws iam get-role --role-name tx01-alb-controller-$ENVIRONMENT --query 'Role.Arn' --output text)
echo "Role ARN: $ROLE_ARN"

# Install controller
echo "Installing AWS Load Balancer Controller via Helm..."
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  --namespace kube-system \
  --set clusterName=$CLUSTER_NAME \
  --set serviceAccount.create=true \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=$ROLE_ARN \
  --set region=$REGION \
  --set vpcId=$(aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query 'cluster.resourcesVpcConfig.vpcId' --output text)

echo ""
echo "=== Waiting for controller to be ready ==="
kubectl wait --for=condition=available --timeout=300s deployment/aws-load-balancer-controller -n kube-system

echo ""
echo "=== Verifying installation ==="
kubectl get deployment -n kube-system aws-load-balancer-controller
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

echo ""
echo "✅ AWS Load Balancer Controller installed successfully!"
