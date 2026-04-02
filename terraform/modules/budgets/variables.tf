variable "project" {
  description = "Project name"
  type        = string
}

variable "budget_limit" {
  description = "Monthly budget limit in USD"
  type        = string
  default     = "350"
}

variable "alert_email" {
  description = "Email for budget alerts"
  type        = string
}
