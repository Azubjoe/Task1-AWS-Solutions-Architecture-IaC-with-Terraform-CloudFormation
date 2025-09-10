resource "aws_db_subnet_group" "rds_subnet" {
  name       = "${var.project}-${var.env}-db-subnet-group"
  subnet_ids = var.subnet_ids
  tags = { Name = "${var.project}-${var.env}-db-subnet-group" }
}

resource "aws_db_instance" "postgres" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "13.9"
  instance_class       = "db.t3.micro"
  name                 = var.db_name
  username             = var.db_username
  password             = var.db_password
  skip_final_snapshot  = true
  db_subnet_group_name = aws_db_subnet_group.rds_subnet.name
  vpc_security_group_ids = var.vpc_security_group_ids
  publicly_accessible  = false
  multi_az             = false
  backup_retention_period = 7
  tags = { Name = "${var.project}-${var.env}-postgres" }
}

output "rds_endpoint" { value = aws_db_instance.postgres.address }
output "rds_port" { value = aws_db_instance.postgres.port }
