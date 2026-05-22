# GitHub Actions AWS OIDC Bootstrap

This Terraform root module creates the AWS IAM role used by GitHub Actions to deploy this project without long-lived AWS access keys.

The GitHub Actions OIDC provider is expected to already exist in the AWS account:

```text
token.actions.githubusercontent.com
```

This module reads that provider as a data source and creates a dedicated IAM role for this repository/pipeline.

## Production Model

Recommended AWS/GitHub OIDC layout:

```text
One shared IAM OIDC provider per AWS account
  token.actions.githubusercontent.com

One IAM role per repo/pipeline/environment
  github-actions-fastapi-terraform-deploy
```

Sharing one OIDC provider across many pipelines is normal for corporate and production AWS accounts. The security boundary is each IAM role trust policy, not the provider itself.

This module scopes the role trust to this repository and branch by default:

```text
repo:dantejauregui/aws_vpcHA_publicALB_FastAPI_ecsFargate_RDS_OpenTelemetry:ref:refs/heads/main
```

## What It Creates

- an IAM role for GitHub Actions deployments
- IAM managed policy attachment(s) for that role
- Terraform outputs for the GitHub Actions workflow

It does not create the OIDC provider. It uses:

```hcl
data "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"
}
```

Default role:

```text
github-actions-fastapi-terraform-deploy
```

Default policy attachment:

```text
AdministratorAccess
```

That is acceptable for bootstrap and learning velocity. For production, replace `managed_policy_arns` with a narrower Terraform deployment policy.

## Backend

This stack can use an S3 backend, configured in `backend.tf`.

If you change the backend bucket, key, or region and Terraform shows:

```text
Backend configuration changed
```

use one of these:

```bash
terraform init -reconfigure
```

Use `-reconfigure` when you want Terraform to accept the new backend config without trying to migrate old state.

```bash
terraform init -migrate-state
```

Use `-migrate-state` when you intentionally want Terraform to copy existing state from the old backend to the new backend.

For this bootstrap stack, `-reconfigure` is usually fine if you are intentionally starting with a new S3 state location.

## Before Apply

Authenticate to AWS:

```bash
aws sso login --profile infra-dev-admin
```

Confirm you are in the expected AWS account:

```bash
AWS_PROFILE=infra-dev-admin aws sts get-caller-identity
```

Confirm the GitHub OIDC provider exists:

```bash
AWS_PROFILE=infra-dev-admin aws iam list-open-id-connect-providers \
  --query "OpenIDConnectProviderList[?contains(Arn, 'token.actions.githubusercontent.com')].Arn" \
  --output text
```

Inspect the provider:

```bash
AWS_PROFILE=infra-dev-admin aws iam get-open-id-connect-provider \
  --open-id-connect-provider-arn arn:aws:iam::<account-id>:oidc-provider/token.actions.githubusercontent.com
```

## Run Terraform

From this folder:

```bash
cd bootstrap/githubActions-auth-oidc
```

Initialize:

```bash
AWS_PROFILE=infra-dev-admin terraform init
```

If you recently changed `backend.tf`:

```bash
AWS_PROFILE=infra-dev-admin terraform init -reconfigure
```

Plan:

```bash
AWS_PROFILE=infra-dev-admin terraform plan \
  -var="profile=infra-dev-admin"
```

Apply:

```bash
AWS_PROFILE=infra-dev-admin terraform apply \
  -var="profile=infra-dev-admin"
```

## Branches And Environments

The default trust policy allows only `main`:

```text
repo:dantejauregui/aws_vpcHA_publicALB_FastAPI_ecsFargate_RDS_OpenTelemetry:ref:refs/heads/main
```

If your workflow deploys from another branch, override `allowed_refs`.

Example for a `dev` branch:

```bash
AWS_PROFILE=infra-dev-admin terraform apply \
  -var="profile=infra-dev-admin" \
  -var='allowed_refs=["repo:dantejauregui/aws_vpcHA_publicALB_FastAPI_ecsFargate_RDS_OpenTelemetry:ref:refs/heads/dev"]'
```

For GitHub Environment-based deployments, the subject usually looks like:

```text
repo:<github_owner>/<github_repo>:environment:<environment-name>
```

Example:

```bash
AWS_PROFILE=infra-dev-admin terraform apply \
  -var="profile=infra-dev-admin" \
  -var='allowed_refs=["repo:dantejauregui/aws_vpcHA_publicALB_FastAPI_ecsFargate_RDS_OpenTelemetry:environment:prod"]'
```

## Existing Role

If the role already exists in AWS but is not in this Terraform state, import it:

```bash
AWS_PROFILE=infra-dev-admin terraform import \
  aws_iam_role.github_actions_deploy \
  github-actions-fastapi-terraform-deploy
```

If the managed policy attachment already exists, import it too:

```bash
AWS_PROFILE=infra-dev-admin terraform import \
  'aws_iam_role_policy_attachment.github_actions_deploy["arn:aws:iam::aws:policy/AdministratorAccess"]' \
  github-actions-fastapi-terraform-deploy/arn:aws:iam::aws:policy/AdministratorAccess
```

The OIDC provider is a data source in this stack, so it should not be imported here.

## Outputs

After apply:

```bash
terraform output github_actions_role_arn
terraform output github_actions_configure_aws_credentials_step
terraform output github_actions_environment_variables
```

The most important output is the role ARN:

```text
arn:aws:iam::<account-id>:role/github-actions-fastapi-terraform-deploy
```

## GitHub Actions Usage

Your workflow must include this permission:

```yaml
permissions:
  contents: read
  packages: write
  id-token: write
```

Then add AWS authentication before any AWS CLI or Terraform commands:

```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v5
  with:
    role-to-assume: ${{ vars.AWS_ROLE_TO_ASSUME }}
    aws-region: ${{ vars.AWS_REGION }}
```

Recommended GitHub repository variables:

```text
AWS_REGION         = eu-central-1
AWS_ROLE_TO_ASSUME = arn:aws:iam::<account-id>:role/github-actions-fastapi-terraform-deploy
```

You can also paste the role ARN directly instead of using repository variables.

## Console Checks

To verify in the AWS Console:

```text
IAM -> Identity providers -> token.actions.githubusercontent.com
IAM -> Roles -> github-actions-fastapi-terraform-deploy
```

In the role trust relationship, confirm the condition includes your GitHub repo and branch/environment.

## Destroy

Destroy only removes resources managed by this stack, such as the IAM role and its policy attachments:

```bash
AWS_PROFILE=infra-dev-admin terraform destroy \
  -var="profile=infra-dev-admin"
```

It will not destroy the shared GitHub OIDC provider because this stack only reads it as a data source.

