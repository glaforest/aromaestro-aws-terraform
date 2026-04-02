locals {
  name_prefix = "${var.project}-${var.environment}"
}

resource "aws_ssm_patch_baseline" "ubuntu" {
  name             = "${local.name_prefix}-ubuntu-baseline"
  operating_system = "UBUNTU"

  approval_rule {
    approve_after_days = 7
    compliance_level   = "HIGH"

    patch_filter {
      key    = "PRIORITY"
      values = ["Required", "Important"]
    }
  }
}

resource "aws_ssm_maintenance_window" "patching" {
  name                       = "${local.name_prefix}-patching-window"
  schedule                   = "cron(0 8 ? * SUN *)"
  duration                   = 3
  cutoff                     = 1
  allow_unassociated_targets = false
}

resource "aws_ssm_maintenance_window_target" "tagged" {
  window_id     = aws_ssm_maintenance_window.patching.id
  name          = "tagged-instances"
  resource_type = "INSTANCE"

  targets {
    key    = "tag:Environment"
    values = [var.environment == "development" ? "development" : "production"]
  }
}

resource "aws_ssm_maintenance_window_task" "patch" {
  window_id        = aws_ssm_maintenance_window.patching.id
  task_type        = "RUN_COMMAND"
  task_arn         = "AWS-RunPatchBaseline"
  priority         = 1
  max_concurrency  = "50%"
  max_errors       = "0"

  targets {
    key    = "WindowTargetIds"
    values = [aws_ssm_maintenance_window_target.tagged.id]
  }

  task_invocation_parameters {
    run_command_parameters {
      parameter {
        name   = "Operation"
        values = ["Install"]
      }
      parameter {
        name   = "RebootOption"
        values = ["RebootIfNeeded"]
      }
    }
  }
}
