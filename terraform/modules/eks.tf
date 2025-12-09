# EKS Cluster
resource "aws_eks_cluster" "main" {
  count = var.enable_eks ? 1 : 0
  
  name     = "${var.project_name}-eks-${var.environment}"
  role_arn = aws_iam_role.eks_cluster[0].arn
  version  = "1.32"

  vpc_config {
    subnet_ids              = aws_subnet.private[*].id
    endpoint_private_access = true
    endpoint_public_access  = true
    security_group_ids      = [aws_security_group.eks_cluster[0].id]
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator"]

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_cloudwatch_log_group.eks_cluster,
  ]

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-eks-${var.environment}"
    }
  )
}

# Security Group for EKS Node Group
resource "aws_security_group" "eks_nodes" {
  count = var.enable_eks ? 1 : 0
  
  name        = "${var.project_name}-eks-nodes-sg-${var.environment}"
  description = "Security group for EKS worker nodes"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-eks-nodes-sg-${var.environment}"
    }
  )
}

# Allow communication between nodes
resource "aws_security_group_rule" "eks_nodes_ingress_self" {
  count = var.enable_eks ? 1 : 0
  
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.eks_nodes[0].id
  description       = "Allow nodes to communicate with each other"
}

# Allow cluster control plane to communicate with nodes
resource "aws_security_group_rule" "eks_nodes_ingress_cluster" {
  count = var.enable_eks ? 1 : 0
  
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes[0].id
  source_security_group_id = aws_security_group.eks_cluster[0].id
  description              = "Allow cluster control plane to communicate with nodes"
}

# Launch Template for EKS Node Group
resource "aws_launch_template" "eks_nodes" {
  count = var.enable_eks ? 1 : 0
  
  name_prefix = "${var.project_name}-eks-node-${var.environment}-"
  description = "Launch template for EKS worker nodes"

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.eks_nodes[0].id]
    delete_on_termination       = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.tags,
      {
        Name = "${var.project_name}-eks-node-${var.environment}"
      }
    )
  }

  lifecycle {
    create_before_destroy = true
  }
}

# EKS Node Group
resource "aws_eks_node_group" "main" {
  count = var.enable_eks ? 1 : 0
  
  cluster_name    = aws_eks_cluster.main[0].name
  node_group_name = "${var.project_name}-ng-${var.environment}-${replace(var.eks_node_instance_type, ".", "-")}"
  node_role_arn   = aws_iam_role.eks_node[0].arn
  subnet_ids      = aws_subnet.private[*].id

  scaling_config {
    desired_size = var.eks_node_desired_size
    max_size     = var.eks_node_max_size
    min_size     = var.eks_node_min_size
  }

  instance_types = [var.eks_node_instance_type]
  capacity_type  = "ON_DEMAND" # ou "SPOT" para economizar
  disk_size      = 20

  update_config {
    max_unavailable = 1
  }

  labels = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  # Force replacement when instance type changes
  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_policy,
    aws_security_group_rule.eks_nodes_ingress_self,
    aws_security_group_rule.eks_nodes_ingress_cluster,
  ]

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-ng-${var.environment}"
    }
  )
}

# EKS Add-ons
resource "aws_eks_addon" "vpc_cni" {
  count = var.enable_eks ? 1 : 0
  
  cluster_name             = aws_eks_cluster.main[0].name
  addon_name               = "vpc-cni"
  addon_version            = "v1.19.0-eksbuild.1"  # Compatible with K8s 1.32
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  depends_on = [
    aws_eks_node_group.main
  ]

  tags = var.tags
}

resource "aws_eks_addon" "kube_proxy" {
  count = var.enable_eks ? 1 : 0
  
  cluster_name             = aws_eks_cluster.main[0].name
  addon_name               = "kube-proxy"
  addon_version            = "v1.32.0-eksbuild.2"  # Match K8s version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  depends_on = [
    aws_eks_node_group.main
  ]

  tags = var.tags
}

resource "aws_eks_addon" "coredns" {
  count = var.enable_eks ? 1 : 0
  
  cluster_name             = aws_eks_cluster.main[0].name
  addon_name               = "coredns"
  addon_version            = "v1.11.3-eksbuild.2"  # Compatible with K8s 1.32
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  depends_on = [
    aws_eks_node_group.main
  ]

  tags = var.tags
}

# EBS CSI Driver Add-on
resource "aws_eks_addon" "ebs_csi_driver" {
  count = var.enable_eks ? 1 : 0
  
  cluster_name             = aws_eks_cluster.main[0].name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.53.0-eksbuild.1"
  service_account_role_arn = aws_iam_role.ebs_csi_driver[0].arn
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  depends_on = [
    aws_eks_node_group.main,
    aws_iam_role.ebs_csi_driver
  ]

  tags = var.tags
}

# IAM Role for EBS CSI Driver
resource "aws_iam_role" "ebs_csi_driver" {
  count = var.enable_eks ? 1 : 0
  
  name = "${var.project_name}-eks-ebs-csi-driver"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks[0].arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eks[0].url, "https://", "")}:aud" = "sts.amazonaws.com"
            "${replace(aws_iam_openid_connect_provider.eks[0].url, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          }
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver_policy" {
  count = var.enable_eks ? 1 : 0
  
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver[0].name
}

