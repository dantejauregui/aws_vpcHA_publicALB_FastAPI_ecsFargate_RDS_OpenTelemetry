output "aws_account_id" {
  description = "AWS account where the GitHub Actions OIDC provider and deploy role were created."
  value       = data.aws_caller_identity.current.account_id
}

output "github_actions_oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC provider."
  value       = data.aws_iam_openid_connect_provider.github_actions.arn
}

output "github_actions_role_arn" {
  description = "IAM role ARN to use in GitHub Actions with aws-actions/configure-aws-credentials."
  value       = aws_iam_role.github_actions_deploy.arn
}

output "github_actions_required_permissions" {
  value = {
    "id-token" = "write"
    contents   = "read"
    packages   = "write"
  }
}

output "github_actions_configure_aws_credentials_step" {
  description = "GitHub Actions step to assume the AWS role through OIDC."
  value       = <<-YAML
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v5
      with:
        role-to-assume: ${aws_iam_role.github_actions_deploy.arn}
        aws-region: ${var.aws_region}
  YAML
}

output "github_actions_environment_variables" {
  description = "Convenient values to add as GitHub Actions variables if you prefer referencing vars in YAML."
  value = {
    AWS_REGION          = var.aws_region
    AWS_ROLE_TO_ASSUME  = aws_iam_role.github_actions_deploy.arn
    AWS_ACCOUNT_ID      = data.aws_caller_identity.current.account_id
    GITHUB_REPOSITORY   = "${var.github_owner}/${var.github_repo}"
    GITHUB_ALLOWED_REFS = var.allowed_refs
  }
}

