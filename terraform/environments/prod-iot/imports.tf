# One-time adoption of the hand-made IoT pipeline (2026-10-05).
# Import blocks are no-ops once the resources are in state; they can be
# deleted after the first successful apply.

import {
  for_each = local.functions
  to       = aws_iam_role.lambda[each.key]
  id       = each.value.role_name
}

import {
  for_each = local.role_policy_attachments
  to       = aws_iam_role_policy_attachment.lambda[each.key]
  id       = "${local.functions[each.value.function].role_name}/${each.value.policy_arn}"
}

import {
  for_each = { for fn, f in local.functions : fn => f if f.inline_logs_policy != null }
  to       = aws_iam_role_policy.lambda_logs[each.key]
  id       = "${each.value.role_name}:${each.value.inline_logs_policy}"
}

import {
  for_each = local.functions
  to       = aws_lambda_function.iot[each.key]
  id       = each.key
}

import {
  for_each = local.functions
  to       = aws_lambda_permission.iot_rule[each.key]
  id       = "${each.key}/${each.value.permission_sid}"
}

import {
  for_each = local.functions
  to       = aws_iot_topic_rule.to_lambda[each.key]
  id       = each.value.rule_name
}

import {
  to = aws_iam_role.online_status_republish
  id = "test"
}

import {
  for_each = local.online_status_policy_arns
  to       = aws_iam_role_policy_attachment.online_status_republish[each.key]
  id       = "test/${each.key}"
}

import {
  to = aws_iot_topic_rule.online_status
  id = "Online_Status"
}
