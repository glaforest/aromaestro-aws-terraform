variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name (development, production)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_nat_cidr" {
  description = "CIDR block for the public NAT subnet"
  type        = string
}

variable "private_app_cidrs" {
  description = "CIDR blocks for private app subnets (one per AZ)"
  type        = list(string)
}

variable "private_data_cidrs" {
  description = "CIDR blocks for private data subnets (one per AZ)"
  type        = list(string)
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "use_nat_gateway" {
  description = "Use NAT Gateway (true) or NAT instance (false)"
  type        = bool
  default     = true
}

variable "nat_instance_type" {
  description = "Instance type for NAT instance (when use_nat_gateway = false)"
  type        = string
  default     = "t4g.nano"
}

variable "logs_bucket_arn" {
  description = "S3 bucket ARN for VPC Flow Logs"
  type        = string
}
