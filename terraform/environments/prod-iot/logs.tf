# Lambda log groups, 90-day retention (decided 2026-10-08). Lambda creates
# /aws/lambda/<name> on first run with no expiry; these were imported so the
# history is kept. Never let Terraform replace one: that deletes its logs.
resource "aws_cloudwatch_log_group" "lambda" {
  for_each = local.functions

  name              = "/aws/lambda/${each.key}"
  retention_in_days = 90

  lifecycle {
    prevent_destroy = true
  }
}
