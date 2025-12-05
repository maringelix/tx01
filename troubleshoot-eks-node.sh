#!/bin/bash
#
# EKS Node Troubleshooting Script
# Diagnoses nodes that fail to join the cluster
#
# Usage: ./troubleshoot-eks-node.sh <instance-id>
#

set -e

INSTANCE_ID="${1:-}"
REGION="${AWS_REGION:-us-east-1}"

if [ -z "$INSTANCE_ID" ]; then
  echo "❌ Usage: $0 <instance-id>"
  echo ""
  echo "Example: $0 i-0a4427835cdae5d85"
  exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 EKS Node Troubleshooting Script"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Instance ID: $INSTANCE_ID"
echo "Region: $REGION"
echo ""

# Check if instance exists
echo "🔍 Checking instance status..."
INSTANCE_STATUS=$(aws ec2 describe-instance-status \
  --instance-ids "$INSTANCE_ID" \
  --region "$REGION" \
  --query 'InstanceStatuses[0].InstanceState.Name' \
  --output text 2>/dev/null || echo "NOT_FOUND")

if [ "$INSTANCE_STATUS" = "NOT_FOUND" ]; then
  echo "❌ Instance $INSTANCE_ID not found!"
  exit 1
fi

echo "✅ Instance Status: $INSTANCE_STATUS"

# Get instance details
INSTANCE_IP=$(aws ec2 describe-instances \
  --instance-ids "$INSTANCE_ID" \
  --region "$REGION" \
  --query 'Reservations[0].Instances[0].PrivateIpAddress' \
  --output text)

INSTANCE_SUBNET=$(aws ec2 describe-instances \
  --instance-ids "$INSTANCE_ID" \
  --region "$REGION" \
  --query 'Reservations[0].Instances[0].SubnetId' \
  --output text)

INSTANCE_TYPE=$(aws ec2 describe-instances \
  --instance-ids "$INSTANCE_ID" \
  --region "$REGION" \
  --query 'Reservations[0].Instances[0].InstanceType' \
  --output text)

LAUNCH_TIME=$(aws ec2 describe-instances \
  --instance-ids "$INSTANCE_ID" \
  --region "$REGION" \
  --query 'Reservations[0].Instances[0].LaunchTime' \
  --output text)

echo "   IP: $INSTANCE_IP"
echo "   Type: $INSTANCE_TYPE"
echo "   Subnet: $INSTANCE_SUBNET"
echo "   Launch Time: $LAUNCH_TIME"
echo ""

# Check if node is in Kubernetes
echo "🔍 Checking Kubernetes nodes..."
NODE_EXISTS=$(kubectl get nodes -o json | jq -r ".items[].status.addresses[] | select(.type==\"InternalIP\" and .address==\"$INSTANCE_IP\") | .address" || echo "")

if [ -n "$NODE_EXISTS" ]; then
  echo "✅ Node found in Kubernetes cluster"
  NODE_NAME=$(kubectl get nodes -o json | jq -r ".items[] | select(.status.addresses[].address==\"$INSTANCE_IP\") | .metadata.name")
  echo "   Node Name: $NODE_NAME"
  echo ""
  
  echo "📊 Node Details:"
  kubectl describe node "$NODE_NAME"
else
  echo "❌ Node NOT found in Kubernetes cluster"
  echo ""
  echo "🔍 Checking SSM connectivity..."
  
  # Try to send SSM command
  COMMAND_ID=$(aws ssm send-command \
    --instance-ids "$INSTANCE_ID" \
    --document-name "AWS-RunShellScript" \
    --parameters 'commands=["echo SSM_TEST_OK"]' \
    --region "$REGION" \
    --output text \
    --query 'Command.CommandId' 2>&1)
  
  if echo "$COMMAND_ID" | grep -q "InvalidInstanceId"; then
    echo "❌ SSM Agent not responding"
    echo ""
    echo "🔧 TROUBLESHOOTING STEPS:"
    echo ""
    echo "1. TERMINATE & RECREATE (Recommended):"
    echo "   aws ec2 terminate-instances --instance-ids $INSTANCE_ID --region $REGION"
    echo "   # ASG will automatically create a replacement"
    echo ""
    echo "2. CHECK USER DATA LOGS (if SSM works on other nodes):"
    echo "   # View /var/log/cloud-init-output.log via EC2 Console"
    echo ""
    echo "3. CHECK SECURITY GROUPS:"
    echo "   # Ensure nodes can reach EKS API endpoint"
    echo "   # Ensure nodes can communicate with each other"
    echo ""
    echo "4. CHECK IAM ROLE:"
    echo "   # Verify EKS node role has required policies:"
    echo "   # - AmazonEKSWorkerNodePolicy"
    echo "   # - AmazonEKS_CNI_Policy"
    echo "   # - AmazonEC2ContainerRegistryReadOnly"
    echo ""
    exit 1
  fi
  
  echo "✅ SSM Agent responding, fetching diagnostics..."
  sleep 5
  
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📋 DIAGNOSTICS FROM INSTANCE"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  aws ssm get-command-invocation \
    --command-id "$COMMAND_ID" \
    --instance-id "$INSTANCE_ID" \
    --region "$REGION" \
    --query 'StandardOutputContent' \
    --output text 2>/dev/null || echo "Command still running..."
  
  echo ""
  echo "🔧 MANUAL DIAGNOSIS REQUIRED:"
  echo ""
  echo "Run detailed diagnostics via SSM:"
  echo "  ./diagnose-node.sh  # Then copy to instance via SSM"
  echo ""
  echo "Or access instance via Session Manager:"
  echo "  aws ssm start-session --target $INSTANCE_ID --region $REGION"
  echo ""
  echo "Check these logs:"
  echo "  - journalctl -u kubelet -n 100 --no-pager"
  echo "  - journalctl -u containerd -n 50 --no-pager"
  echo "  - /var/log/cloud-init-output.log"
  echo "  - /var/log/messages"
  echo ""
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Troubleshooting complete"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
