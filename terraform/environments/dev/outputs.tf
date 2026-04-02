output "vpc_id" {
  value = module.vpc.vpc_id
}

output "ec2_instance_ids" {
  value = merge(module.ec2.instance_ids, { "web-site" = aws_instance.web_site.id })
}

output "ec2_private_ips" {
  value = merge(module.ec2.instance_private_ips, { "web-site" = aws_instance.web_site.private_ip })
}

output "web_site_public_ip" {
  value = aws_eip.web_site.public_ip
}

output "rds_endpoint" {
  value     = module.rds.endpoint
  sensitive = true
}

output "tailscale_secret_arn" {
  value = aws_secretsmanager_secret.tailscale.arn
}
