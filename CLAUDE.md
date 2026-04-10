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

# Prod-OTA environment (IoT OTA pipeline, deployed)
cd terraform/environments/prod-ota
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
    prod-ota/              # IoT OTA pipeline (same prod account, isolated state, deployed)
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
- **Phase 3.5 (Prod-OTA):** DONE - IoT OTA pipeline for ESP32-C5 diffuser firmware (separate Terraform env in the prod account, isolated state)

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
- **IMDSv2 enforced:** `http_tokens = required` on all EC2 instances (CIS EC2.8).
- **SNS encrypted:** KMS `alias/aws/sns` on all SNS topics (CIS SNS.1).
- **Default VPC SG restricted:** No ingress/egress rules on default security group (CIS 5.4).
- **All S3 buckets enforce TLS:** Including Terraform state bucket.
- **Prod-OTA is its own Terraform env:** `terraform/environments/prod-ota/` owns the AWS IoT OTA pipeline (bucket, ACM cert, Signer profile, IoT role, ota_user). Isolated state (`env/prod-ota/terraform.tfstate`) so the pipeline isn't coupled to the unapplied Phase 3 `prod/` code. Same prod AWS account, same backend bucket.
- **Signer profile via terraform_data:** AWS Signer requires `signingParameters.certname` for FreeRTOS OTA, but the hashicorp/aws provider doesn't expose that argument. `prod-ota` manages the profile through `terraform_data` + `local-exec` calling `aws signer put-signing-profile`. Create-only: changing the cert requires picking a new profile name because canceled Signer names are permanently reserved.

## Pending Items

- Cost Anomaly Detection: uncomment in `modules/budgets/main.tf` after Cost Explorer is active (24h after activation on 2026-04-02)
- Tailscale auth key rotation: automate with Lambda + EventBridge
- LogArchive CloudTrail centralization: future work
- Prod environment deployment: code ready, see getting-started.md etape 5
- Clean up `module.existing_diffuser_ota` from `terraform/environments/prod/main.tf` when Phase 3 prod is eventually deployed — the bucket is now owned by `prod-ota` state, so leaving it in `prod/main.tf` would cause a state conflict on Phase 3 apply

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

## Prod-OTA Environment Resources

| Resource | Details |
|---|---|
| S3 | aromaestro-diffuser-ota (imported, versioned, SSE-S3, TLS enforced, 90d expiration on signed/ prefix) |
| ACM cert | CN=DiffuserOTACodeSign subject, ECDSA P-256, serial 091AC033257B23E5BB494764E4CA5B9213F3E4C7, prevent_destroy |
| Signer profile | AromaestroESP32C5OTACodeSign (platform AmazonFreeRTOS-Default, certname=/cert.pem, managed via terraform_data + local-exec) |
| IAM role | AWSIoTOTAUpdateRole (trust iot.amazonaws.com, inline S3+Signer+IoT Jobs/Streams+PassRole self) |
| IAM user | ota_user (service account, path /service-accounts/, OtaDeployPolicy with S3+IoT OTA+Signer+scoped PassRole) |
| Consumed by | `scripts/deploy-ota.sh` in the firmware repo at `/Applications/Work/Diffusers_Firmwares/diffuser_firmware_esp32` |

See `docs/infrastructure/ota.md` for full details.
