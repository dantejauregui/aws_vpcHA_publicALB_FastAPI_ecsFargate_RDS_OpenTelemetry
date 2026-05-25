variable "vpc_cidr" {
  type        = string
  description = "CIDR for VPC"
  default     = "10.0.0.0/16"
}

# Project Name
variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "fastApi"
}

# Environment
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

# AWS Region
variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

# FastApi (Backend) Port
variable "container_port" {
  type    = number
  default = 8000
}
# FastApi (Backend) DNS Domain URL
variable "backend_domain_name" {
  description = "Public hostname for fastApi Backend. This hostname must point to the existing ALB."
  type        = string
  default     = "backend.dntgrowth.xyz"
}

# Frontend Port
variable "frontend_container_port" {
  type    = number
  default = 5678
}
# Frontend DNS Domain URL
variable "frontend_domain_name" {
  description = "Public hostname for Fronted. This hostname must point to the existing ALB."
  type        = string
  default     = "frontend.dntgrowth.xyz"
}
