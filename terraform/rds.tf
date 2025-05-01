# Create a subnet group for RDS
resource "aws_db_subnet_group" "database" {
  name       = "example-db-subnet-group-{{ $sys.id }}"
  subnet_ids = [
    "{{ $sys.deploymentCell.publicSubnetIDs[0].id }}",
    "{{ $sys.deploymentCell.publicSubnetIDs[1].id }}",
  ]
  
  tags = {
    Name = "example-db-subnet-group"
  }
}

# Create a security group for RDS
resource "aws_security_group" "database" {
  vpc_id      = "{{ $sys.deploymentCell.cloudProviderNetworkID }}"
  name        = "example-db-sg-{{ $sys.id }}"
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
    Name = "example-db-sg-{{ $sys.id }}"
  }
}

# Store DB credentials in SSM Parameter Store
resource "aws_ssm_parameter" "db_host" {
  name        = "/example/database/host/{{ $sys.id }}"
  description = "Example RDS endpoint"
  type        = "String"
  value       = aws_db_instance.example.address
}

resource "aws_ssm_parameter" "db_port" {
  name        = "/example/database/port/{{ $sys.id }}"
  description = "Example RDS port"
  type        = "String"
  value       = aws_db_instance.example.port
}

resource "aws_ssm_parameter" "db_name" {
  name        = "/example/database/name/{{ $sys.id }}"
  description = "Example RDS database name"
  type        = "String"
  value       = aws_db_instance.example.db_name
}

resource "aws_ssm_parameter" "db_username" {
  name        = "/example/database/username/{{ $sys.id }}"
  description = "Example RDS admin username"
  type        = "String"
  value       = aws_db_instance.example.username
}

resource "aws_ssm_parameter" "db_password" {
  name        = "/example/database/password/{{ $sys.id }}"
  description = "Example RDS admin password"
  type        = "SecureString"
  value       = "example-password"
}

# Create RDS instance
resource "aws_db_instance" "example" {
  identifier             = "example-rds-{{ $sys.id }}"
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  db_name                = "exampledb"
  username               = "admin"
  password               = "example-password"
  parameter_group_name   = "default.mysql8.0"
  db_subnet_group_name   = aws_db_subnet_group.database.name
  vpc_security_group_ids = [aws_security_group.database.id]
  skip_final_snapshot    = true
  publicly_accessible    = false
  
  tags = {
    Name = "example-rds-{{ $sys.id }}"
  }
}

# Create an IAM role for EC2 instances to access SSM parameters
resource "aws_iam_role" "ssm_access" {
  name = "example-ssm-access-role-{{ $sys.id }}"
  
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
  name        = "example-ssm-parameter-access-{{ $sys.id }}"
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
