resource "aws_security_group" "fastApi_alb_sg" {
  name        = "${var.project_name}_sg"
  description = "Allow all outbound traffic"
  vpc_id      = aws_vpc.fastApi_vpc.id

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

resource "aws_lb_target_group" "fastApi_alb_tg" {
  name        = "${var.project_name}-alb-tg"
  port        = 80
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

resource "aws_lb_listener" "fastApi_alb_listener" {
  load_balancer_arn = aws_lb.fastApi_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fastApi_alb_tg.arn
  }
}

