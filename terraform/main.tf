resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-central-1a"

  tags = {
    Name = "private-subnet-1"
  }
}

resource "aws_subnet" "private2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "eu-central-1b"

  tags = {
    Name = "private-subnet-2"
  }
}

resource "aws_instance" "app" {
  ami = "ami-0c42fad2ea005202d"
  instance_type = "t3.micro"
  subnet_id = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  
  user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo install -y docker.io docker-compose
                sudo systemctl start docker
                EOF

  tags = {
    Name = "BooksAppInstance"
  }  
}

resource "aws_security_group" "ec2_sg" {
  vpc_id = aws_vpc.main.id

  ingress  {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }  
}

resource "aws_db_subnet_group" "default" {
  name       = "main-db-subnet-group"
  subnet_ids = [aws_subnet.private1.id, aws_subnet.private2.id]

  tags = {
    Name = "Main DB subnet group"
  }
}


resource "aws_db_instance" "db" {
  allocated_storage = 20
  engine = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"
  username = var.db_username
  password = var.db_password
  parameter_group_name = "default.mysql8.0"
  db_subnet_group_name = aws_db_subnet_group.default.name
  skip_final_snapshot = false
final_snapshot_identifier = "final-snapshot"
  publicly_accessible = false
}

resource "aws_ecr_repository" "frontend" {
  name = "frontend"  
}

resource "aws_ecr_repository" "backend" {
  name = "backend"  
}

# OIDC provider for GitHub Actions.  This enables the workflow to
# assume roles without AWS access keys.
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [
    # GitHub's OIDC provider certificate thumbprint (as of 2023).
    # Update if AWS reports a mismatch.
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]
}

# Role assumed by GitHub Actions when running terraform.
resource "aws_iam_role" "github_actions" {
  name = "github-actions-terraform"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:lkcodeacademy/books_app:ref:refs/heads/*"
          }
        }
      }
    ]
  })
}

# Attach a policy with permissions needed by Terraform
resource "aws_iam_role_policy" "github_actions_policy" {
  name = "github-actions-terraform-policy"
  role = aws_iam_role.github_actions.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:*",
          "rds:*",
          "ecr:*",
          "iam:PassRole"
        ],
        Resource = "*"
      }
    ]
  })
}


