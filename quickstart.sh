#!/bin/bash

# TX01 Quick Start Script
# Este script auxilia no setup e deployment da infraestrutura

set -e

# Colors para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

check_requirements() {
    print_header "Checking Requirements"
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform not found. Please install Terraform >= 1.0"
        exit 1
    fi
    print_success "Terraform found: $(terraform version -json | grep terraform_version | head -1)"
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI not found. Please install AWS CLI v2"
        exit 1
    fi
    print_success "AWS CLI found: $(aws --version)"
    
    # Check Git
    if ! command -v git &> /dev/null; then
        print_error "Git not found. Please install Git"
        exit 1
    fi
    print_success "Git found: $(git --version)"
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_warning "Docker not found. Optional but recommended for local testing"
    else
        print_success "Docker found: $(docker --version)"
    fi
    
    echo ""
}

check_aws_credentials() {
    print_header "Checking AWS Credentials"
    
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not found or invalid"
        echo "Configure with: aws configure"
        exit 1
    fi
    
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    ACCOUNT_ARN=$(aws sts get-caller-identity --query Arn --output text)
    
    print_success "AWS Account: $ACCOUNT_ID"
    print_success "AWS User: $ACCOUNT_ARN"
    echo ""
}

setup_terraform() {
    print_header "Setting up Terraform"
    
    ENV=${1:-stg}
    
    if [ ! -d "terraform/$ENV" ]; then
        print_error "terraform/$ENV directory not found"
        exit 1
    fi
    
    cd "terraform/$ENV"
    
    print_success "Initializing Terraform for $ENV environment..."
    terraform init
    
    print_success "Validating Terraform configuration..."
    terraform validate
    
    print_success "Terraform setup completed for $ENV"
    cd - > /dev/null
    echo ""
}

deploy_infrastructure() {
    print_header "Deploying Infrastructure"
    
    ENV=${1:-stg}
    
    cd "terraform/$ENV"
    
    echo "Planning infrastructure changes for $ENV..."
    terraform plan -out=tfplan
    
    echo ""
    read -p "Do you want to continue with deployment? (yes/no): " -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        print_success "Applying Terraform configuration..."
        terraform apply -auto-approve tfplan
        
        print_header "Deployment Completed"
        print_success "Getting outputs..."
        terraform output
    else
        print_warning "Deployment cancelled"
    fi
    
    cd - > /dev/null
    echo ""
}

show_help() {
    cat << EOF
TX01 Quick Start Script

Usage: ./quickstart.sh [COMMAND] [ENV]

Commands:
    check           - Check all requirements and credentials
    setup [ENV]     - Setup Terraform (default: stg)
    deploy [ENV]    - Deploy infrastructure (default: stg)
    clean [ENV]     - Clean Terraform state files
    destroy [ENV]   - Destroy infrastructure (CAUTION!)
    help            - Show this help message

Environment:
    stg             - Staging (default)
    prd             - Production

Examples:
    ./quickstart.sh check
    ./quickstart.sh setup stg
    ./quickstart.sh deploy prd
    ./quickstart.sh destroy stg

EOF
}

cleanup_terraform() {
    print_header "Cleaning Terraform"
    
    ENV=${1:-stg}
    
    cd "terraform/$ENV"
    
    rm -f tfplan terraform.tfstate* .terraform.lock.hcl
    rm -rf .terraform/
    
    print_success "Cleaned up $ENV environment"
    cd - > /dev/null
    echo ""
}

destroy_infrastructure() {
    print_header "Destroying Infrastructure - CAUTION!"
    
    ENV=${1:-stg}
    
    print_error "This will destroy all resources in $ENV environment!"
    read -p "Type '$ENV' to confirm destruction: " -r
    echo ""
    
    if [[ $REPLY == $ENV ]]; then
        cd "terraform/$ENV"
        
        print_error "Destroying infrastructure..."
        terraform destroy -auto-approve
        
        print_success "Infrastructure destroyed for $ENV"
        cd - > /dev/null
    else
        print_warning "Destruction cancelled"
    fi
    echo ""
}

# Main script
if [ $# -eq 0 ]; then
    print_header "TX01 Quick Start"
    echo "No command specified. Running checks..."
    echo ""
    check_requirements
    check_aws_credentials
    show_help
    exit 0
fi

COMMAND=$1
ENV=${2:-stg}

case $COMMAND in
    check)
        check_requirements
        check_aws_credentials
        ;;
    setup)
        check_requirements
        check_aws_credentials
        setup_terraform $ENV
        ;;
    deploy)
        check_requirements
        check_aws_credentials
        setup_terraform $ENV
        deploy_infrastructure $ENV
        ;;
    clean)
        cleanup_terraform $ENV
        ;;
    destroy)
        destroy_infrastructure $ENV
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $COMMAND"
        show_help
        exit 1
        ;;
esac

print_header "Done!"
print_success "For more information, see README.md and DEPLOYMENT_GUIDE.md"
