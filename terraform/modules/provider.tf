terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24"
    }
  }
}

# Configurar provider Kubernetes para se conectar ao cluster EKS
provider "kubernetes" {
  host                   = var.enable_eks ? aws_eks_cluster.main[0].endpoint : ""
  cluster_ca_certificate = var.enable_eks ? base64decode(aws_eks_cluster.main[0].certificate_authority[0].data) : ""

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      var.enable_eks ? aws_eks_cluster.main[0].name : "",
      "--region",
      var.aws_region
    ]
  }
}