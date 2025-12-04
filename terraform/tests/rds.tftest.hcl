# RDS Module Tests

run "rds_instance" {
  command = plan

  assert {
    condition     = length(aws_db_instance.main) > 0
    error_message = "RDS instance must be created"
  }

  assert {
    condition     = aws_db_instance.main[0].engine == "postgres"
    error_message = "Database engine must be PostgreSQL"
  }

  assert {
    condition     = can(regex("^17\\.", aws_db_instance.main[0].engine_version))
    error_message = "PostgreSQL version should be 17.x"
  }
}

run "rds_storage" {
  command = plan

  assert {
    condition     = aws_db_instance.main[0].allocated_storage >= 20
    error_message = "Minimum storage must be 20GB"
  }

  assert {
    condition     = aws_db_instance.main[0].storage_type == "gp3"
    error_message = "Storage type should be gp3 for better performance"
  }

  assert {
    condition     = aws_db_instance.main[0].storage_encrypted == true
    error_message = "RDS storage must be encrypted"
  }
}

run "rds_backup" {
  command = plan

  assert {
    condition     = aws_db_instance.main[0].backup_retention_period >= 7
    error_message = "Backup retention must be at least 7 days"
  }

  assert {
    condition     = aws_db_instance.main[0].backup_window != null
    error_message = "Backup window must be configured"
  }
}

run "rds_multi_az" {
  command = plan

  variables {
    environment = "prd"
  }

  assert {
    condition     = aws_db_instance.main[0].multi_az == true
    error_message = "Multi-AZ must be enabled for production"
  }
}

run "rds_security_group" {
  command = plan

  assert {
    condition     = length(aws_security_group.rds) > 0
    error_message = "RDS security group must exist"
  }

  assert {
    condition     = length(aws_security_group_rule.rds_from_eks) > 0 || var.enable_eks == false
    error_message = "RDS must allow access from EKS when EKS is enabled"
  }
}

run "rds_parameter_group" {
  command = plan

  assert {
    condition     = length(aws_db_parameter_group.main) > 0
    error_message = "DB parameter group must be configured"
  }
}

run "rds_subnet_group" {
  command = plan

  assert {
    condition     = length(aws_db_subnet_group.main) > 0
    error_message = "DB subnet group must exist"
  }

  assert {
    condition     = length(aws_db_subnet_group.main[0].subnet_ids) >= 2
    error_message = "At least 2 subnets required for RDS"
  }
}
