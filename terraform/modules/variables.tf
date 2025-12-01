variable "project_name" {
  description = "Nome do projeto"
  type        = string
}

variable "environment" {
  description = "Environment (stg/prd)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
  default     = ""
}

variable "ssh_public_key" {
  description = "SSH public key content (optional, will use file if not provided)"
  type        = string
  default     = ""
}

variable "waf_ip_whitelist" {
  description = "IP whitelist for WAF"
  type        = list(string)
  default     = []
}

variable "docker_image_tag" {
  description = "Docker image tag"
  type        = string
  default     = "latest"
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "instance_count" {
  description = "Number of EC2 instances to launch"
  type        = number
  default     = 2
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# Database Variables
variable "db_allocated_storage" {
  description = "Allocated storage for RDS in GB"
  type        = number
  default     = 20
}

variable "db_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "17.6"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.micro"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "tx01db"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "tx01admin"
}

variable "db_backup_retention_period" {
  description = "Number of days to retain database backups"
  type        = number
  default     = 7
}

# EKS Variables
variable "enable_eks" {
  description = "Enable EKS cluster creation"
  type        = bool
  default     = false
}

variable "eks_node_instance_type" {
  description = "Instance type for EKS nodes"
  type        = string
  default     = "t3.small"
}

variable "eks_node_desired_size" {
  description = "Desired number of nodes in EKS node group"
  type        = number
  default     = 2
}

variable "eks_node_min_size" {
  description = "Minimum number of nodes in EKS node group"
  type        = number
  default     = 1
}

variable "eks_node_max_size" {
  description = "Maximum number of nodes in EKS node group"
  type        = number
  default     = 4
}

variable "iam_user_arn" {
  description = "ARN of the IAM user to grant Kubernetes access"
  type        = string
  default     = ""
}

variable "iam_user_name" {
  description = "Name of the IAM user to grant Kubernetes access"
  type        = string
  default     = ""
}
