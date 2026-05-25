# Data source to get the manually created "Hosted zone"
data "aws_route53_zone" "main" {
  name         = "dntgrowth.xyz"
  private_zone = false
}

# A record for backend subdomain and connected to ALB
resource "aws_route53_record" "backend" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.backend_domain_name
  type    = "A"

  alias {
    name                   = aws_lb.fastApi_alb.dns_name
    zone_id                = aws_lb.fastApi_alb.zone_id
    evaluate_target_health = true
  }
}

# A record for frontend subdomain and connected to ALB
resource "aws_route53_record" "frontend" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.frontend_domain_name
  type    = "A"

  alias {
    name                   = aws_lb.fastApi_alb.dns_name
    zone_id                = aws_lb.fastApi_alb.zone_id
    evaluate_target_health = true
  }
}

# Data source to get my manually created "ACM certificate" (as wildcard) 
data "aws_acm_certificate" "wildcard" {
  domain      = "*.dntgrowth.xyz"
  most_recent = true
  statuses    = ["ISSUED"]
}
