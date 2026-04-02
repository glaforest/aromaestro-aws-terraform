output "instance_ids" {
  description = "Map of instance name to instance ID"
  value       = { for k, v in aws_instance.web : k => v.id }
}

output "instance_private_ips" {
  description = "Map of instance name to private IP"
  value       = { for k, v in aws_instance.web : k => v.private_ip }
}

output "web_app_security_group_id" {
  description = "Web app security group ID"
  value       = aws_security_group.web_app.id
}

output "ec2_role_arn" {
  description = "EC2 IAM role ARN"
  value       = aws_iam_role.ec2.arn
}
