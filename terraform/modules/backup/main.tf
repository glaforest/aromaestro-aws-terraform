locals {
  name_prefix = "${var.project}-${var.environment}"
}

resource "aws_backup_vault" "main" {
  name = "${local.name_prefix}-backup-vault"
}

# ============================================================
# Backup Plan
# ============================================================

resource "aws_backup_plan" "main" {
  name = "${local.name_prefix}-backup-plan"

  rule {
    rule_name         = "daily-backup"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 7 * * ? *)"

    lifecycle {
      delete_after = var.is_production ? 7 : 3
    }
  }

  dynamic "rule" {
    for_each = var.is_production ? [1] : []
    content {
      rule_name         = "weekly-backup"
      target_vault_name = aws_backup_vault.main.name
      schedule          = "cron(0 7 ? * 1 *)"

      lifecycle {
        delete_after = 28
      }
    }
  }

  dynamic "rule" {
    for_each = var.is_production ? [1] : []
    content {
      rule_name         = "monthly-backup"
      target_vault_name = aws_backup_vault.main.name
      schedule          = "cron(0 7 1 * ? *)"

      lifecycle {
        cold_storage_after = 30
        delete_after       = 365
      }
    }
  }
}

# ============================================================
# Backup Selection (tag-based)
# ============================================================

resource "aws_iam_role" "backup" {
  name = "${local.name_prefix}-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "restore" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

resource "aws_backup_selection" "tagged_resources" {
  name         = "${local.name_prefix}-tagged-resources"
  iam_role_arn = aws_iam_role.backup.arn
  plan_id      = aws_backup_plan.main.id

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "Environment"
    value = var.environment == "development" ? "development" : "production"
  }
}
