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
