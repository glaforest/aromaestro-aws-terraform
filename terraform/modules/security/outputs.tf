output "guardduty_detector_id" {
  value = aws_guardduty_detector.main.id
}

output "cloudtrail_arn" {
  value = aws_cloudtrail.main.arn
}

output "config_recorder_id" {
  value = aws_config_configuration_recorder.main.id
}
