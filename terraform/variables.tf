variable "vpc_cidr" {
  type        = string
  description = "CIDR for VPC"
  default     = "10.0.0.0/16"
}

# Project Name
variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "fastApi-app"
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

# FastApi Port
variable "container_port" {
  type    = number
  default = 8000
}
