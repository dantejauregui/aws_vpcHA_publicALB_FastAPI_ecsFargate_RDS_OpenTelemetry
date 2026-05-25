resource "random_password" "n8n_encryption_key" {
  length  = 32
  special = false
}

resource "aws_security_group" "n8n_ecs_sg" {
  name        = "${var.project_name}_n8n_ecs"
  description = "Allow ALB access to n8n ECS tasks"
  vpc_id      = aws_vpc.fastApi_vpc.id

  ingress {
    description     = "n8n HTTP from ALB"
    from_port       = var.frontend_container_port
    to_port         = var.frontend_container_port
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

resource "aws_cloudwatch_log_group" "n8n_logs" {
  name              = "/ecs/${var.project_name}/frontend"
  retention_in_days = 3
}

resource "aws_ecs_task_definition" "n8n_ecs_task_definition" {
  family                   = "frontend-service"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name      = "n8n"
      image     = "docker.n8n.io/n8nio/n8n:latest"
      essential = true

      portMappings = [
        {
          containerPort = var.frontend_container_port
          hostPort      = var.frontend_container_port
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.n8n_logs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }

      environment = [
        {
          name  = "NODE_ENV"
          value = "production"
        },
        {
          name  = "N8N_HOST"
          value = var.frontend_domain_name
        },
        {
          name  = "N8N_PORT"
          value = tostring(var.frontend_container_port)
        },
        {
          name  = "N8N_PROTOCOL"
          value = "https"
        },
        {
          name  = "N8N_EDITOR_BASE_URL"
          value = "https://${var.frontend_domain_name}"
        },
        {
          name  = "WEBHOOK_URL"
          value = "https://${var.frontend_domain_name}/"
        },
        {
          name  = "GENERIC_TIMEZONE"
          value = "Europe/Warsaw"
        },
        {
          name  = "TZ"
          value = "Europe/Warsaw"
        },
        {
          name  = "N8N_ENCRYPTION_KEY"
          value = random_password.n8n_encryption_key.result
        },
        {
          name  = "N8N_RUNNERS_ENABLED"
          value = "true"
        },
        {
          name  = "N8N_SECURE_COOKIE"
          value = "true"
        },
        {
          name  = "N8N_DEFAULT_BINARY_DATA_MODE"
          value = "database"
        },
        {
          name  = "DB_TYPE"
          value = "postgresdb"
        },
        {
          name  = "DB_TABLE_PREFIX"
          value = "n8n_"
        },
        {
          name  = "DB_POSTGRESDB_HOST"
          value = aws_db_instance.fastApi_rds.address
        },
        {
          name  = "DB_POSTGRESDB_PORT"
          value = "5432"
        },
        {
          name  = "DB_POSTGRESDB_DATABASE"
          value = "fastApi_db"
        },
        {
          name  = "DB_POSTGRESDB_SCHEMA"
          value = "public"
        },
        {
          name  = "DB_POSTGRESDB_USER"
          value = "dbadmin"
        },
        {
          name  = "DB_POSTGRESDB_PASSWORD"
          value = "ChangeMe123"
        },
        {
          name  = "DB_POSTGRESDB_SSL_ENABLED"
          value = "false"
        },
        {
          name  = "DB_POSTGRESDB_SSL_REJECT_UNAUTHORIZED"
          value = "false"
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "n8n_ecs_service" {
  name                   = "${var.project_name}_frontend_service"
  cluster                = aws_ecs_cluster.fastApi_ecs_cluster.id
  task_definition        = aws_ecs_task_definition.n8n_ecs_task_definition.arn
  desired_count          = 1
  launch_type            = "FARGATE"
  enable_execute_command = true

  network_configuration {
    subnets = [
      aws_subnet.fastApi_sn_private_1.id,
      aws_subnet.fastApi_sn_private_2.id
    ]
    assign_public_ip = false
    security_groups  = [aws_security_group.n8n_ecs_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.n8n_alb_tg.arn
    container_name   = "n8n"
    container_port   = var.frontend_container_port
  }

  depends_on = [
    aws_lb_listener.fastApi_alb_https_listener,
    aws_lb_listener_rule.n8n_https_host
  ]
}
