#!/bin/bash

# TX01 EKS Helper Script
# Facilita operações comuns no cluster EKS

set -e

ENVIRONMENT="${1:-stg}"
AWS_REGION="us-east-1"
CLUSTER_NAME="tx01-eks-${ENVIRONMENT}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

function print_usage() {
    echo "Usage: $0 [environment] [command]"
    echo ""
    echo "Environments:"
    echo "  stg       Staging (default)"
    echo "  prd       Production"
    echo ""
    echo "Commands:"
    echo "  status    Show cluster and pod status"
    echo "  logs      Tail application logs"
    echo "  shell     Open shell in a pod"
    echo "  scale     Scale deployment"
    echo "  restart   Restart deployment (zero downtime)"
    echo "  db        Test database connection"
    echo "  metrics   Show pod metrics (CPU/Memory)"
    echo "  health    Check target health in ALB"
    echo "  config    Update kubeconfig"
    echo ""
    echo "Examples:"
    echo "  $0 stg status"
    echo "  $0 stg logs"
    echo "  $0 prd scale 5"
}

function check_cluster() {
    echo -e "${YELLOW}Checking if cluster exists...${NC}"
    if ! aws eks describe-cluster --name "$CLUSTER_NAME" --region "$AWS_REGION" &>/dev/null; then
        echo -e "${RED}Cluster $CLUSTER_NAME not found in $AWS_REGION${NC}"
        exit 1
    fi
    echo -e "${GREEN}Cluster found!${NC}"
}

function update_kubeconfig() {
    echo -e "${YELLOW}Updating kubeconfig...${NC}"
    aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$AWS_REGION"
    echo -e "${GREEN}Kubeconfig updated!${NC}"
}

function show_status() {
    check_cluster
    update_kubeconfig
    
    echo -e "\n${GREEN}=== Cluster Info ===${NC}"
    kubectl cluster-info
    
    echo -e "\n${GREEN}=== Deployments ===${NC}"
    kubectl get deployments
    
    echo -e "\n${GREEN}=== Pods ===${NC}"
    kubectl get pods -o wide
    
    echo -e "\n${GREEN}=== Services ===${NC}"
    kubectl get svc
    
    echo -e "\n${GREEN}=== Ingress ===${NC}"
    kubectl get ingress
    
    echo -e "\n${GREEN}=== HPA ===${NC}"
    kubectl get hpa
}

function tail_logs() {
    check_cluster
    update_kubeconfig
    
    echo -e "${YELLOW}Tailing logs for app=tx01...${NC}"
    kubectl logs -l app=tx01 -f --tail=100
}

function open_shell() {
    check_cluster
    update_kubeconfig
    
    POD=$(kubectl get pods -l app=tx01 -o jsonpath='{.items[0].metadata.name}')
    if [ -z "$POD" ]; then
        echo -e "${RED}No pods found${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}Opening shell in pod: $POD${NC}"
    kubectl exec -it "$POD" -- /bin/sh
}

function scale_deployment() {
    check_cluster
    update_kubeconfig
    
    REPLICAS="${3:-2}"
    echo -e "${YELLOW}Scaling deployment to $REPLICAS replicas...${NC}"
    kubectl scale deployment tx01-app --replicas="$REPLICAS"
    
    echo -e "${YELLOW}Waiting for rollout...${NC}"
    kubectl rollout status deployment tx01-app
    
    echo -e "${GREEN}Scaled successfully!${NC}"
}

function restart_deployment() {
    check_cluster
    update_kubeconfig
    
    echo -e "${YELLOW}Restarting deployment (zero downtime)...${NC}"
    kubectl rollout restart deployment tx01-app
    
    echo -e "${YELLOW}Waiting for rollout...${NC}"
    kubectl rollout status deployment tx01-app
    
    echo -e "${GREEN}Restarted successfully!${NC}"
}

function test_db_connection() {
    check_cluster
    update_kubeconfig
    
    POD=$(kubectl get pods -l app=tx01 -o jsonpath='{.items[0].metadata.name}')
    if [ -z "$POD" ]; then
        echo -e "${RED}No pods found${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}Testing DB connection from pod: $POD${NC}"
    
    DB_HOST=$(kubectl get secret tx01-db-credentials -o jsonpath='{.data.host}' | base64 -d)
    DB_PORT=$(kubectl get secret tx01-db-credentials -o jsonpath='{.data.port}' | base64 -d)
    
    echo "DB Host: $DB_HOST"
    echo "DB Port: $DB_PORT"
    
    kubectl exec "$POD" -- nc -zv "$DB_HOST" "$DB_PORT"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Database connection OK!${NC}"
    else
        echo -e "${RED}Database connection FAILED!${NC}"
        exit 1
    fi
}

function show_metrics() {
    check_cluster
    update_kubeconfig
    
    echo -e "${YELLOW}Fetching pod metrics...${NC}"
    kubectl top pods -l app=tx01
    
    echo -e "\n${YELLOW}Fetching node metrics...${NC}"
    kubectl top nodes
}

function check_health() {
    echo -e "${YELLOW}Checking ALB target health...${NC}"
    
    TG_ARN=$(aws elbv2 describe-target-groups \
        --region "$AWS_REGION" \
        --query "TargetGroups[?contains(TargetGroupName, 'k8s-default-tx01')].TargetGroupArn" \
        --output text)
    
    if [ -z "$TG_ARN" ]; then
        echo -e "${RED}EKS target group not found${NC}"
        exit 1
    fi
    
    echo "Target Group ARN: $TG_ARN"
    echo ""
    
    aws elbv2 describe-target-health \
        --target-group-arn "$TG_ARN" \
        --region "$AWS_REGION" \
        --query 'TargetHealthDescriptions[*].[Target.Id, TargetHealth.State, TargetHealth.Reason]' \
        --output table
}

# Main
case "${2:-status}" in
    status)
        show_status
        ;;
    logs)
        tail_logs
        ;;
    shell)
        open_shell
        ;;
    scale)
        scale_deployment "$@"
        ;;
    restart)
        restart_deployment
        ;;
    db)
        test_db_connection
        ;;
    metrics)
        show_metrics
        ;;
    health)
        check_health
        ;;
    config)
        update_kubeconfig
        ;;
    help|--help|-h)
        print_usage
        ;;
    *)
        echo -e "${RED}Unknown command: ${2}${NC}"
        echo ""
        print_usage
        exit 1
        ;;
esac
