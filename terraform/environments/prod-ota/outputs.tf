output "ota_user_access_key_id" {
  description = "Access key ID for ota_user service account"
  value       = aws_iam_access_key.ota_user.id
  sensitive   = true
}

output "ota_user_secret_access_key" {
  description = "Secret access key for ota_user service account"
  value       = aws_iam_access_key.ota_user.secret
  sensitive   = true
}

output "ota_s3_bucket" {
  description = "S3 bucket name for OTA firmware artifacts"
  value       = module.diffuser_ota_bucket.bucket_id
}

output "ota_signing_profile" {
  description = "AWS Signer profile name for FreeRTOS OTA"
  value       = local.ota_signing_profile_name
}

output "ota_iam_role_arn" {
  description = "IoT OTA service role ARN — passed via iot:CreateOTAUpdate"
  value       = aws_iam_role.iot_ota_service.arn
}

output "ota_acm_cert_arn" {
  description = "ACM ARN of the code signing certificate bound to the signer profile"
  value       = aws_acm_certificate.ota_signing.arn
}
