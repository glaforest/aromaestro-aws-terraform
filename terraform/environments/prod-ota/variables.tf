variable "ota_signing_cert_pem" {
  description = "PEM-encoded ECDSA code signing certificate used by AWS Signer for FreeRTOS OTA. MUST match the cert already embedded in prod firmware (serial 091AC033257B23E5BB494764E4CA5B9213F3E4C7). NEVER regenerate."
  type        = string
  sensitive   = true
}

variable "ota_signing_cert_key_pem" {
  description = "PEM-encoded private key matching ota_signing_cert_pem. Stored only in gitignored prod-ota/ota.auto.tfvars."
  type        = string
  sensitive   = true
}
