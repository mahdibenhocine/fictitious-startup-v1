terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  cloud {
    organization = "cloudwithben-org"  # Replace with your actual org name ---
    
    workspaces {
      name = "app-dev-ec2" 
    }
  }
}

provider "aws" {
  region = "eu-west-1"
}

# Data source to read VPC outputs from remote state of
data "terraform_remote_state" "vpc" {
  backend = "remote"
  
  config = {
    organization = "cloudwithben-org"  # Replace with your actual org name
    workspaces = {
      name = "network-vpc-prod"  # Replace with your VPC workspace name
    }
  }
}

# Data source to find the custom AMI
data "aws_ami" "custom_ami" {
  most_recent = true
  owners      = ["self"]
  
  filter {
    name   = "name"
    values = ["cloudtalents-startup-${var.custom_ami_version}"]
  }
  
  filter {
    name   = "state"
    values = ["available"]
  }
}

resource "aws_launch_template" "app" {
  name_prefix   = "app-"
  image_id      = data.aws_ami.custom_ami.id
  instance_type = "t2.micro"

  # associate_public_ip_address must live inside network_interfaces
  # and the security group moves here too as a result
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.app.id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  # Drops CloudWatch metrics from 5-minute to 1-minute intervals
  # Required for the ASG to react fast enough to CPU spikes
  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "app-asg-instance"
      Environment = "development"
      ManagedBy   = "terraform"
    }
  }
}

resource "aws_autoscaling_group" "app" {
  name                = "app-asg"
  min_size            = 1
  max_size            = 5
  desired_capacity    = 1

  # Spread instances across your private/public subnets
  # These should already be available via your remote state data source
  vpc_zone_identifier = data.terraform_remote_state.vpc.outputs.public_subnets

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  # How long to wait for an instance to pass health checks before
  # marking it as unhealthy and replacing it
  health_check_grace_period = 300
  health_check_type         = "ELB"

  tag {
    key                 = "Name"
    value               = "app-asg-instance"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "app_cpu_target_tracking" {
  name                      = "app-cpu-target-tracking"
  autoscaling_group_name    = aws_autoscaling_group.app.name
  policy_type               = "TargetTrackingScaling"
  estimated_instance_warmup = 60

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 60.0
  }
}

resource "aws_lb" "app" {
  name               = "cloudtalents-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.app.id]
  subnets            = data.terraform_remote_state.vpc.outputs.public_subnets
}

resource "aws_lb_target_group" "app" {
  name                          = "cloudtalents-tg"
  port                          = 80
  protocol                      = "HTTP"
  vpc_id                        = data.terraform_remote_state.vpc.outputs.vpc_id
  load_balancing_algorithm_type = "least_outstanding_requests"

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 4
    timeout             = 15
    interval            = 30
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_autoscaling_attachment" "app" {
  autoscaling_group_name = aws_autoscaling_group.app.name
  lb_target_group_arn    = aws_lb_target_group.app.arn
}
