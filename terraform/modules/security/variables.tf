variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "logs_bucket_name" {
  description = "S3 bucket name for CloudTrail logs"
  type        = string
}

variable "logs_bucket_arn" {
  description = "S3 bucket ARN for CloudTrail logs"
  type        = string
}
