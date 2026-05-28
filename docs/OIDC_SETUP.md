# OIDC Setup — tx01 (AWS)

GitHub Actions in this repo no longer use `AWS_ACCESS_KEY_ID` /
`AWS_SECRET_ACCESS_KEY`. Authentication uses **OpenID Connect (OIDC)** with
short-lived STS credentials via `aws-actions/configure-aws-credentials@v4` and
`role-to-assume`.

## What changed

- All workflows include:

  ```yaml
  permissions:
    contents: read
    id-token: write
  ```

- Every `aws-actions/configure-aws-credentials` step now uses
  `role-to-assume: ${{ vars.AWS_DEPLOY_ROLE_ARN }}` instead of long-lived keys.
- A reusable Terraform module is provided under
  [`terraform/modules/iam-github-actions`](../terraform/modules/iam-github-actions/main.tf).

## Bootstrap (one-time per AWS account)

Requires a human/operator with `iam:*` and `sts:*` permissions.

1. **Wire the module** from a root config (example for `terraform/prd/main.tf`):

   ```hcl
   module "github_oidc" {
     source            = "../modules/iam-github-actions"
     github_repository = "maringelix/tx01"
     allowed_refs = [
       "ref:refs/heads/main",
       "environment:prd",
     ]
     role_name           = "github-actions-tx01-prd"
     managed_policy_arns = [
       # Replace with least-privilege managed policies or a dedicated
       # customer-managed policy ARN.
       "arn:aws:iam::aws:policy/PowerUserAccess",
     ]
   }

   output "github_actions_role_arn" {
     value = module.github_oidc.role_arn
   }
   ```

2. `terraform apply` — creates the OIDC provider (if absent) and the IAM role.

3. **Publish the role ARN as a GitHub Actions variable** (not a secret — the
   ARN is not sensitive and `${{ vars.* }}` is what the workflows reference):

   ```bash
   gh variable set AWS_DEPLOY_ROLE_ARN \
     --repo maringelix/tx01 \
     --body "$(terraform output -raw github_actions_role_arn)"
   ```

4. **Remove the legacy secrets** from the repository:

   ```bash
   gh secret delete AWS_ACCESS_KEY_ID --repo maringelix/tx01
   gh secret delete AWS_SECRET_ACCESS_KEY --repo maringelix/tx01
   ```

## Trust policy reminder

The trust policy restricts `token.actions.githubusercontent.com:sub` to a
list of `repo:maringelix/tx01:<ref-or-environment>` values. Wildcard subjects
(`repo:owner/repo:*`) are rejected by the module's variable validation.

## Permission scopes per workflow

`permissions:` is set at the **workflow level** to the minimum required:

- `contents: read` — required by `actions/checkout`.
- `id-token: write` — required to mint the OIDC token presented to STS.

Workflows that previously needed `pull-requests: write` (e.g. `terraform-plan`)
keep that scope in addition to `id-token: write`.
