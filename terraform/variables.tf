variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (stg or prd)"
  type        = string
  validation {
    condition     = contains(["stg", "prd"], var.environment)
    error_message = "Environment must be either 'stg' or 'prd'."
  }
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "tx01"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "instance_count" {
  description = "Number of EC2 instances"
  type        = number
  default     = 2
  validation {
    condition     = var.instance_count > 0 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10."
  }
}

variable "docker_image_tag" {
  description = "Docker image tag"
  type        = string
  default     = "latest"
}

variable "enable_waf" {
  description = "Enable WAF on ALB"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default = {
    Terraform   = "true"
    Owner       = "DevOps"
    ManagedBy   = "Terraform"
  }
}
