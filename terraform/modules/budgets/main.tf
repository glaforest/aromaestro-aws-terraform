resource "aws_budgets_budget" "monthly" {
  name         = "${var.project}-monthly-budget"
  budget_type  = "COST"
  limit_amount = var.budget_limit
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }
}

## Cost Anomaly Detection
## Uncomment after Cost Explorer is active (can take up to 24h after activation)
#
# resource "aws_ce_anomaly_monitor" "main" {
#   name              = "${var.project}-cost-anomaly-monitor"
#   monitor_type      = "DIMENSIONAL"
#   monitor_dimension = "SERVICE"
# }
#
# resource "aws_ce_anomaly_subscription" "main" {
#   name = "${var.project}-cost-anomaly-alerts"
#
#   monitor_arn_list = [aws_ce_anomaly_monitor.main.arn]
#
#   subscriber {
#     type    = "EMAIL"
#     address = var.alert_email
#   }
#
#   frequency = "DAILY"
#
#   threshold_expression {
#     dimension {
#       key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
#       match_options = ["GREATER_THAN_OR_EQUAL"]
#       values        = ["20"]
#     }
#   }
# }
