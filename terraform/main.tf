resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
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
  key_name = aws_key_pair.deployer.key_name
  user_data_replace_on_change = true
  
  user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install -y docker.io docker-compose
                sudo systemctl start docker
                
                # Fallback for SSH key injection
                mkdir -p /home/ubuntu/.ssh
                echo "${trimspace(var.public_key)}" >> /home/ubuntu/.ssh/authorized_keys
                chown ubuntu:ubuntu /home/ubuntu/.ssh/authorized_keys
                chmod 600 /home/ubuntu/.ssh/authorized_keys
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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
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
  skip_final_snapshot = true
  publicly_accessible = false
}

resource "aws_ecr_repository" "frontend" {
  name = "frontend"  
}

resource "aws_ecr_repository" "backend" {
  name = "backend"  
}

# Look up the existing OIDC provider for GitHub Actions.
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# Role assumed by GitHub Actions when running terraform.
data "aws_iam_role" "github_actions" {
  name = "github-actions-terraform"
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = trimspace(var.public_key)
}


