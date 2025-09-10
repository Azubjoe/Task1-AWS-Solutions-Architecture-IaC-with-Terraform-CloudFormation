resource "aws_lb" "this" {
  name               = replace("alb-${var.vpc_id}", "/", "-")
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids
  tags = { Name = "alb-${var.vpc_id}" }
}

resource "aws_lb_target_group" "tg" {
  name     = "tg-${substr(var.vpc_id,0,8)}"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

output "alb_tg_arn" { value = aws_lb_target_group.tg.arn }
output "alb_dns" { value = aws_lb.this.dns_name }
