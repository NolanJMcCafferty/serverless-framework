provider "aws" {
  region = "{{ $sys.deploymentCell.region }}"
}

# Create a VPC for our resources
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = {
    Name = "example-vpc"
  }
}

# Create subnets across multiple availability zones for RDS
resource "aws_subnet" "database_subnet_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  
  tags = {
    Name = "example-db-subnet-1"
  }
}

resource "aws_subnet" "database_subnet_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  
  tags = {
    Name = "example-db-subnet-2"
  }
}

# Create a subnet group for RDS
resource "aws_db_subnet_group" "database" {
  name       = "example-db-subnet-group"
  subnet_ids = [aws_subnet.database_subnet_1.id, aws_subnet.database_subnet_2.id]
  
  tags = {
    Name = "example-db-subnet-group"
  }
}

# Create a security group for RDS
resource "aws_security_group" "database" {
  vpc_id      = aws_vpc.main.id
  name        = "example-db-sg"
  description = "Allow database traffic"
  
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "example-db-sg"
  }
}

# Generate a random password for the RDS instance
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Store DB credentials in SSM Parameter Store
resource "aws_ssm_parameter" "db_host" {
  name        = "/example/database/host"
  description = "Example RDS endpoint"
  type        = "String"
  value       = aws_db_instance.example.address
}

resource "aws_ssm_parameter" "db_port" {
  name        = "/example/database/port"
  description = "Example RDS port"
  type        = "String"
  value       = aws_db_instance.example.port
}

resource "aws_ssm_parameter" "db_name" {
  name        = "/example/database/name"
  description = "Example RDS database name"
  type        = "String"
  value       = aws_db_instance.example.name
}

resource "aws_ssm_parameter" "db_username" {
  name        = "/example/database/username"
  description = "Example RDS admin username"
  type        = "String"
  value       = aws_db_instance.example.username
}

resource "aws_ssm_parameter" "db_password" {
  name        = "/example/database/password"
  description = "Example RDS admin password"
  type        = "SecureString"
  value       = random_password.db_password.result
}

# Create RDS instance
resource "aws_db_instance" "example" {
  identifier             = "example-rds"
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  db_name                = "exampledb"
  username               = "admin"
  password               = random_password.db_password.result
  parameter_group_name   = "default.mysql8.0"
  db_subnet_group_name   = aws_db_subnet_group.database.name
  vpc_security_group_ids = [aws_security_group.database.id]
  skip_final_snapshot    = true
  publicly_accessible    = false
  
  tags = {
    Name = "example-rds"
  }
}

# Create an IAM role for EC2 instances to access SSM parameters
resource "aws_iam_role" "ssm_access" {
  name = "example-ssm-access-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Create an IAM policy for SSM parameter access
resource "aws_iam_policy" "ssm_parameter_access" {
  name        = "example-ssm-parameter-access"
  description = "Policy to allow access to specific SSM parameters"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/example/*"
      }
    ]
  })
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "ssm_access" {
  role       = aws_iam_role.ssm_access.name
  policy_arn = aws_iam_policy.ssm_parameter_access.arn
}

# Get current AWS region and account ID
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# Outputs
output "rds_endpoint" {
  value = aws_db_instance.example.address
}

output "rds_port" {
  value = aws_db_instance.example.port
}

output "ssm_parameter_prefix" {
  value = "/example/database/"
}

output "ssm_parameter_access_role" {
  value = aws_iam_role.ssm_access.name
}
