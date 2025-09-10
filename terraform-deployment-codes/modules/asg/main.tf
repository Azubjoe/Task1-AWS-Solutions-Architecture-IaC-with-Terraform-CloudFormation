locals { create_key = length(trim(var.public_key_path)) > 0 }

data "local_file" "public_key" {
  count = local.create_key ? 1 : 0
  filename = var.public_key_path
}

resource "aws_key_pair" "this" {
  count = local.create_key ? 1 : 0
  key_name = var.key_name
  public_key = data.local_file.public_key[0].content
}

data "aws_ami" "al2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = [var.ami_name_filter]
  }
}

resource "aws_launch_template" "lt" {
  name_prefix   = "lt-${var.instance_type}-"
  image_id      = data.aws_ami.al2.id
  instance_type = var.instance_type
  key_name      = var.key_name
  iam_instance_profile {
    name = var.iam_instance_profile
  }
  network_interfaces {
    associate_public_ip_address = false
    security_groups = var.security_group_ids
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              # install packages and run Django app; adapt to your deployment mechanism
              yum update -y
              amazon-linux-extras enable python3.8
              yum install -y python3 git gcc postgresql-devel
              python3 -m pip install --upgrade pip
              cd /home/ec2-user || exit 0
              if [ ! -d "app" ]; then
                git clone --depth 1 -b ${var.app_branch} ${var.app_repo} app || true
              else
                cd app && git pull || true
              fi
              cd app || exit 0
              pip3 install -r requirements.txt || true
              # start with gunicorn (example). Replace/manage with systemd or supervisor in prod
              nohup python3 manage.py migrate --noinput || true
              nohup python3 manage.py collectstatic --noinput || true
              nohup gunicorn --bind 0.0.0.0:8000 your_project.wsgi:application &
              EOF
  )
}

resource "aws_autoscaling_group" "asg" {
  name                      = "asg-${substr(var.vpc_id,0,8)}"
  desired_capacity          = var.asg_min_size
  min_size                  = var.asg_min_size
  max_size                  = var.asg_max_size
  vpc_zone_identifier       = var.app_subnet_ids
  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }
  target_group_arns = [var.alb_target_group_arn]

  tag {
    key                 = "Name"
    value               = "asg-${substr(var.vpc_id,0,8)}"
    propagate_at_launch = true
  }
}

