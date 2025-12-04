# EKS Module Tests

run "eks_cluster_exists" {
  command = plan

  variables {
    enable_eks = true
  }

  assert {
    condition     = var.enable_eks == true
    error_message = "EKS must be enabled for this test"
  }

  assert {
    condition     = length(aws_eks_cluster.main) > 0
    error_message = "EKS cluster must be created when enabled"
  }
}

run "eks_version" {
  command = plan

  variables {
    enable_eks = true
  }

  assert {
    condition     = can(regex("^1\\.(2[8-9]|3[0-9])", var.eks_version))
    error_message = "EKS version must be 1.28 or higher"
  }
}

run "eks_node_group" {
  command = plan

  variables {
    enable_eks = true
  }

  assert {
    condition     = length(aws_eks_node_group.main) > 0
    error_message = "At least one node group must exist"
  }

  assert {
    condition     = aws_eks_node_group.main[0].scaling_config[0].desired_size >= 2
    error_message = "Node group must have at least 2 nodes for HA"
  }

  assert {
    condition     = aws_eks_node_group.main[0].scaling_config[0].min_size >= 1
    error_message = "Minimum nodes must be at least 1"
  }

  assert {
    condition     = aws_eks_node_group.main[0].scaling_config[0].max_size >= 2
    error_message = "Maximum nodes must be at least 2"
  }
}

run "eks_security" {
  command = plan

  variables {
    enable_eks = true
  }

  assert {
    condition     = length(aws_security_group.eks_cluster) > 0
    error_message = "EKS cluster security group must exist"
  }

  assert {
    condition     = length(aws_security_group.eks_nodes) > 0
    error_message = "EKS nodes security group must exist"
  }
}

run "eks_iam_roles" {
  command = plan

  variables {
    enable_eks = true
  }

  assert {
    condition     = length(aws_iam_role.eks_cluster) > 0
    error_message = "EKS cluster IAM role must exist"
  }

  assert {
    condition     = length(aws_iam_role.eks_nodes) > 0
    error_message = "EKS nodes IAM role must exist"
  }
}

run "eks_disabled" {
  command = plan

  variables {
    enable_eks = false
  }

  assert {
    condition     = length(aws_eks_cluster.main) == 0
    error_message = "EKS cluster should not be created when disabled"
  }

  assert {
    condition     = length(aws_eks_node_group.main) == 0
    error_message = "EKS node group should not be created when disabled"
  }
}
