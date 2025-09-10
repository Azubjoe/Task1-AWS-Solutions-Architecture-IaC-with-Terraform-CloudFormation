variable "vpc_cidr" { type = string }
variable "azs" { type = list(string) }            # e.g. ["us-east-1a","us-east-1b"]
variable "public_subnet_cidrs" { type = list(string) }
variable "private_app_subnet_cidrs" { type = list(string) }
variable "private_db_subnet_cidrs" { type = list(string) }
variable "project" { type = string }
variable "env" { type = string }
