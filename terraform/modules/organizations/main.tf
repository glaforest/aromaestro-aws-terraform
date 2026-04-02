data "aws_organizations_organization" "current" {}

# ============================================================
# Combined SCP - All guardrails in one policy
# ============================================================

data "aws_iam_policy_document" "guardrails" {
  # Region Deny
  statement {
    sid    = "RegionDeny"
    effect = "Deny"
    not_actions = [
      "a4b:*",
      "acm:*",
      "aws-marketplace-management:*",
      "aws-marketplace:*",
      "aws-portal:*",
      "budgets:*",
      "ce:*",
      "chime:*",
      "cloudfront:*",
      "config:*",
      "cur:*",
      "directconnect:*",
      "ec2:DescribeRegions",
      "ec2:DescribeTransitGateways",
      "ec2:DescribeVpnGateways",
      "fms:*",
      "globalaccelerator:*",
      "health:*",
      "iam:*",
      "importexport:*",
      "kms:*",
      "mobileanalytics:*",
      "networkmanager:*",
      "organizations:*",
      "pricing:*",
      "route53:*",
      "route53domains:*",
      "route53-recovery-cluster:*",
      "route53-recovery-control-config:*",
      "route53-recovery-readiness:*",
      "s3:GetBucketLocation",
      "s3:ListAllMyBuckets",
      "shield:*",
      "sts:*",
      "support:*",
      "trustedadvisor:*",
      "waf-regional:*",
      "waf:*",
      "wafv2:*",
      "wellarchitected:*",
    ]
    resources = ["*"]

    condition {
      test     = "StringNotEquals"
      variable = "aws:RequestedRegion"
      values   = var.allowed_regions
    }
  }

  # Deny Root Account Usage
  statement {
    sid       = "DenyRootUser"
    effect    = "Deny"
    actions   = ["*"]
    resources = ["*"]

    condition {
      test     = "StringLike"
      variable = "aws:PrincipalArn"
      values   = ["arn:aws:iam::*:root"]
    }
  }

  # Protect CloudTrail
  statement {
    sid    = "ProtectCloudTrail"
    effect = "Deny"
    actions = [
      "cloudtrail:DeleteTrail",
      "cloudtrail:StopLogging",
      "cloudtrail:UpdateTrail",
      "cloudtrail:PutEventSelectors",
    ]
    resources = ["*"]
  }

  # Protect Config
  statement {
    sid    = "ProtectConfig"
    effect = "Deny"
    actions = [
      "config:DeleteConfigRule",
      "config:DeleteConfigurationRecorder",
      "config:DeleteDeliveryChannel",
      "config:StopConfigurationRecorder",
    ]
    resources = ["*"]
  }

  # Protect GuardDuty
  statement {
    sid    = "ProtectGuardDuty"
    effect = "Deny"
    actions = [
      "guardduty:DeleteDetector",
      "guardduty:DisassociateFromMasterAccount",
      "guardduty:UpdateDetector",
    ]
    resources = ["*"]
  }

  # Deny S3 Public Access
  statement {
    sid    = "DenyS3PublicAccess"
    effect = "Deny"
    actions = [
      "s3:PutBucketPublicAccessBlock",
    ]
    resources = ["*"]

    condition {
      test     = "StringNotEquals"
      variable = "s3:PublicAccessBlockConfiguration/BlockPublicAcls"
      values   = ["true"]
    }
  }
}

resource "aws_organizations_policy" "guardrails" {
  name        = "aromaestro-guardrails"
  description = "Combined guardrails: region deny, root deny, protect CloudTrail/Config/GuardDuty, deny S3 public"
  type        = "SERVICE_CONTROL_POLICY"
  content     = data.aws_iam_policy_document.guardrails.json
}

resource "aws_organizations_policy_attachment" "guardrails" {
  policy_id = aws_organizations_policy.guardrails.id
  target_id = data.aws_organizations_organization.current.roots[0].id
}
