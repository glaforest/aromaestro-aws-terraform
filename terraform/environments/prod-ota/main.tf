# ============================================================
# AWS IoT OTA — firmware delivery to Diffusers thing group
# ============================================================
# Dedicated environment for the OTA pipeline. Isolated state from prod/ because
# prod/ is Phase 3 code not yet deployed — see CLAUDE.md.
#
# Supports scripts/deploy-ota.sh in the firmware repo.
# Target: Diffusers thing group (ESP32-C5 diffusers in prod).
# Signing cert: DiffuserOTACodeSign, serial 091AC033257B23E5BB494764E4CA5B9213F3E4C7.
#
# Never regenerate the signing cert — prod devices embed it and would reject
# updates signed by a different cert.

locals {
  # The old DiffuserOTACodeSign profile was canceled on 2026-04-10 because it
  # had been created without signingParameters.certname, which FreeRTOS OTA
  # requires. Canceled Signer profiles permanently reserve their name, so we
  # moved to a new profile name tied to the hardware platform.
  ota_signing_profile_name = "AromaestroESP32C5OTACodeSign"
  ota_signing_cert_path    = "/cert.pem" # placeholder — devices embed the cert at compile time and never read this path
}

# ============================================================
# S3 bucket for firmware artifacts
# ============================================================
# Bucket already exists in AWS (created outside Terraform); imported into state.
# Uses the shared s3 module with SSE-S3 (simpler than KMS for the IoT service role).
module "diffuser_ota_bucket" {
  source = "../../modules/s3"

  bucket_name       = "aromaestro-diffuser-ota"
  enable_versioning = true
  force_tls         = true
  sse_algorithm     = "AES256"
}

