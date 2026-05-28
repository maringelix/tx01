###############################################################################
# GitHub Actions OIDC for AWS
#
# Creates (or reuses) the GitHub OIDC provider in AWS and a single IAM role that
# GitHub Actions workflows in a given repository can assume via OIDC, removing
# the need for long-lived AWS access keys in secrets.
#
# Wire from a root module with:
#
#   module "github_oidc" {
#     source                  = "../modules/iam-github-actions"
#     github_repository       = "maringelix/tx01"
#     allowed_refs            = ["ref:refs/heads/main", "environment:prd"]
#     role_name               = "github-actions-tx01-prd"
#     managed_policy_arns     = [aws_iam_policy.tx01_workflow.arn]
#     create_oidc_provider    = true   # set false if another module/account
#                                      # already created the provider
#   }
#
# Outputs the role ARN to publish as GitHub Actions variable
# `AWS_DEPLOY_ROLE_ARN`.
###############################################################################

locals {
  github_oidc_url = "https://token.actions.githubusercontent.com"
  github_aud      = "sts.amazonaws.com"

  # GitHub Actions OIDC thumbprint -- documented at
  # https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services#adding-the-identity-provider-to-aws
  # The thumbprint is required even though AWS now validates the cert chain.
  github_thumbprints = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd",
  ]
}

data "aws_iam_openid_connect_provider" "existing" {
  count = var.create_oidc_provider ? 0 : 1
  url   = local.github_oidc_url
}

resource "aws_iam_openid_connect_provider" "github" {
  count           = var.create_oidc_provider ? 1 : 0
  url             = local.github_oidc_url
  client_id_list  = [local.github_aud]
  thumbprint_list = local.github_thumbprints

  tags = var.tags
}

locals {
  provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : data.aws_iam_openid_connect_provider.existing[0].arn
}

data "aws_iam_policy_document" "trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = [local.github_aud]
    }

    # Restrict to specific refs/environments inside the repository. Examples
    # of allowed_refs entries:
    #   "ref:refs/heads/main"
    #   "environment:prd"
    #   "pull_request"
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [for r in var.allowed_refs : "repo:${var.github_repository}:${r}"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name                 = var.role_name
  description          = "Assumed by GitHub Actions OIDC from ${var.github_repository}"
  assume_role_policy   = data.aws_iam_policy_document.trust.json
  max_session_duration = var.max_session_duration

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each   = toset(var.managed_policy_arns)
  role       = aws_iam_role.github_actions.name
  policy_arn = each.value
}
