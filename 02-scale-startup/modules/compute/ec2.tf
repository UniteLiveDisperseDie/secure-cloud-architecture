resource "aws_launch_template" "app_server" {
  name_prefix   = "${var.environment}-app-server-"
  instance_type = local.instance_type
  image_id      = data.aws_ami.amazon_linux.id

  vpc_security_group_ids = var.app_security_group_ids

  iam_instance_profile {
    name = var.iam_instance_profile_name
  }

  # EC2 메타데이터는 IMDSv2 토큰이 있을 때만 접근 가능하도록 강제한다.
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  user_data = filebase64("${path.module}/scripts/install_apache.sh")

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-app-server"
      Environment = var.environment
    }
  )
}

resource "aws_autoscaling_group" "app_server" {
  name                = "${var.environment}-app-server-asg"
  vpc_zone_identifier = var.public_subnet_ids
  min_size            = 1
  max_size            = 3
  desired_capacity    = 1

  target_group_arns = [var.alb_target_group_arn]

  launch_template {
    id      = aws_launch_template.app_server.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.environment}-app-server"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = var.tags["Project"]
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "ManagedBy"
    value               = "terraform"
    propagate_at_launch = true
  }
}
