resource "aws_security_group" "fastApi_ecs_sg" {
  name        = "${var.project_name}_ecs"
  description = "Allow all outbound traffic"
  vpc_id      = aws_vpc.fastApi_vpc.id

  ingress {
    description     = "what inbound port ALB can access on ECS tasks (must match container runtime port)"
    from_port       = var.container_port
    to_port         = var.container_port
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
      image     = "ghcr.io/dantejauregui/fastapi1:24"
      essential = true
      portMappings = [
        {
          # What port the app listens on INSIDE the container (must match uvicorn --port XXXX):
          containerPort = var.container_port

          hostPort = var.container_port
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
        {
          name  = "DB_HOST"
          value = aws_db_instance.fastApi_rds.address
        },
        {
          name  = "DB_PORT"
          value = "5432"
        },
        {
          name  = "DB_NAME"
          value = "fastApi_db"
        },
        {
          name  = "DB_USER"
          value = "dbadmin"
        },
        {
          name  = "DB_PASSWORD"
          value = "ChangeMe123"
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "fastApi_ecs_service" {
  name                   = "${var.project_name}_ecs_service"
  cluster                = aws_ecs_cluster.fastApi_ecs_cluster.id
  task_definition        = aws_ecs_task_definition.fastApi_ecs_task_definition.arn
  desired_count          = 2
  launch_type            = "FARGATE"
  enable_execute_command = true #enables ECS EXEC

  network_configuration {
    subnets = [
      aws_subnet.fastApi_sn_private_1.id,
      aws_subnet.fastApi_sn_private_2.id
    ]
    assign_public_ip = false
    security_groups  = [aws_security_group.fastApi_ecs_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.fastApi_alb_tg.arn
    container_name   = "fastApi_dockerHub_image"
    container_port   = var.container_port
  }

  depends_on = [aws_lb_listener.fastApi_alb_listener]
}
