# RDS PostgreSQL Database Module
# Free Tier: t4g.micro, 20GB storage, PostgreSQL 15

# DB Subnet Group (private subnets)
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group-${var.environment}"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${var.project_name}-db-subnet-group-${var.environment}"
  }
}

# Security Group for RDS
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg-${var.environment}"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = aws_vpc.main.id

  # Allow PostgreSQL access from EC2 instances only
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
    description     = "PostgreSQL from EC2 instances"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name = "${var.project_name}-rds-sg-${var.environment}"
  }
}

# Random password for database
resource "random_password" "db_password" {
  length  = 32
  special = true
  # Avoid characters that might cause issues in connection strings
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Secrets Manager for database credentials
resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "${var.project_name}-db-credentials-${var.environment}-v2"
  description             = "RDS database credentials for ${var.environment}"
  recovery_window_in_days = var.environment == "prd" ? 30 : 0

  tags = {
    Name = "${var.project_name}-db-secret-${var.environment}"
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = "dbadmin"
    password = random_password.db_password.result
    engine   = "postgres"
    host     = aws_db_instance.main.address
    port     = 5432
    dbname   = "${var.project_name}_${var.environment}"
  })
}

# RDS PostgreSQL Instance
resource "aws_db_instance" "main" {
  identifier     = "${var.project_name}-db-${var.environment}"
  engine         = "postgres"
  engine_version = "15.5"

  # Free Tier: t4g.micro (ARM-based, better performance than t3.micro)
  instance_class = var.environment == "prd" ? "db.t4g.micro" : "db.t4g.micro"

  # Storage: Free Tier allows up to 20GB
  allocated_storage     = 20
  max_allocated_storage = var.environment == "prd" ? 100 : 20
  storage_type          = "gp3"
  storage_encrypted     = true

  # Database configuration
  db_name  = "${var.project_name}_${var.environment}"
  username = "dbadmin"
  password = random_password.db_password.result

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false # IMPORTANT: Keep in private subnet
  multi_az               = false  # Multi-AZ not in free tier

  # Backup configuration
  backup_retention_period = var.environment == "prd" ? 7 : 1
  backup_window           = "03:00-04:00"
  maintenance_window      = "mon:04:00-mon:05:00"
  skip_final_snapshot     = var.environment == "stg" ? true : false
  final_snapshot_identifier = var.environment == "prd" ? "${var.project_name}-db-final-snapshot-${var.environment}-${formatdate("YYYY-MM-DD-hhmm", timestamp())}" : null

  # Enhanced monitoring (optional, not free tier)
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  
  # Performance Insights (not in free tier, disable for staging)
  performance_insights_enabled = false

  # Automatic minor version upgrades
  auto_minor_version_upgrade = true

  # Deletion protection for production
  deletion_protection = var.environment == "prd" ? true : false

  # Parameter group for PostgreSQL tuning
  parameter_group_name = aws_db_parameter_group.main.name

  tags = {
    Name        = "${var.project_name}-db-${var.environment}"
    Environment = var.environment
  }

  lifecycle {
    ignore_changes = [
      final_snapshot_identifier,
      password # Password managed by Secrets Manager
    ]
  }
}

# DB Parameter Group for PostgreSQL optimization
resource "aws_db_parameter_group" "main" {
  name   = "${var.project_name}-pg15-params-${var.environment}"
  family = "postgres15"

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  parameter {
    name  = "log_duration"
    value = "1"
  }

  parameter {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements"
  }

  tags = {
    Name = "${var.project_name}-pg15-params-${var.environment}"
  }
}

# CloudWatch Log Group for RDS logs
resource "aws_cloudwatch_log_group" "rds" {
  name              = "/aws/rds/instance/${var.project_name}-db-${var.environment}/postgresql"
  retention_in_days = var.environment == "prd" ? 30 : 7

  tags = {
    Name = "${var.project_name}-rds-logs-${var.environment}"
  }
}

# Outputs
output "db_instance_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "db_instance_address" {
  description = "RDS instance address"
  value       = aws_db_instance.main.address
  sensitive   = true
}

output "db_instance_name" {
  description = "Database name"
  value       = aws_db_instance.main.db_name
}

output "db_secret_arn" {
  description = "ARN of the Secrets Manager secret containing DB credentials"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "db_security_group_id" {
  description = "Security Group ID for RDS"
  value       = aws_security_group.rds.id
}
