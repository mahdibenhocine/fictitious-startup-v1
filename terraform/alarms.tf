locals {
  alarm_actions = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "ec2_cpu_high" {
  alarm_name          = "cloudtalents-ec2-cpu-high"
  alarm_description   = "Average EC2 CPU across the ASG exceeded 70%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 70
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }
  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "ec2_memory_high" {
  alarm_name          = "cloudtalents-ec2-memory-high"
  alarm_description   = "Average EC2 memory across the ASG exceeded 70%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = 60
  statistic           = "Average"
  threshold           = 70
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }
  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "cloudtalents-rds-cpu-high"
  alarm_description   = "Average RDS CPU exceeded 70%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 70
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.cloudtalents.identifier
  }
  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions
}