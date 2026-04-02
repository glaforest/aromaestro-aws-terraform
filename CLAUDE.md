# Aromaestro AWS Infrastructure

## Project Overview

Multi-account AWS infrastructure for Aromaestro managed with Terraform. Inspired by a KPMG/Solist implementation but simplified with a zero-trust approach (Tailscale instead of VPN/Firewall).

**Region:** ca-central-1 (Canada)
**IaC:** Terraform >= 1.7, AWS Provider ~> 5.0
**Documentation:** `docs/README.md` (master index)
**Design spec:** `docs/specs/2026-04-02-aromaestro-aws-infrastructure-design.md`
**Implementation plan:** `docs/specs/2026-04-02-aromaestro-aws-infrastructure.md`

## AWS Accounts

| Compte | Account ID | CLI Profile | Role |
|---|---|---|---|
| Management | 589389426408 | aromaestro-mgmt | Billing, Organizations, SCPs, Budgets, Terraform state |
| Dev | 051370880327 | aromaestro-dev | Development workloads |
| Prod | 872515273944 | aromaestro-prod | Production workloads, IoT, SES |
| LogArchive | 315466292610 | aromaestro-logarchive | Centralized audit logs |

SSO portal: `https://d-9d674000e9.awsapps.com/start`

## Terraform Commands

```bash
# Renew SSO session
aws sso login --profile aromaestro-dev

# Dev environment
cd terraform/environments/dev
AWS_PROFILE=aromaestro-dev terraform plan
AWS_PROFILE=aromaestro-dev terraform apply

# Management (SCPs, budgets)
cd terraform/environments/management
AWS_PROFILE=aromaestro-mgmt terraform plan
AWS_PROFILE=aromaestro-mgmt terraform apply

# Prod environment (code ready, not yet deployed)
cd terraform/environments/prod
AWS_PROFILE=aromaestro-prod terraform plan
AWS_PROFILE=aromaestro-prod terraform apply

# State backend bootstrap (one-time, already done)
cd terraform/backend
AWS_PROFILE=aromaestro-mgmt terraform apply
```

**Backend:** S3 (`aromaestro-terraform-state`) + DynamoDB (`aromaestro-terraform-locks`) in Management account. All environments use `profile = "aromaestro-mgmt"` in their backend config. Provider uses `AWS_PROFILE` env var for the target account.

## Project Structure

```
terraform/
  backend/                 # S3 + DynamoDB for Terraform state (bootstrap, local state)
  modules/
    vpc/                   # VPC, subnets, route tables, NAT, IGW, flow logs, S3 endpoint
    ec2/                   # EC2 instances, IAM role, security groups, user_data template
    rds/                   # RDS MySQL, DB subnet group, parameter group, security group
    s3/                    # S3 buckets, encryption, versioning, lifecycle, TLS policy
    security/              # GuardDuty, Inspector, SecurityHub, CloudTrail, Config, EBS encryption
    monitoring/            # CloudWatch alarms, SNS, EventBridge rules
    backup/                # AWS Backup vault, plans, selections
    patching/              # SSM Patch Manager, maintenance windows
    budgets/               # AWS Budgets, Cost Anomaly Detection (commented out pending activation)
    organizations/         # Combined SCP guardrails
  environments/
    management/            # Organizations, SCPs, Budgets
    dev/                   # Full dev environment (all modules wired up, deployed)
    prod/                  # Prod environment (code ready, not yet deployed)
    logarchive/            # LogArchive account (placeholder, not yet implemented)
docs/
  README.md                # Master index
  getting-started.md       # New machine setup guide
  architecture/            # Overview, accounts, network
  infrastructure/          # Compute, database, storage
  security/                # Services, IAM, encryption
  operations/              # Monitoring, backup, patching
  runbooks/                # Incident response, restore procedures
  specs/                   # Design spec and implementation plan
```

## Deployment Status

- **Phase 1 (Foundation):** DONE - accounts, SSO, state backend, SCPs, budgets
- **Phase 2 (Dev):** DONE - 108 resources deployed
- **Phase 3 (Prod):** CODE READY, NOT YET DEPLOYED - uses same modules, see getting-started.md for deploy steps

## Key Architecture Decisions

- **No assume_role:** Each environment uses its own `AWS_PROFILE`. Backend always uses `aromaestro-mgmt`.
- **web-site is public:** `web-site` instance is in the public subnet with an Elastic IP and inbound 80/443. Other instances (web-admin, web-wordpress, web-openclaw) are in private subnets with zero inbound ports.
- **NAT instance in dev:** Amazon Linux 2023 (t4g.nano) with IP forwarding + iptables MASQUERADE. Interface auto-detected. Saves ~$40/mo vs NAT Gateway.
- **NAT Gateway in prod:** More reliable for production.
- **Tailscale zero-trust:** All instance access via Tailscale mesh VPN. Auth key in Secrets Manager. Installed automatically at first boot via user_data (installs AWS CLI v2, Tailscale, CloudWatch Agent). Fallback: SSM Run Command if user_data fails.
- **S3 logs bucket uses AES256:** Not KMS, for CloudTrail/Config write compatibility. Assets buckets use SSE-KMS (default).
- **SCPs combined:** Single policy `aromaestro-guardrails` (AWS limit of 5 SCPs per target).
- **CloudWatch Agent required:** Memory and disk metrics need the CWAgent installed on each EC2.
- **CloudTrail multi-region:** Required by SecurityHub Foundational Best Practices standard.

## Pending Items

- Cost Anomaly Detection: uncomment in `modules/budgets/main.tf` after Cost Explorer is active (24h after activation on 2026-04-02)
- Tailscale auth key rotation: automate with Lambda + EventBridge
- LogArchive CloudTrail centralization: future work
- Prod environment deployment: code ready, see getting-started.md etape 5

## Dev Environment Resources

| Resource | Details |
|---|---|
| VPC | 10.1.0.0/16 |
| web-site | t4g.micro, public subnet, EIP, inbound 80/443 |
| web-admin | t4g.micro, private subnet, zero inbound |
| web-wordpress | t4g.micro, private subnet, zero inbound |
| web-openclaw | t4g.micro, private subnet, zero inbound |
| RDS | MySQL 8.0, db.t4g.micro, TLS enforced, password in Secrets Manager |
| S3 | aromaestro-dev-assets (SSE-KMS), aromaestro-dev-logs (AES256) |
| Security | GuardDuty, Inspector, SecurityHub, CloudTrail (multi-region), Config (4 rules) |
| Monitoring | 23 CloudWatch alarms, SNS email alerts, 2 EventBridge rules (GuardDuty/Inspector) |
| Backup | Daily 7:00 UTC, 3-day retention |
| Patching | Sunday 8:00 UTC (3AM EST), automatic |
