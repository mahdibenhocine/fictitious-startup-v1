resource "aws_cloudwatch_log_metric_filter" "upload_count" {
  name           = "UploadCount"
  log_group_name = "/startup/app"
  pattern        = "\"PUT /media/user_images/\""

  metric_transformation {
    name      = "UploadCount"
    namespace = "StartupApp"
    value     = "1"
    unit      = "Count"
  }
}