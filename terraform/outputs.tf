output "ami_id" {
  description = "AMI ID used for the instance"
  value       = data.aws_ami.custom_ami.id
}

output "instance_profile_name" {
  description = "Name of the IAM instance profile"
  value       = aws_iam_instance_profile.ec2_profile.name
}

output "iam_role_arn" {
  description = "ARN of the IAM role"
  value       = aws_iam_role.ec2_ssm_role.arn
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.postgres.endpoint
}

output "rds_address" {
  description = "RDS instance address (hostname only)"
  value       = aws_db_instance.postgres.address
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.postgres.port
}

output "dms_replication_instance_private_ip" {
  description = "Private IP of the DMS replication instance"
  value = length(aws_dms_replication_instance.main) > 0 ? aws_dms_replication_instance.main[0].replication_instance_private_ips : null
}

output "alb_dns_name" {
  value       = aws_lb.app.dns_name
  description = "The DNS name of the Application Load Balancer"
}