variable "profile" {
  description = "Local AWS CLI profile used when running this bootstrap stack."
  type        = string
  default     = "infra-dev-admin"
}

variable "aws_region" {
  description = "AWS region used by the provider and emitted for GitHub Actions."
  type        = string
  default     = "eu-central-1"
}

variable "github_owner" {
  description = "GitHub organization or username that owns the repository."
  type        = string
  default     = "dantejauregui"
}

variable "github_repo" {
  description = "GitHub repository name allowed to assume the AWS deploy role."
  type        = string
  default     = "aws_vpcHA_publicALB_FastAPI_ecsFargate_RDS_OpenTelemetry"
}

variable "allowed_refs" {
  description = "Git refs allowed to assume the role. Example: repo:owner/repo:ref:refs/heads/main"
  type        = list(string)
  default = [
    "repo:dantejauregui/aws_vpcHA_publicALB_FastAPI_ecsFargate_RDS_OpenTelemetry:ref:refs/heads/main"
  ]
}

variable "role_name" {
  description = "IAM role name created for GitHub Actions deployments."
  type        = string
  default     = "github-actions-fastapi-terraform-deploy"
}

variable "managed_policy_arns" {
  description = "Managed policies attached to the GitHub Actions role. Replace AdministratorAccess with a narrower policy when ready."
  type        = list(string)
  default = [
    "arn:aws:iam::aws:policy/AdministratorAccess"
  ]
}

variable "max_session_duration" {
  description = "Maximum role session duration in seconds."
  type        = number
  default     = 3600
}

variable "tags" {
  description = "Tags applied to bootstrap resources."
  type        = map(string)
  default = {
    Project   = "fastapi-ecs-rds-opentelemetry"
    ManagedBy = "Terraform"
    Purpose   = "github-actions-oidc"
  }
}

