resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
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

resource "aws_db_instance" "db" {
  allocated_storage = 20
  engine = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"
  username = var.db_username
  password = var.db_password
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot = false
  publicly_accessible = false
}

resource "aws_ecr_repository" "frontend" {
  name = "frontend"  
}

resource "aws_ecr_repository" "backend" {
  name = "backend"  
}


