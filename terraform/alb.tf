resource "aws_security_group" "fastApi_alb_sg" {
  name        = "${var.project_name}_sg"
  description = "Allow all outbound traffic"
  vpc_id      = aws_vpc.fastApi_vpc.id

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "fastApi_alb" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.fastApi_alb_sg.id]
  subnets = [
    aws_subnet.fastApi_sn_public_1.id,
    aws_subnet.fastApi_sn_public_2.id
  ]

  enable_deletion_protection = false
}

# ALB HTTPS listener :443
resource "aws_lb_listener" "fastApi_alb_https_listener" {
  load_balancer_arn = aws_lb.fastApi_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = data.aws_acm_certificate.wildcard.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fastApi_alb_tg.arn
  }
}
# ALB HTTP listener :80  - redirects insecure traffic from HTTP to HTTPS:
resource "aws_lb_listener" "fastApi_alb_listener" {
  load_balancer_arn = aws_lb.fastApi_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}


# =========================
# For BACKEND ECS:
# =========================

# route secure backend traffic to backend fastApi container:
resource "aws_lb_listener_rule" "fastapi_https_host" {
  listener_arn = aws_lb_listener.fastApi_alb_https_listener.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fastApi_alb_tg.arn
  }

  condition {
    host_header {
      values = [var.backend_domain_name]
    }
  }
}

resource "aws_lb_target_group" "fastApi_alb_tg" {
  name = "${var.project_name}-alb-tg"
  # What port ALB forwards traffic to (this should match the ecs container application port):
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.fastApi_vpc.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
  }
}


# =========================
# For FRONTEND ECS:
# =========================

# route secure frontend traffic to frontend container:
resource "aws_lb_listener_rule" "n8n_https_host" {
  listener_arn = aws_lb_listener.fastApi_alb_https_listener.arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.n8n_alb_tg.arn
  }

  condition {
    host_header {
      values = [var.frontend_domain_name]
    }
  }
}

resource "aws_lb_target_group" "n8n_alb_tg" {
  name        = "${var.project_name}-n8n-tg"
  port        = var.frontend_container_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.fastApi_vpc.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/healthz"
    protocol            = "HTTP"
    matcher             = "200-399"
  }
}
