resource "aws_iam_role" "ecs_task_role" {
  name = "${var.prefix}-ecs-task-role"

  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json

  tags = var.tags
}

resource "aws_iam_role" "ecs_execution_role" {
  name               = "${var.prefix}-ecs-execution-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json

  tags = var.tags
}

resource "aws_iam_role_policy" "ecs_task_execution_policy" {
  name = "${var.prefix}-ecs-task-execution-policy"
  role = aws_iam_role.ecs_execution_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sns:Publish"
      ],
      "Resource": ["*"]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "ecs_task_policy" {
  name = "${var.prefix}-ecs-task-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
        "logs:PutLogEvents",
        "logs:CreateLogGroup",
        "logs:CreateLogStream"
      ],
      "Resource": ["*"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "sns:Publish"
      ],
      "Resource": ["*"]
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy_attachment" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
