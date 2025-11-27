.PHONY: help init plan apply destroy fmt validate lint clean docker-build docker-push test

PROJECT_NAME := tx01
AWS_REGION := us-east-1
TF_DIR := terraform

help:
	@echo "TX01 - DevOps Infrastructure Management"
	@echo ""
	@echo "Available commands:"
	@echo ""
	@echo "Terraform:"
	@echo "  make init [ENV=stg|prd]       - Initialize Terraform"
	@echo "  make plan [ENV=stg|prd]       - Plan infrastructure changes"
	@echo "  make apply [ENV=stg|prd]      - Apply infrastructure changes"
	@echo "  make destroy [ENV=stg|prd]    - Destroy infrastructure"
	@echo "  make fmt                      - Format Terraform files"
	@echo "  make validate [ENV=stg|prd]  - Validate Terraform files"
	@echo "  make outputs [ENV=stg|prd]   - Show Terraform outputs"
	@echo ""
	@echo "Docker:"
	@echo "  make docker-build             - Build Docker image locally"
	@echo "  make docker-test              - Test Docker image"
	@echo ""
	@echo "Code Quality:"
	@echo "  make lint                     - Run TFLint on Terraform files"
	@echo "  make clean                    - Clean Terraform cache and files"
	@echo ""
	@echo "AWS:"
	@echo "  make aws-info                 - Show AWS account info"
	@echo "  make ssh-stg                  - SSH into staging EC2 instance"
	@echo "  make ssh-prd                  - SSH into production EC2 instance"

ENV ?= stg

init:
	@echo "Initializing Terraform for $(ENV) environment..."
	cd $(TF_DIR)/$(ENV) && terraform init

plan:
	@echo "Planning Terraform for $(ENV) environment..."
	cd $(TF_DIR)/$(ENV) && terraform plan -out=tfplan

apply:
	@echo "Applying Terraform for $(ENV) environment..."
	cd $(TF_DIR)/$(ENV) && terraform apply -auto-approve tfplan

destroy:
	@echo "WARNING: Destroying $(ENV) infrastructure!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		cd $(TF_DIR)/$(ENV) && terraform destroy -auto-approve; \
	else \
		echo "Cancelled."; \
	fi

fmt:
	@echo "Formatting Terraform files..."
	terraform fmt -recursive $(TF_DIR)/

validate:
	@echo "Validating Terraform for $(ENV) environment..."
	cd $(TF_DIR)/$(ENV) && terraform init -backend=false && terraform validate

outputs:
	@echo "Terraform outputs for $(ENV) environment:"
	cd $(TF_DIR)/$(ENV) && terraform output

lint:
	@echo "Running TFLint..."
	tflint --init
	tflint -format compact $(TF_DIR)/

docker-build:
	@echo "Building Docker image..."
	docker build -t $(PROJECT_NAME)-nginx:latest docker/

docker-test:
	@echo "Testing Docker image..."
	docker run -d --name test-nginx -p 8080:80 $(PROJECT_NAME)-nginx:latest
	@sleep 2
	@curl -s http://localhost:8080/health && echo "\n✓ Health check passed"
	docker stop test-nginx
	docker rm test-nginx

clean:
	@echo "Cleaning Terraform files..."
	find $(TF_DIR) -name '.terraform' -type d -exec rm -rf {} + 2>/dev/null || true
	find $(TF_DIR) -name '.terraform.lock.hcl' -delete
	find $(TF_DIR) -name 'tfplan' -delete
	find $(TF_DIR) -name '*.tfstate*' -delete
	@echo "Clean completed."

aws-info:
	@echo "AWS Account Information:"
	aws sts get-caller-identity
	@echo ""
	@echo "Current region: $(AWS_REGION)"

ssh-stg:
	@echo "Connecting to staging EC2 instance..."
	$(eval IP := $(shell cd $(TF_DIR)/stg && terraform output -raw instance_public_ips | head -n1 2>/dev/null))
	@if [ -z "$(IP)" ]; then \
		echo "Error: Could not get instance IP. Make sure infrastructure is deployed."; \
		exit 1; \
	fi
	ssh -o StrictHostKeyChecking=no ubuntu@$(IP)

ssh-prd:
	@echo "Connecting to production EC2 instance..."
	$(eval IP := $(shell cd $(TF_DIR)/prd && terraform output -raw instance_public_ips | head -n1 2>/dev/null))
	@if [ -z "$(IP)" ]; then \
		echo "Error: Could not get instance IP. Make sure infrastructure is deployed."; \
		exit 1; \
	fi
	ssh -o StrictHostKeyChecking=no ubuntu@$(IP)

.DEFAULT_GOAL := help
