# ============================================================
# AWS IoT -> site API pipeline (dev + prod)
# ============================================================
# Every diffuser talks to the single IoT endpoint of the prod account. Each MQTT
# flow has two topic rules that both fire on every message: one Lambda posts to
# dev.aromaestro.com, the other to www.aromaestro.com. Both sites must receive
# every event.
#
# All of this was created by hand and imported here on 2026-10-05 (import
# blocks removed once applied, see git history). Names, role paths and statement ids are kept as found, including
# the "iotCommanResponseToApi" typo, because renaming forces a replacement.

locals {
  account_id = "872515273944"
  region     = "ca-central-1"

  api_base_url = {
    dev  = "https://dev.aromaestro.com/index.php?route=api/"
    prod = "https://www.aromaestro.com/index.php?route=api/"
  }

  # One entry per MQTT flow. The dev and prod Lambdas run the same source.
  flows = {
    shadow = {
      source_dir   = "shadow"
      handler      = "index.handler"
      runtime      = "nodejs20.x"
      arch         = "arm64"
      api_route    = "diffuser_mqtt_shadow"
      sql          = "SELECT *, topic() AS topic FROM '$aws/things/+/shadow/update/documents'"
      device_field = "topic(3)"
    }
    logs = {
      source_dir   = "logs"
      handler      = "index.handler"
      runtime      = "nodejs22.x"
      arch         = "x86_64"
      api_route    = "diffuser_logs"
      sql          = "SELECT *, topic(3) as serial FROM 'aromaestro/things/+/logs'"
      device_field = "topic(3)"
    }
    command_response = {
      source_dir   = "command-response"
      handler      = "index.handler"
      runtime      = "nodejs22.x"
      arch         = "arm64"
      api_route    = "diffuser_mqtt_command_response"
      sql          = "SELECT *, topic(3) as serial FROM 'aromaestro/things/+/commands/response'"
      device_field = "topic(3)"
    }
    provision = {
      source_dir   = "provision"
      handler      = "lambda_function.handler"
      runtime      = "nodejs22.x"
      arch         = "arm64"
      api_route    = "diffuser_provision"
      sql          = "SELECT thingName, eventType, operation, timestamp() as provisioned_at FROM '$aws/events/thing/+/created'"
      device_field = "thingName"
    }
  }

  # One entry per Lambda, keyed by function name.
  # Dev entries use console-generated roles under /service-role/ with their
  # customer-managed policies; prod entries use roles created by CLI.
  functions = {
    iotShadowToApi = {
      flow                = "shadow"
      site                = "dev"
      rule_name           = "shadowUpdateToLambda"
      rule_description    = ""
      role_name           = "iotShadowToApi-role-szqdr2pz"
      role_path           = "/service-role/"
      role_description    = null
      managed_policy_arns = ["arn:aws:iam::872515273944:policy/service-role/AWSLambdaBasicExecutionRole-697f95c4-8ea7-4e18-9693-e9a9266406d9"]
      inline_logs_policy  = null
      description         = ""
      permission_sid      = "shadowUpdateToLambda"
      permission_account  = null
    }
    iotShadowToApiProd = {
      flow                = "shadow"
      site                = "prod"
      rule_name           = "shadowUpdateToLambdaProd"
      rule_description    = "Prod duplicate of shadowUpdateToLambda"
      role_name           = "iotShadowToApiProd-role"
      role_path           = "/"
      role_description    = "Execution role for iotShadowToApiProd (logs only)"
      managed_policy_arns = []
      inline_logs_policy  = "AWSLambdaBasicExecutionRole-iotShadowToApiProd"
      description         = ""
      permission_sid      = "shadowUpdateToLambdaProd"
      permission_account  = null
    }
    iotLogsToApi = {
      flow                = "logs"
      site                = "dev"
      rule_name           = "deviceLogsToLambda"
      rule_description    = ""
      role_name           = "iotLogsToApi-role-z8j1x3be"
      role_path           = "/service-role/"
      role_description    = null
      managed_policy_arns = ["arn:aws:iam::872515273944:policy/service-role/AWSLambdaBasicExecutionRole-5be96fbe-a623-49c9-b766-92e62daf81f8"]
      inline_logs_policy  = null
      description         = ""
      permission_sid      = "deviceLogsToLambda"
      permission_account  = null
    }
    iotLogsToApiProd = {
      flow                = "logs"
      site                = "prod"
      rule_name           = "deviceLogsToLambdaProd"
      rule_description    = "Prod duplicate of deviceLogsToLambda"
      role_name           = "iotLogsToApiProd-role"
      role_path           = "/"
      role_description    = "Execution role for iotLogsToApiProd (logs only)"
      managed_policy_arns = []
      inline_logs_policy  = "AWSLambdaBasicExecutionRole-iotLogsToApiProd"
      description         = ""
      permission_sid      = "deviceLogsToLambdaProd"
      permission_account  = null
    }
    iotCommanResponseToApi = {
      flow                = "command_response"
      site                = "dev"
      rule_name           = "commandResponseToLambda"
      rule_description    = ""
      role_name           = "iotCommanResponseToApi-role-8hn8n6kb"
      role_path           = "/service-role/"
      role_description    = null
      managed_policy_arns = ["arn:aws:iam::872515273944:policy/service-role/AWSLambdaBasicExecutionRole-1b9ac78f-aae6-4142-b09b-a6ea15aaee27"]
      inline_logs_policy  = null
      description         = ""
      permission_sid      = "commandResponseToLambda"
      permission_account  = null
    }
    iotCommandResponseToApiProd = {
      flow                = "command_response"
      site                = "prod"
      rule_name           = "commandResponseToLambdaProd"
      rule_description    = "Prod duplicate of commandResponseToLambda"
      role_name           = "iotCommandResponseToApiProd-role"
      role_path           = "/"
      role_description    = "Execution role for iotCommandResponseToApiProd (logs only)"
      managed_policy_arns = []
      inline_logs_policy  = "AWSLambdaBasicExecutionRole-iotCommandResponseToApiProd"
      description         = ""
      permission_sid      = "commandResponseToLambdaProd"
      permission_account  = null
    }
    ProvisionDevices = {
      flow             = "provision"
      site             = "dev"
      rule_name        = "CaptureDeviceProvisioning"
      rule_description = ""
      role_name        = "ProvisionDevices-role-w5rwbt3w"
      role_path        = "/service-role/"
      role_description = null
      managed_policy_arns = [
        "arn:aws:iam::872515273944:policy/service-role/AWSLambdaBasicExecutionRole-61a9a502-b89a-40c4-bb32-e7ed87dd14e0",
        "arn:aws:iam::872515273944:policy/service-role/AWSLambdaVPCAccessExecutionRole-b41f7572-4448-449c-92a7-74f051ed7f05",
      ]
      inline_logs_policy = null
      description        = ""
      permission_sid     = "CaptureDeviceProvisioning"
      permission_account = null
    }
    ProvisionDevicesProd = {
      flow                = "provision"
      site                = "prod"
      rule_name           = "CaptureDeviceProvisioningProd"
      rule_description    = null
      role_name           = "ProvisionDevicesProd-role"
      role_path           = "/"
      role_description    = "Execution role for ProvisionDevicesProd (IoT provisioning -> prod API)"
      managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
      inline_logs_policy  = null
      description         = "IoT thing created -> prod API diffuser_provision"
      permission_sid      = "iot-CaptureDeviceProvisioningProd"
      permission_account  = "872515273944"
    }
  }

  # Dev rules only see the devices listed in dev-devices.tf, so client
  # diffusers reach the prod site only. IoT SQL has no IN operator.
  dev_device_filter = {
    for name, f in local.flows : name => join(" OR ", [
      for serial in local.dev_device_serials : "${f.device_field} = '${serial}'"
    ])
  }

  rule_sql = {
    for fn, f in local.functions : fn => (
      f.site == "dev"
      ? "${local.flows[f.flow].sql} WHERE ${local.dev_device_filter[f.flow]}"
      : local.flows[f.flow].sql
    )
  }

  online_status_policy_arns = toset([
    "arn:aws:iam::872515273944:policy/service-role/aws-iot-rule-Online_Status-action-1-role-test",
  ])

  role_policy_attachments = merge([
    for fn, f in local.functions : {
      for arn in f.managed_policy_arns : "${fn}|${arn}" => { function = fn, policy_arn = arn }
    }
  ]...)
}

