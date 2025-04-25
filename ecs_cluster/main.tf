provider "aws" {
  region = "{{ $sys.deploymentCell.region }}"
}

# ---------------------------------------------------------------------------------------------------------------------
# VPC AND NETWORKING RESOURCES
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_vpc" "serverless_deployer_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  
  tags = {
    Name = "serverless-deployer-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.serverless_deployer_vpc.id
  
  tags = {
    Name = "serverless-deployer-igw"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.serverless_deployer_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "{{ $sys.deploymentCell.region }}a"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "serverless-deployer-subnet"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.serverless_deployer_vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  
  tags = {
    Name = "serverless-deployer-rtb"
  }
}

resource "aws_route_table_association" "public_route_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_security_group" "ecs_sg" {
  name        = "serverless-deployer-sg"
  description = "Security group for Serverless deployer ECS tasks"
  vpc_id      = aws_vpc.serverless_deployer_vpc.id
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "serverless-deployer-sg"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# S3 BUCKET FOR SERVERLESS.YML
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_s3_bucket" "serverless_config" {
  bucket = "serverless-deployer-configs-${random_string.bucket_suffix.result}"
  
  tags = {
    Name = "Serverless Deployer Configs"
  }
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  lower   = true
  upper   = false
}

resource "aws_s3_bucket_ownership_controls" "serverless_config_ownership" {
  bucket = aws_s3_bucket.serverless_config.id
  
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "serverless_config_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.serverless_config_ownership]
  
  bucket = aws_s3_bucket.serverless_config.id
  acl    = "private"
}

resource "aws_s3_object" "serverless_yaml" {
  bucket = aws_s3_bucket.serverless_config.id
  key    = "example.yaml"
  source = "${path.module}/example.yaml"
  etag   = filemd5("${path.module}/example.yaml")
}

# ---------------------------------------------------------------------------------------------------------------------
# ECR REPOSITORY
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_ecr_repository" "serverless_deployer" {
  name                 = "serverless-deployer"
  image_tag_mutability = "MUTABLE"
  
  image_scanning_configuration {
    scan_on_push = true
  }
  
  tags = {
    Name = "serverless-deployer"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# IAM ROLES AND POLICIES
# ---------------------------------------------------------------------------------------------------------------------

# ECS Task Execution Role
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "serverless-deployer-execution-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
  
  tags = {
    Name = "serverless-deployer-execution-role"
  }
}

# Attach the AWS managed policy for ECS task execution
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Role (with permissions to deploy serverless stack)
resource "aws_iam_role" "serverless_deployer_role" {
  name = "serverless-deployer-task-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
  
  tags = {
    Name = "serverless-deployer-task-role"
  }
}

resource "aws_iam_policy" "serverless_deployer_policy" {
  name        = "serverless-deployer-policy"
  description = "Policy for Serverless Framework deployments"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudformation:*",
          "s3:*",
          "logs:*",
          "iam:*",
          "lambda:*",
          "apigateway:*",
          "cloudwatch:*",
          "events:*",
          "ssm:*"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy" "s3_access_policy" {
  name        = "serverless-config-s3-access"
  description = "Allow access to S3 bucket containing serverless.yml"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.serverless_config.arn,
          "${aws_s3_bucket.serverless_config.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "serverless_deployer_policy_attachment" {
  role       = aws_iam_role.serverless_deployer_role.name
  policy_arn = aws_iam_policy.serverless_deployer_policy.arn
}

resource "aws_iam_role_policy_attachment" "s3_access_policy_attachment" {
  role       = aws_iam_role.serverless_deployer_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

# ---------------------------------------------------------------------------------------------------------------------
# ECS CLUSTER
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_ecs_cluster" "serverless_deployment_cluster" {
  name = "serverless-deployment-cluster"
  
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  
  tags = {
    Name    = "serverless-deployment-cluster"
    Purpose = "ServerlessDeployments"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ECS TASK DEFINITION
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_ecs_task_definition" "serverless_deployer" {
  family                   = "serverless-deployer"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.serverless_deployer_role.arn
  
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }
  
  container_definitions = jsonencode([
    {
      name      = "serverless-deployer"
      image     = "${aws_ecr_repository.serverless_deployer.repository_url}:latest"
      essential = true
      
      environment = [
        {
          name  = "AWS_REGION"
          value = "{{ $sys.deploymentCell.region }}"
        },
        {
          name  = "AWS_ACCESS_KEY_ID"
          value = "{{ $var.aws_access_key_id }}",
        },
        {
          name  = "AWS_SECRET_ACCESS_KEY"
          value = "{{ $var.aws_secret_access_key }}",
        },
        {
          name  = "SERVERLESS_ACCESS_KEY"
          value = "{{ $var.serverless_access_key }}",
        },
        {
          name  = "S3_SERVERLESS_CONFIG"
          value = "s3://${aws_s3_bucket.serverless_config.id}/serverless.yml"
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.serverless_deployer_logs.name
          "awslogs-region"        = "{{ $sys.deploymentCell.region }}"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
  
  tags = {
    Name = "serverless-deployer"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CLOUDWATCH LOG GROUP
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "serverless_deployer_logs" {
  name              = "/ecs/serverless-deployer"
  retention_in_days = 14
  
  tags = {
    Name = "serverless-deployer-logs"
  }
}
