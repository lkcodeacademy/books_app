
output "ec2_public_ip" {
  value = aws_instance.app.public_ip  
}

output "db_endpoint" {
  value = aws_db_instance.db.endpoint
}

