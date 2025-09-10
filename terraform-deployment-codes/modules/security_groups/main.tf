resource "aws_security_group" "alb" {
  name   = var.alb_sg_name
  vpc_id = var.vpc_id
  description = "ALB security group allowing HTTP"
  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress { from_port=0; to_port=0; protocol="-1"; cidr_blocks=["0.0.0.0/0"] }
}

resource "aws_security_group" "app" {
  name   = var.app_sg_name
  vpc_id = var.vpc_id
  description = "App instances security group - allow from ALB and SSH"
  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    description = "Allow app traffic from ALB"
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_ssh_cidr]
    description = "SSH for admin"
  }
  egress { from_port=0; to_port=0; protocol="-1"; cidr_blocks=["0.0.0.0/0"] }
}

resource "aws_security_group" "rds" {
  name   = var.rds_sg_name
  vpc_id = var.vpc_id
  description = "RDS access - only from app SG"
  ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
    security_groups = [aws_security_group.app.id]
  }
  egress { from_port=0; to_port=0; protocol="-1"; cidr_blocks=["0.0.0.0/0"] }
}

output "alb_sg_id" { value = aws_security_group.alb.id }
output "app_sg_id" { value = aws_security_group.app.id }
output "rds_sg_id" { value = aws_security_group.rds.id }
