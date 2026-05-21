# =========================
# EXECUTION ROLE
# Used by ECS/Fargate infrastructure itself
# (pull images, push logs, inject secrets...)
# =========================


# Identity-based Trust-Policy for ECS (WHO can use this role)
data "aws_iam_policy_document" "ecs_execution_trust_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ecs_execution_role" {
  name               = "ecs_execution_role"
  assume_role_policy = data.aws_iam_policy_document.ecs_execution_trust_policy.json
}


# Identity-based Permission-Policy for ECS (WHAT this role can do):
data "aws_iam_policy_document" "ecs_execution_permission_policy" {

  # CloudWatch Logs permissions:
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "ecs_execution_policy" {
  name   = "ecs_execution_policy"
  role   = aws_iam_role.ecs_execution_role.id
  policy = data.aws_iam_policy_document.ecs_execution_permission_policy.json
}



# =========================
# TASK ROLE
# Used by MY application/container itself
# (S3, DynamoDB, SNS...)
# =========================


# Identity-based Trust-Policy for ECS Tasks (WHO can use this role)
data "aws_iam_policy_document" "ecs_task_trust_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ecs_task_role" {
  name               = "ecs_task_role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_trust_policy.json
}


# Identity-based Permission-Policy for MY APP (WHAT this role can do):
# Enabling ECS EXEC:

data "aws_iam_policy_document" "ecs_task_permission_policy" {

  statement {
    effect = "Allow"

    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "ecs_task_policy" {
  name   = "ecs_task_policy"
  role   = aws_iam_role.ecs_task_role.id
  policy = data.aws_iam_policy_document.ecs_task_permission_policy.json
}
