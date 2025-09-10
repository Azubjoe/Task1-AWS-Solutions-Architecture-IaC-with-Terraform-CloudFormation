variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "project_name" {
  type    = string
  default = "django-app"
}

variable "public_key_path" {
  type    = string
  default = ""
  description = "Path to local public key file (optional). If provided, Terraform will create an aws_key_pair named by var.key_name."
}

variable "key_name" {
  type    = string
  default = "DjangoKey"
  description = "Key pair name to use for EC2 instances (will be created if public_key_path provided)."
}

variable "admin_ssh_cidr" {
  type    = string
  default = "0.0.0.0/0"
  description = "CIDR allowed for SSH to app instances. Please restrict to your admin IP in production."
}

variable "db_username" { type = string; default = "django_user" }
variable "db_password" { type = string; default = "ChangeMe123!" } # use terraform.tfvars or secrets manager in prod
variable "db_name"     { type = string; default = "django_db" }

variable "app_instance_type" { type = string; default = "t2.micro" }
variable "asg_min_size"      { type = number; default = 1 }
variable "asg_max_size"      { type = number; default = 3 }
variable "app_repo_url"      { type = string; default = "https://github.com/your-org/your-django-repo.git" }
variable "app_repo_branch"   { type = string; default = "main" }

variable "s3_bucket_name" {
  type    = string
  default = ""
  description = "If empty a bucket with a generated name will be created."
}

variable "ami_name_filter" {
  type = string
  default = "amzn2-ami-hvm-*-x86_64-gp2"
}
