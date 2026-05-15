resource "aws_security_group" "fastApi_alb_ecs" {
  name        = "${var.project_name}_ecs"
  description = "Allow all outbound traffic"
  vpc_id      = aws_vpc.fastApi_vpc.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.fastApi_alb_sg.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_cloudwatch_log_group" "fastApi_logs" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 7
}

resource "aws_ecs_cluster" "fastApi_ecs_cluster" {
  name = "${var.project_name}_ecs"

  #   setting {
  #     name  = "containerInsights"
  #     value = "enabled"
  #   }
}

resource "aws_ecs_task_definition" "fastApi_ecs_task_definition" {
  family                   = "service"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
  container_definitions = jsonencode([
    {
      name      = "fastApi_dockerHub_image"
      image     = "nginx:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.fastApi_logs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
      environment = [
        { name = "TEST_VAR", value = "test" }
      ]
    }
  ])
}

resource "aws_ecs_service" "fastApi_ecs_service" {
  name            = "${var.project_name}_ecs_service"
  cluster         = aws_ecs_cluster.fastApi_ecs_cluster.id
  task_definition = aws_ecs_task_definition.fastApi_ecs_task_definition.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets = [
      aws_subnet.fastApi_sn_private_1.id,
      aws_subnet.fastApi_sn_private_2.id
    ]
    assign_public_ip = false
    security_groups  = [aws_security_group.fastApi_alb_ecs.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.fastApi_alb_tg.arn
    container_name   = "fastApi_dockerHub_image"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.fastApi_alb_listener]
}
