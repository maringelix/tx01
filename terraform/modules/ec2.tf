# Data source para a AMI mais recente do Ubuntu
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# User data script para instalar Docker e puxar imagem
locals {
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    ecr_registry  = split("/", aws_ecr_repository.main.repository_url)[0]
    docker_image  = "${var.project_name}-nginx:${var.docker_image_tag}"
    environment   = var.environment
    aws_region    = var.aws_region
  }))
}

# IAM Role para EC2
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ec2-role-${var.environment}"
  }
}

# IAM Policy para acesso ao ECR
resource "aws_iam_role_policy" "ecr_access" {
  name   = "${var.project_name}-ecr-access-${var.environment}"
  role   = aws_iam_role.ec2_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchDownloadLayerDigest"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile-${var.environment}"
  role = aws_iam_role.ec2_role.name
}

# EC2 Instances
resource "aws_instance" "web" {
  count                    = var.instance_count
  ami                      = data.aws_ami.ubuntu.id
  instance_type            = var.instance_type
  subnet_id                = aws_subnet.public[count.index % 2].id
  vpc_security_group_ids   = [aws_security_group.ec2.id]
  iam_instance_profile     = aws_iam_instance_profile.ec2_profile.name
  user_data                = local.user_data
  associate_public_ip_address = true
  key_name                 = "tx01-deploy-key"

  monitoring = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = {
    Name = "${var.project_name}-ec2-${count.index + 1}-${var.environment}"
  }

  depends_on = [aws_nat_gateway.main]
}

# CloudWatch Log Group para EC2
resource "aws_cloudwatch_log_group" "ec2" {
  name              = "/aws/ec2/${var.project_name}-${var.environment}"
  retention_in_days = var.environment == "prd" ? 30 : 7

  tags = {
    Name = "${var.project_name}-logs-${var.environment}"
  }
}

# Outputs
output "instance_ids" {
  description = "EC2 Instance IDs"
  value       = aws_instance.web[*].id
}

output "instance_private_ips" {
  description = "EC2 Instance Private IPs"
  value       = aws_instance.web[*].private_ip
}

output "instance_public_ips" {
  description = "EC2 Instance Public IPs"
  value       = aws_instance.web[*].public_ip
}
