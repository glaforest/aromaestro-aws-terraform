output "guardrails_policy_id" {
  value = aws_organizations_policy.guardrails.id
}

output "organization_root_id" {
  value = data.aws_organizations_organization.current.roots[0].id
}