# 90-day expiration on the signed/ prefix (where AWS Signer writes signed blobs).
resource "aws_s3_bucket_lifecycle_configuration" "diffuser_ota_signed" {
  bucket = module.diffuser_ota_bucket.bucket_id

  rule {
    id     = "expire-signed-prefix"
    status = "Enabled"

    filter {
      prefix = "signed/"
    }

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# ============================================================
# ACM code signing certificate
# ============================================================
# NEVER regenerate — devices in prod embed this cert and would reject updates
# signed by any other. See variables.tf for ota_signing_cert_pem description.
resource "aws_acm_certificate" "ota_signing" {
  certificate_body = var.ota_signing_cert_pem
  private_key      = var.ota_signing_cert_key_pem

  tags = {
    Name    = "aromaestro-ota-code-signing"
    Purpose = "freertos-ota-code-signing"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# ============================================================
# AWS Signer profile AromaestroESP32C5OTACodeSign
# ============================================================
# Managed via terraform_data + local-exec because the hashicorp/aws provider's
# aws_signer_signing_profile resource does not expose signing_parameters, which
# FreeRTOS OTA requires (certname).
#
# AWS Signer profiles cannot be updated in place — put-signing-profile errors
# with "Profile already exists" on any existing name. The local-exec is
# therefore a create-only helper: it queries the profile first, and only calls
# put-signing-profile if no Active profile with that name exists.
#
# To change the cert ARN or certname: (1) cancel the current profile, (2) pick
# a new local.ota_signing_profile_name (canceled names are permanently reserved),
# (3) update the firmware repo's scripts/.env OTA_SIGNING_PROFILE. Do NOT attempt
# automated rotation here.
resource "terraform_data" "ota_signing_profile" {
  triggers_replace = {
    profile_name    = local.ota_signing_profile_name
    platform_id     = "AmazonFreeRTOS-Default"
    certificate_arn = aws_acm_certificate.ota_signing.arn
    certname        = local.ota_signing_cert_path
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      status=$(aws signer get-signing-profile \
        --profile-name ${self.triggers_replace.profile_name} \
        --region ca-central-1 \
        --query 'status' --output text 2>/dev/null || echo NOTFOUND)
      if [ "$status" = "Active" ]; then
        echo "Signer profile ${self.triggers_replace.profile_name} already Active — skipping put-signing-profile."
        exit 0
      fi
      aws signer put-signing-profile \
        --region ca-central-1 \
        --profile-name ${self.triggers_replace.profile_name} \
        --platform-id ${self.triggers_replace.platform_id} \
        --signing-material certificateArn=${self.triggers_replace.certificate_arn} \
        --signing-parameters certname=${self.triggers_replace.certname}
    EOT
  }
}

# ============================================================
# IoT OTA service role AWSIoTOTAUpdateRole
# ============================================================
# Assumed by iot.amazonaws.com while an OTA job executes.
# Reads firmware from the OTA bucket and starts signing jobs on its behalf.
data "aws_iam_policy_document" "iot_ota_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["iot.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "iot_ota_service" {
  name               = "AWSIoTOTAUpdateRole"
  assume_role_policy = data.aws_iam_policy_document.iot_ota_assume.json
  description        = "IoT OTA service role - reads firmware from aromaestro-diffuser-ota and drives Signer"
}

data "aws_iam_policy_document" "iot_ota_inline" {
  statement {
    sid    = "S3ObjectAccess"
    effect = "Allow"
    actions = [
      "s3:GetObjectVersion",
      "s3:GetObject",
      "s3:PutObject",
    ]
    resources = ["${module.diffuser_ota_bucket.bucket_arn}/*"]
  }

  statement {
    sid    = "S3BucketAccess"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:ListBucketVersions",
    ]
    resources = [module.diffuser_ota_bucket.bucket_arn]
  }

  statement {
    sid    = "SignerAccess"
    effect = "Allow"
    actions = [
      "signer:DescribeSigningJob",
      "signer:GetSigningProfile",
      "signer:StartSigningJob",
    ]
    resources = ["*"]
  }

  # The OTA service assumes this role during CreateOTAUpdate to provision the
  # underlying IoT Jobs and Streams on behalf of the caller. Without these,
  # CreateOTAUpdate returns CREATE_FAILED with iot:CreateJob AccessDenied.
  # See https://docs.aws.amazon.com/freertos/latest/userguide/create-service-role.html
  statement {
    sid    = "IoTJobAndStream"
    effect = "Allow"
    actions = [
      "iot:CreateJob",
      "iot:DescribeJob",
      "iot:UpdateJob",
      "iot:CancelJob",
      "iot:DeleteJob",
      "iot:DescribeJobExecution",
      "iot:CreateStream",
      "iot:DescribeStream",
      "iot:DeleteStream",
      "iot:GetOTAUpdate",
    ]
    resources = ["*"]
  }

  # IoT OTA passes this same role to the downstream IoT Stream service to read
  # the signed firmware from S3. Without this, CreateOTAUpdate returns
  # CREATE_FAILED with iam:PassRole AccessDenied.
  statement {
    sid       = "PassRoleToIoT"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.iot_ota_service.arn]
  }
}

resource "aws_iam_role_policy" "iot_ota_service" {
  name   = "OtaUpdatePolicy"
  role   = aws_iam_role.iot_ota_service.id
  policy = data.aws_iam_policy_document.iot_ota_inline.json
}

# ============================================================
# ota_user — service account for the local deploy script
# ============================================================
# No console, no MFA. The access key material is exposed via outputs (sensitive)
# and copied into the firmware repo's scripts/.env.
# Rotate manually: `terraform taint aws_iam_access_key.ota_user && terraform apply`.
resource "aws_iam_user" "ota_user" {
  name = "ota_user"
  path = "/service-accounts/"

  tags = {
    Purpose = "firmware-deploy-automation"
  }
}

resource "aws_iam_access_key" "ota_user" {
  user = aws_iam_user.ota_user.name
}

data "aws_iam_policy_document" "ota_deploy" {
  statement {
    sid    = "S3UploadFirmware"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion", # AWS Signer needs GetObjectVersion on versioned source buckets
      "s3:AbortMultipartUpload",
      "s3:ListBucket",
      "s3:ListBucketVersions",
      "s3:GetBucketLocation",
    ]
    resources = [
      module.diffuser_ota_bucket.bucket_arn,
      "${module.diffuser_ota_bucket.bucket_arn}/*",
    ]
  }

  statement {
    sid    = "IoTOtaManagement"
    effect = "Allow"
    actions = [
      "iot:CreateOTAUpdate",
      "iot:DescribeOTAUpdate",
      "iot:GetOTAUpdate",
      "iot:ListOTAUpdates",
      "iot:DeleteOTAUpdate",
      "iot:CreateJob",
      "iot:DescribeJob",
      "iot:DescribeJobExecution",
      "iot:CancelJob",
      "iot:DescribeThing",
      "iot:ListThings",
      "iot:ListThingGroups",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "CodeSigning"
    effect = "Allow"
    actions = [
      "signer:StartSigningJob",
      "signer:DescribeSigningJob",
      "signer:GetSigningProfile",
      "signer:ListSigningProfiles",
    ]
    resources = ["*"]
  }

  statement {
    sid       = "PassOtaRole"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.iot_ota_service.arn]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["iot.amazonaws.com"]
    }
  }
}

resource "aws_iam_user_policy" "ota_deploy" {
  name   = "OtaDeployPolicy"
  user   = aws_iam_user.ota_user.name
  policy = data.aws_iam_policy_document.ota_deploy.json
}
