variable "custom_ami_version" {
  description = "Version of the custom AMI to use"
  type        = string
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "CloudWithBen"
}