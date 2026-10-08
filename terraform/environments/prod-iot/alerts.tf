# ============================================================
# Failed-event capture and alarms for the prod Lambdas (2026-10-08)
# ============================================================
# IoT rules invoke the Lambdas asynchronously: after 2 retries a failed event
# is dropped silently. Prod Lambdas now send those events to an SQS queue, and
# alarms mail it@aromaestro.com. Dev Lambdas are left without alerting.

locals {
  prod_functions = { for fn, f in local.functions : fn => f if f.site == "prod" }
  alert_email    = "it@aromaestro.com"
}

# ------------------------------------------------------------
# SNS topic
# ------------------------------------------------------------
# CloudWatch alarms cannot publish to a topic encrypted with the AWS-managed
# alias/aws/sns key (its key policy does not trust cloudwatch.amazonaws.com),
# so this topic uses a customer-managed key that does.
data "aws_iam_policy_document" "alerts_key" {
  statement {
    sid       = "AccountAdmin"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_id}:root"]
    }
  }

  statement {
    sid       = "CloudWatchAlarmsPublish"
    actions   = ["kms:Decrypt", "kms:GenerateDataKey*"]
    resources = ["*"]
    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }
  }
}

resource "aws_kms_key" "alerts" {
  description         = "prod-iot alerts SNS topic (CloudWatch alarms)"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.alerts_key.json
}

resource "aws_kms_alias" "alerts" {
  name          = "alias/prod-iot-alerts"
  target_key_id = aws_kms_key.alerts.key_id
}

resource "aws_sns_topic" "alerts" {
  name              = "prod-iot-alerts"
  kms_master_key_id = aws_kms_key.alerts.arn
}

# Stays "PendingConfirmation" until someone clicks the link mailed to the address.
resource "aws_sns_topic_subscription" "alerts_email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = local.alert_email
}

# ------------------------------------------------------------
# Failed events
# ------------------------------------------------------------
resource "aws_sqs_queue" "failed_events" {
  name                      = "prod-iot-failed-events"
  message_retention_seconds = 1209600 # 14 days, the SQS maximum
  sqs_managed_sse_enabled   = true
}

data "aws_iam_policy_document" "send_failed_events" {
  statement {
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.failed_events.arn]
  }
}

resource "aws_iam_role_policy" "send_failed_events" {
  for_each = local.prod_functions

  name   = "send-failed-events"
  role   = aws_iam_role.lambda[each.key].id
  policy = data.aws_iam_policy_document.send_failed_events.json
}

resource "aws_lambda_function_event_invoke_config" "prod" {
  for_each = local.prod_functions

  function_name                = aws_lambda_function.iot[each.key].function_name
  maximum_retry_attempts       = 2
  maximum_event_age_in_seconds = 21600

  destination_config {
    on_failure {
      destination = aws_sqs_queue.failed_events.arn
    }
  }

  depends_on = [aws_iam_role_policy.send_failed_events]
}

# ------------------------------------------------------------
# Alarms
# ------------------------------------------------------------
locals {
  # Per prod Lambda: any error, any event dropped without reaching the queue,
  # any failure to deliver to the queue.
  lambda_alarm_metrics = {
    errors               = "Errors"
    dropped              = "AsyncEventsDropped"
    destination_failures = "DestinationDeliveryFailures"
  }

  lambda_alarms = merge([
    for fn, f in local.prod_functions : {
      for key, metric in local.lambda_alarm_metrics : "${fn}-${key}" => {
        function = fn
        metric   = metric
      }
    }
  ]...)
}

resource "aws_cloudwatch_metric_alarm" "lambda" {
  for_each = local.lambda_alarms

  alarm_name          = "prod-iot-${each.key}"
  alarm_description   = "${each.value.metric} > 0 on ${each.value.function} (IoT -> www.aromaestro.com). Failed events are in SQS prod-iot-failed-events."
  namespace           = "AWS/Lambda"
  metric_name         = each.value.metric
  dimensions          = { FunctionName = each.value.function }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "failed_events_queue" {
  alarm_name          = "prod-iot-failed-events-queued"
  alarm_description   = "Events are waiting in SQS prod-iot-failed-events: the prod site rejected or did not answer them. Inspect, then replay or purge."
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  dimensions          = { QueueName = aws_sqs_queue.failed_events.name }
  statistic           = "Maximum"
  period              = 300
  evaluation_periods  = 1
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}
