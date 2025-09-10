provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source                  = "./modules/vpc"
  vpc_cidr                = "10.0.0.0/16"
  azs                     = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs     = ["10.0.1.0/24","10.0.2.0/24"]
  private_app_subnet_cidrs = ["10.0.3.0/24","10.0.4.0/24"]
  private_db_subnet_cidrs  = ["10.0.5.0/24","10.0.6.0/24"]
  project                 = var.project_name
  env                     = var.environment
}

module "iam" {
  source = "./modules/iam"
  project = var.project_name
  env = var.environment
  s3_bucket_name = var.s3_bucket_name
}

module "security_groups" {
  source = "./modules/security_groups"
  vpc_id = module.vpc.vpc_id
  admin_ssh_cidr = var.admin_ssh_cidr
  alb_sg_name = "${var.project_name}-${var.environment}-alb-sg"
  app_sg_name = "${var.project_name}-${var.environment}-app-sg"
  rds_sg_name = "${var.project_name}-${var.environment}-rds-sg"
}

module "alb" {
  source = "./modules/alb"
  vpc_id = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  alb_security_group_id = module.security_groups.alb_sg_id
}

module "asg" {
  source = "./modules/asg"
  vpc_id = module.vpc.vpc_id
  app_subnet_ids = module.vpc.private_app_subnet_ids
  key_name = var.key_name
  public_key_path = var.public_key_path
  ami_name_filter = var.ami_name_filter
  instance_type = var.app_instance_type
  asg_min_size = var.asg_min_size
  asg_max_size = var.asg_max_size
  alb_target_group_arn = module.alb.alb_tg_arn
  iam_instance_profile = module.iam.instance_profile_name
  security_group_ids = [module.security_groups.app_sg_id]
  app_repo = var.app_repo_url
  app_branch = var.app_repo_branch
}

module "rds" {
  source = "./modules/rds"
  db_username = var.db_username
  db_password = var.db_password
  db_name     = var.db_name
  subnet_ids  = module.vpc.private_db_subnet_ids
  vpc_security_group_ids = [module.security_groups.rds_sg_id]
  project = var.project_name
  env     = var.environment
}

module "s3_cloudwatch" {
  source = "./modules/s3_cloudwatch"
  project = var.project_name
  env     = var.environment
  bucket_name = var.s3_bucket_name
}
