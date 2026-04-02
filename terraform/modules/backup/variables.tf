variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "is_production" {
  description = "Whether this is production (enables weekly/monthly backups)"
  type        = bool
  default     = false
}