# OIDC Provider for EKS (required for IRSA - IAM Roles for Service Accounts)
# Using fixed thumbprint as recommended by AWS for us-east-1
# https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc_verify-thumbprint.html
resource "aws_iam_openid_connect_provider" "eks" {
  count = var.enable_eks ? 1 : 0
  
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]  # Root CA thumbprint for EKS OIDC
  url             = aws_eks_cluster.main[0].identity[0].oidc[0].issuer

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-eks-oidc-${var.environment}"
    }
  )
}

# IAM Role for EKS Cluster
resource "aws_iam_role" "eks_cluster" {
  count = var.enable_eks ? 1 : 0
  
  name = "${var.project_name}-eks-cluster-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  count = var.enable_eks ? 1 : 0
  
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster[0].name
}

# IAM Role for EKS Node Group
resource "aws_iam_role" "eks_node" {
  count = var.enable_eks ? 1 : 0
  
  name = "${var.project_name}-eks-node-role-${var.environment}"

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

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "eks_node_policy" {
  count = var.enable_eks ? 1 : 0
  
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node[0].name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  count = var.enable_eks ? 1 : 0
  
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node[0].name
}

resource "aws_iam_role_policy_attachment" "eks_container_registry_policy" {
  count = var.enable_eks ? 1 : 0
  
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node[0].name
}

# Security Group for EKS Cluster
resource "aws_security_group" "eks_cluster" {
  count = var.enable_eks ? 1 : 0
  
  name        = "${var.project_name}-eks-cluster-sg-${var.environment}"
  description = "Security group for EKS cluster"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-eks-cluster-sg-${var.environment}"
    }
  )
}

# Allow ALB to communicate with EKS Pods
resource "aws_security_group_rule" "eks_cluster_alb_ingress" {
  count = var.enable_eks ? 1 : 0
  
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster[0].id
  source_security_group_id = aws_security_group.alb.id
  description              = "Allow ALB to communicate with EKS cluster"
}

# CloudWatch Log Group for EKS
resource "aws_cloudwatch_log_group" "eks_cluster" {
  count = var.enable_eks ? 1 : 0
  
  name              = "/aws/eks/${var.project_name}-eks-${var.environment}/cluster"
  retention_in_days = 7

  tags = var.tags
}

# IAM Role for AWS Load Balancer Controller
resource "aws_iam_role" "aws_load_balancer_controller" {
  count = var.enable_eks ? 1 : 0
  
  name = "${var.project_name}-alb-controller-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks[0].arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eks[0].url, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
            "${replace(aws_iam_openid_connect_provider.eks[0].url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_policy" "aws_load_balancer_controller" {
  count = var.enable_eks ? 1 : 0
  
  name        = "${var.project_name}-alb-controller-policy-${var.environment}"
  description = "Policy for AWS Load Balancer Controller"

  policy = file("${path.module}/../policies/alb-controller-policy.json")

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller" {
  count = var.enable_eks ? 1 : 0
  
  policy_arn = aws_iam_policy.aws_load_balancer_controller[0].arn
  role       = aws_iam_role.aws_load_balancer_controller[0].name
}

# Outputs
output "eks_cluster_id" {
  description = "EKS cluster ID"
  value       = var.enable_eks ? aws_eks_cluster.main[0].id : null
}

output "eks_cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = var.enable_eks ? aws_eks_cluster.main[0].endpoint : null
}

output "eks_cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = var.enable_eks ? aws_eks_cluster.main[0].vpc_config[0].cluster_security_group_id : null
}

output "eks_node_security_group_id" {
  description = "Security group ID for EKS worker nodes"
  value       = var.enable_eks ? aws_security_group.eks_nodes[0].id : null
}

output "eks_cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC Issuer"
  value       = var.enable_eks ? try(aws_eks_cluster.main[0].identity[0].oidc[0].issuer, null) : null
}

output "eks_node_group_id" {
  description = "EKS node group ID"
  value       = var.enable_eks ? aws_eks_node_group.main[0].id : null
}

# Kubernetes ConfigMap para aws-auth (manage existing ConfigMap created by EKS)
resource "kubernetes_config_map_v1_data" "aws_auth" {
  count = var.enable_eks && var.iam_user_arn != "" ? 1 : 0

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode([
      {
        rolearn  = aws_iam_role.eks_node[0].arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = ["system:bootstrappers", "system:nodes"]
      }
    ])
    mapUsers = yamlencode([
      {
        userarn  = var.iam_user_arn
        username = var.iam_user_name
        groups   = ["system:masters"]
      }
    ])
  }

  force = true

  depends_on = [
    aws_eks_cluster.main,
    aws_eks_node_group.main
  ]
}

# ClusterRoleBinding para console AWS (permite visualizar nodes e recursos no console)
resource "kubernetes_cluster_role_binding_v1" "console_admin" {
  count = var.enable_eks && var.iam_user_name != "" ? 1 : 0

  metadata {
    name = "console-admin-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "User"
    name      = var.iam_user_name
    api_group = "rbac.authorization.k8s.io"
  }

  depends_on = [
    kubernetes_config_map_v1_data.aws_auth
  ]
}

output "aws_load_balancer_controller_role_arn" {
  description = "ARN of IAM role for AWS Load Balancer Controller"
  value       = var.enable_eks ? aws_iam_role.aws_load_balancer_controller[0].arn : null
}