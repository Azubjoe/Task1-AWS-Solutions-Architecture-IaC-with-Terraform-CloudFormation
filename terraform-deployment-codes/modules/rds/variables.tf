variable "db_username" { type = string }
variable "db_password" { type = string }
variable "db_name" { type = string }
variable "subnet_ids" { type = list(string) }
variable "vpc_security_group_ids" { type = list(string) }
variable "project" { type = string }
variable "env" { type = string }
