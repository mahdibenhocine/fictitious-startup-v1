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

resource "aws_instance" "app" {
  ami                         = data.aws_ami.custom_ami.id
  instance_type              = "t2.micro"
  subnet_id                  = data.terraform_remote_state.vpc.outputs.public_subnets[0]
  vpc_security_group_ids     = [aws_security_group.app.id]
  associate_public_ip_address = true
  
  tags = {
    Name        = "app-instance"
    Environment = "development"
    ManagedBy   = "terraform"
  }
}

resource "aws_instance" "app_server" {
  ami                    = var.ami_id
  instance_type         = var.instance_type
  subnet_id             = var.subnet_id
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name  # Add this line

  tags = {
    Name    = "${var.project_name}-app-server"
    Project = var.project_name
  }
}