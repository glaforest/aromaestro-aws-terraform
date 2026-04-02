variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ca-central-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "management"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "aromaestro"
}

variable "alert_email" {
  description = "Email for budget alerts"
  type        = string
}
