packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }

  required_plugins {
    amazon-ami-management = {
        version = ">= 1.0.0"
        source = "github.com/wata727/amazon-ami-management"
    }
  }

}

variable "version" {
  type        = string
  description = "Version of the AMI to build"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where Packer will build the AMI"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID where Packer will launch the instance"
}

variable "region" {
  type        = string
  default     = "eu-west-1"
  description = "AWS region"
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "cloudtalents-startup-${var.version}"
  instance_type = "t2.micro"
  region        = var.region
  
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-jammy-22.04-amd64-server*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }

  metadata_options {
    http_tokens = "required"
  }
  
  # Required for accounts without default VPC
  vpc_id                      = var.vpc_id
  subnet_id                   = var.subnet_id
  associate_public_ip_address = true
  
  ssh_username = "ubuntu"
  
  tags = {
    Name    = "cloudtalents-startup-${var.version}"
    Version = var.version
    Builder = "Packer"
  }
}

build {
  sources = ["source.amazon-ebs.ubuntu"]
  
  # Upload application code to /tmp
  provisioner "file" {
    source      = "./"
    destination = "/tmp"
  }
  
  # Move files from /tmp to /opt/app
  provisioner "shell" {
    inline = [
      "sudo mkdir -p /opt/app",
      "sudo mv /tmp/* /opt/app/",
      "sudo chown -R ubuntu:ubuntu /opt/app"
    ]
  }
  
  # Keep only the last 2 AMI releases
  post-processor "amazon-ami-management" {
    regions       = [var.region]
    identifier    = "cloudtalents-startup-*"
    keep_releases = 2
  }
}