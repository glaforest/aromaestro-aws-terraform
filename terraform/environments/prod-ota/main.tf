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
# AWS Signer profile DiffuserOTACodeSign
# ============================================================
# Name is hardcoded in scripts/deploy-ota.sh in the firmware repo — do not rename.
resource "aws_signer_signing_profile" "ota" {
  name        = "DiffuserOTACodeSign"
  platform_id = "AmazonFreeRTOS-Default"

  # AmazonFreeRTOS-Default rejects custom signature_validity_period — the
  # signature lifetime is fixed by the platform. The brief's 135-month value is
  # unsupported at the API layer.

  signing_material {
    certificate_arn = aws_acm_certificate.ota_signing.arn
  }

  tags = {
    Name = "DiffuserOTACodeSign"
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
