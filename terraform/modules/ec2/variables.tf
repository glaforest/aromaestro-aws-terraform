variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR for DNS security group rule"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for instances"
  type        = string
}

variable "rds_security_group_id" {
  description = "RDS security group ID for outbound MySQL rule"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t4g.small"
}

variable "instances" {
  description = "Map of instance names to their application tag"
  type        = map(string)
}

variable "tailscale_auth_key_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the Tailscale auth key"
  type        = string
}

variable "cloudwatch_agent_config_ssm_param" {
  description = "SSM Parameter name for CloudWatch Agent config"
  type        = string
}
