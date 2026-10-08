# ============================================================
# IoT fleet security, logging, indexing and custom domain
# ============================================================
# Created or changed by hand during the 2026-10-07/08 fleet audit, imported
# here on 2026-10-08 so the whole IoT setup lives in one state. Device
# certificates (made by fleet provisioning) and the Cloudflare DNS records
# stay outside Terraform.

# ------------------------------------------------------------
# Device policy
# ------------------------------------------------------------
# A content change creates a new policy version; IoT keeps at most 5 and the
# provider deletes the oldest non-default one to make room.
resource "aws_iot_policy" "diffuser" {
  name   = "Diffuser_Policy"
  policy = file("${path.module}/policies/diffuser-policy.json")
}

# ------------------------------------------------------------
# Logging (IoT v2, log group AWSIotLogsV2)
# ------------------------------------------------------------
resource "aws_iam_role" "iot_logging" {
  name = "IoTLoggingRole"
  path = "/service-role/"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "iot.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Console-generated, kept as found.
resource "aws_iam_policy" "iot_logging" {
  name = "aws-iot-role-logging_1791468602201"
  path = "/service-role/"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:PutMetricFilter",
        "logs:PutRetentionPolicy",
      ]
      Resource = ["arn:aws:logs:*:${local.account_id}:log-group:*:log-stream:*"]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "iot_logging" {
  role       = aws_iam_role.iot_logging.name
  policy_arn = aws_iam_policy.iot_logging.arn
}

# Account-level setting with no import: creating it re-sends the same values
# (SetV2LoggingOptions), which is a no-op when they match.
resource "aws_iot_logging_options" "this" {
  default_log_level = "ERROR"
  role_arn          = aws_iam_role.iot_logging.arn
  disable_all_logs  = false
}

# ------------------------------------------------------------
# Custom domain iot.aromaestro.com (firmware >= 1.1.2 connects here first)
# ------------------------------------------------------------
# NEVER let Terraform replace either resource: the whole 1.1.2 fleet would lose
# its endpoint. The DNS validation CNAME _b37adb6e1c3e1a423e51df2c9bc7eb85.iot
# in Cloudflare must stay, or ACM cannot renew.
resource "aws_acm_certificate" "iot_domain" {
  domain_name       = "iot.aromaestro.com"
  validation_method = "DNS"
  key_algorithm     = "RSA_2048"

  options {
    certificate_transparency_logging_preference = "ENABLED"
  }

  tags = {
    Purpose = "iot-custom-domain"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iot_domain_configuration" "aromaestro" {
  name                    = "aromaestro-iot"
  domain_name             = "iot.aromaestro.com"
  service_type            = "DATA"
  server_certificate_arns = [aws_acm_certificate.iot_domain.arn]

  tls_config {
    security_policy = "IoTSecurityPolicy_TLS13_1_2_2022_10"
  }

  tags = {
    Purpose = "iot-custom-domain"
  }

  lifecycle {
    prevent_destroy = true
  }
}
