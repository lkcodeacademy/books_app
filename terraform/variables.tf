variable "db_username" {
  description = "The username for the RDS database"
  type        = string
  sensitive = true 
}

variable "db_password" {
  description = "The password for the RDS database"
  type        = string
  sensitive = true 
}

variable "github_repo" {
  description = "GitHub repository identifier (owner/repo) for OIDC trust policy"
  type        = string
}

variable "public_key" {
  description = "The public key for SSH access to the EC2 instance"
  type        = string
}