output "rds_addr" {
  value       = "postgresql://dbadmin:ChangeMe123456!@${aws_db_instance.fastApi_rds.address}:5432/fastApi_db"
  description = "RDS_DATABASE_ADDRESS"
}
output "rds_endpoint" {
  value       = aws_db_instance.fastApi_rds.endpoint
  description = "RDS_DATABASE_ENDPOINT"
}
output "n8n_url" {
  description = "Public n8n URL. Make sure this hostname has a Route53 alias/CNAME pointing to the ALB."
  value       = "https://${var.frontend_domain_name}"
}
