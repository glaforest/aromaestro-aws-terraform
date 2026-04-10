variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ca-central-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "aromaestro"
}

variable "alert_email" {
  description = "Email for CloudWatch and budget alerts"
  type        = string
}

variable "ota_signing_cert_pem" {
  description = "PEM-encoded ECDSA code signing certificate used by AWS Signer for FreeRTOS OTA. MUST match the cert already embedded in prod firmware (serial 091AC033257B23E5BB494764E4CA5B9213F3E4C7). NEVER regenerate."
  type        = string
  sensitive   = true
}

variable "ota_signing_cert_key_pem" {
  description = "PEM-encoded private key matching ota_signing_cert_pem. Stored only in gitignored prod/ota.auto.tfvars."
  type        = string
  sensitive   = true
}