# ============================================================
# Lambda sources
# ============================================================
data "archive_file" "flow" {
  for_each = local.flows

  type        = "zip"
  source_dir  = "${path.module}/lambda/${each.value.source_dir}"
  output_path = "${path.module}/.build/${each.key}.zip"
}

# ============================================================
# Lambda execution roles
# ============================================================
data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  for_each = local.functions

  name               = each.value.role_name
  path               = each.value.role_path
  description        = each.value.role_description
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy_attachment" "lambda" {
  for_each = local.role_policy_attachments

  role       = aws_iam_role.lambda[each.value.function].name
  policy_arn = each.value.policy_arn
}

# Logs-only inline policy scoped to the function's own log group.
data "aws_iam_policy_document" "lambda_logs" {
  for_each = { for fn, f in local.functions : fn => f if f.inline_logs_policy != null }

  statement {
    actions   = ["logs:CreateLogGroup"]
    resources = ["arn:aws:logs:${local.region}:${local.account_id}:*"]
  }

  statement {
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/lambda/${each.key}:*"]
  }
}

resource "aws_iam_role_policy" "lambda_logs" {
  for_each = data.aws_iam_policy_document.lambda_logs

  name   = local.functions[each.key].inline_logs_policy
  role   = aws_iam_role.lambda[each.key].id
  policy = each.value.json
}

