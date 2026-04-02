variable "bucket_name" {
  description = "S3 bucket name"
  type        = string
}

variable "enable_versioning" {
  description = "Enable versioning"
  type        = bool
  default     = true
}

variable "lifecycle_expiration_days" {
  description = "Days before objects expire (0 = no expiration)"
  type        = number
  default     = 0
}

variable "lifecycle_glacier_days" {
  description = "Days before transition to Glacier (0 = no transition)"
  type        = number
  default     = 0
}

variable "force_tls" {
  description = "Deny non-TLS requests via bucket policy"
  type        = bool
  default     = true
}

variable "sse_algorithm" {
  description = "Server-side encryption algorithm (AES256 or aws:kms)"
  type        = string
  default     = "aws:kms"
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
