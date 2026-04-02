variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "alert_email" {
  description = "Email address for alerts"
  type        = string
}

variable "ec2_instance_ids" {
  description = "Map of instance name to instance ID"
  type        = map(string)
}

variable "rds_instance_id" {
  description = "RDS instance identifier"
  type        = string
}

variable "has_nat_instance" {
  description = "Whether a NAT instance exists (for monitoring alarm)"
  type        = bool
  default     = false
}

variable "nat_instance_id" {
  description = "NAT instance ID (empty string if using NAT Gateway)"
  type        = string
  default     = ""
}