# ============================================================
# Lambdas
# ============================================================
resource "aws_lambda_function" "iot" {
  for_each = local.functions

  function_name    = each.key
  description      = each.value.description
  role             = aws_iam_role.lambda[each.key].arn
  runtime          = local.flows[each.value.flow].runtime
  handler          = local.flows[each.value.flow].handler
  architectures    = [local.flows[each.value.flow].arch]
  memory_size      = 128
  timeout          = 10
  filename         = data.archive_file.flow[each.value.flow].output_path
  source_code_hash = data.archive_file.flow[each.value.flow].output_base64sha256

  environment {
    variables = {
      API_URL = "${local.api_base_url[each.value.site]}${local.flows[each.value.flow].api_route}"
      API_KEY = var.api_keys[each.value.site]
    }
  }
}

resource "aws_lambda_permission" "iot_rule" {
  for_each = local.functions

  statement_id   = each.value.permission_sid
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.iot[each.key].function_name
  principal      = "iot.amazonaws.com"
  source_arn     = "arn:aws:iot:${local.region}:${local.account_id}:rule/${each.value.rule_name}"
  source_account = each.value.permission_account
}

# ============================================================
# Topic rules
# ============================================================
resource "aws_iot_topic_rule" "to_lambda" {
  for_each = local.functions

  name        = each.value.rule_name
  description = each.value.rule_description
  enabled     = true
  sql         = local.rule_sql[each.key]
  sql_version = "2016-03-23"

  lambda {
    function_arn = aws_lambda_function.iot[each.key].arn
  }
}

# Online_Status republishes the device's online flag into its shadow. The
# shadow update then fires both shadow rules, so dev and prod each receive it
# without a separate prod rule.
resource "aws_iam_role" "online_status_republish" {
  name = "test"
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

# Console-generated policy, kept attached but ineffective: its resource is
# topic/$$aws/things/+/shadow/update, and IAM matches neither the $$ escape nor
# the MQTT "+" wildcard. The republish only worked through AWSIoTFullAccess,
# which was removed on 2026-10-08 in favour of the inline policy below.
resource "aws_iam_role_policy_attachment" "online_status_republish" {
  for_each = local.online_status_policy_arns

  role       = aws_iam_role.online_status_republish.name
  policy_arn = each.value
}

resource "aws_iam_role_policy" "online_status_republish" {
  name = "republish-online-status-to-shadow"
  role = aws_iam_role.online_status_republish.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "iot:Publish"
      Resource = "arn:aws:iot:${local.region}:${local.account_id}:topic/$aws/things/*/shadow/update"
    }]
  })
}

resource "aws_iot_topic_rule" "online_status" {
  name        = "Online_Status"
  description = ""
  enabled     = true
  sql         = "SELECT * FROM 'aromaestro/things/+/online_status'"
  sql_version = "2016-03-23"

  republish {
    role_arn = aws_iam_role.online_status_republish.arn
    topic    = "$$aws/things/$${topic(3)}/shadow/update"
    qos      = 1
  }
}
