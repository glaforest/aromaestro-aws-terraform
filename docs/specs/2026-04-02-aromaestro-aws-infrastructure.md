# Aromaestro AWS Infrastructure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deploy a multi-account AWS infrastructure for Aromaestro with zero-trust networking (Tailscale), starting with dev then prod.

**Architecture:** Multi-account AWS Organizations (Management, Dev, LogArchive, Prod) with Terraform IaC. Each account gets a VPC with private subnets + NAT for egress. EC2 instances run Tailscale with no inbound ports. RDS MySQL shared per environment. Security stack (GuardDuty, Inspector, SecurityHub, CloudTrail, Config) on all accounts.

**Tech Stack:** Terraform >= 1.7, AWS Provider >= 5.0, ca-central-1 region, Ubuntu 24.04 ARM (t4g Graviton)

**Spec:** `docs/superpowers/specs/2026-04-02-aromaestro-aws-infrastructure-design.md`

**Documentation:** Each task produces or updates documentation in `docs/`. The `docs/README.md` is the master index (GitHub-style) linking to all sub-documents.

---

## Phase 1: Foundation

### Task 1: Project Scaffolding + Terraform Configuration

**Files:**
- Create: `terraform/modules/.gitkeep`
- Create: `terraform/environments/management/providers.tf`
- Create: `terraform/environments/management/versions.tf`
- Create: `terraform/environments/management/variables.tf`
- Create: `terraform/environments/dev/providers.tf`
- Create: `terraform/environments/dev/versions.tf`
- Create: `terraform/environments/dev/variables.tf`
- Create: `terraform/environments/logarchive/providers.tf`
- Create: `terraform/environments/logarchive/versions.tf`
- Create: `terraform/environments/logarchive/variables.tf`
- Create: `terraform/environments/prod/providers.tf`
- Create: `terraform/environments/prod/versions.tf`
- Create: `terraform/environments/prod/variables.tf`
- Create: `terraform/locals.tf` (shared tag defaults)
- Create: `.gitignore`
- Create: `docs/README.md`
- Create: `docs/architecture/overview.md`

- [ ] **Step 1: Create .gitignore for Terraform project**

```gitignore
# Terraform
*.tfstate
*.tfstate.*
*.tfvars
!*.tfvars.example
.terraform/
.terraform.lock.hcl
crash.log
crash.*.log
override.tf
override.tf.json
*_override.tf
*_override.tf.json
*.tfplan

# OS
.DS_Store
```

- [ ] **Step 2: Create shared versions.tf template**

Every environment uses the same provider versions. Create `terraform/environments/dev/versions.tf`:

```hcl
terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

Copy the same file to `management/`, `logarchive/`, and `prod/` directories.

- [ ] **Step 3: Create dev environment providers.tf**

```hcl
# terraform/environments/dev/providers.tf
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "development"
      ManagedBy   = "terraform"
      Owner       = "aromaestro"
    }
  }
}
```

- [ ] **Step 4: Create dev environment variables.tf**

```hcl
# terraform/environments/dev/variables.tf
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ca-central-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "development"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "aromaestro"
}
```

- [ ] **Step 5: Create management environment providers.tf**

```hcl
# terraform/environments/management/providers.tf
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "management"
      ManagedBy   = "terraform"
      Owner       = "aromaestro"
    }
  }
}
```

- [ ] **Step 6: Create management environment variables.tf**

```hcl
# terraform/environments/management/variables.tf
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ca-central-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "management"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "aromaestro"
}
```

- [ ] **Step 7: Create logarchive environment providers.tf and variables.tf**

`terraform/environments/logarchive/providers.tf`:
```hcl
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "logarchive"
      ManagedBy   = "terraform"
      Owner       = "aromaestro"
    }
  }
}
```

`terraform/environments/logarchive/variables.tf`:
```hcl
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ca-central-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "logarchive"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "aromaestro"
}
```

- [ ] **Step 8: Create prod environment providers.tf and variables.tf**

`terraform/environments/prod/providers.tf`:
```hcl
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "production"
      ManagedBy   = "terraform"
      Owner       = "aromaestro"
    }
  }
}
```

`terraform/environments/prod/variables.tf`:
```hcl
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ca-central-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "aromaestro"
}
```

- [ ] **Step 9: Create docs/README.md (master index)**

```markdown
# Aromaestro - Documentation Technique AWS

Documentation technique de l'infrastructure AWS Aromaestro.

**Version:** 1.0
**Region:** ca-central-1 (Canada)
**IaC:** Terraform

---

## Table des matieres

### Architecture
- [Vue d'ensemble](architecture/overview.md)

### Infrastructure
*(a venir)*

### Securite
*(a venir)*

### Operations
*(a venir)*

### Runbooks
*(a venir)*
```

- [ ] **Step 10: Create docs/architecture/overview.md**

```markdown
# Vue d'ensemble de l'architecture

## Resume

Infrastructure AWS multi-compte pour Aromaestro utilisant une approche zero-trust avec Tailscale.

## Structure des comptes

| Compte | Role | ID |
|---|---|---|
| Management | Facturation, Organizations, IAM Identity Center, SCPs | *(a completer)* |
| Prod | Workloads de production, IoT, SES | *(compte Aromaestro existant)* |
| Dev | Miroir simplifie de Prod | *(a completer)* |
| LogArchive | Centralisation des logs CloudTrail | *(a completer)* |

## Principes architecturaux

- **Zero-trust** : Tailscale comme overlay reseau, aucun port inbound sur les instances
- **Subnets prives** : 1 seul subnet public par VPC (NAT uniquement)
- **Infrastructure as Code** : 100% Terraform, state distant S3 + DynamoDB
- **Dev-first** : tout est valide en Dev avant deploiement en Prod
- **Chiffrement partout** : EBS, S3 (SSE-S3 + TLS), RDS (KMS + TLS)

## Estimation des couts

| | Prod | Dev |
|---|---|---|
| **Total** | ~$221/mois | ~$84/mois |
| **Total combine** | **~$305/mois** | |
```

- [ ] **Step 11: Validate project structure**

Run:
```bash
cd /Users/gabriellaforest/Desktop/KPMG
find terraform/ docs/ -type f | sort
```

Expected output:
```
docs/README.md
docs/architecture/overview.md
terraform/environments/dev/providers.tf
terraform/environments/dev/variables.tf
terraform/environments/dev/versions.tf
terraform/environments/logarchive/providers.tf
terraform/environments/logarchive/variables.tf
terraform/environments/logarchive/versions.tf
terraform/environments/management/providers.tf
terraform/environments/management/variables.tf
terraform/environments/management/versions.tf
terraform/environments/prod/providers.tf
terraform/environments/prod/variables.tf
terraform/environments/prod/versions.tf
```

- [ ] **Step 12: Commit**

```bash
git add .gitignore terraform/ docs/
git commit -m "feat: scaffold Terraform project structure and docs index"
```

---

### Task 2: Manual Account Setup (User Action Required)

This task requires the user to perform manual actions in the AWS Console. Claude assists by providing exact step-by-step instructions.

**Files:**
- Update: `docs/architecture/overview.md` (fill in account IDs)
- Create: `docs/architecture/accounts.md`

- [ ] **Step 1: User creates new Management account**

Instruct the user:
> 1. Go to https://portal.aws.amazon.com/billing/signup
> 2. Create a new AWS account with a **dedicated email** (e.g. aws-management@aromaestro.com)
> 3. Enable MFA on the root user immediately
> 4. Note the Account ID

- [ ] **Step 2: User enables AWS Organizations**

Instruct the user:
> 1. Sign into the new Management account
> 2. Go to AWS Organizations console
> 3. Click "Create an organization"
> 4. Choose "All features" (not just consolidated billing)

- [ ] **Step 3: User creates Dev account**

Instruct the user:
> 1. In Organizations, click "Add an AWS account" > "Create an AWS account"
> 2. Account name: `aromaestro-dev`
> 3. Email: `aws-dev@aromaestro.com`
> 4. Note the Account ID

- [ ] **Step 4: User creates LogArchive account**

Instruct the user:
> 1. In Organizations, click "Add an AWS account" > "Create an AWS account"
> 2. Account name: `aromaestro-logarchive`
> 3. Email: `aws-logarchive@aromaestro.com`
> 4. Note the Account ID

- [ ] **Step 5: User invites Aromaestro (Prod) account**

Instruct the user:
> 1. In Organizations, click "Add an AWS account" > "Invite an existing account"
> 2. Enter the Aromaestro account ID or root email
> 3. Sign into the Aromaestro account and accept the invitation

- [ ] **Step 6: User enables IAM Identity Center**

Instruct the user:
> 1. In the Management account, go to IAM Identity Center
> 2. Click "Enable"
> 3. Choose "Identity Center directory" as identity source
> 4. Create your admin user with MFA enforced
> 5. Create an "Admin" permission set with AdministratorAccess
> 6. Assign the admin user to all 4 accounts with the Admin permission set

- [ ] **Step 7: Write docs/architecture/accounts.md**

```markdown
# Structure des comptes AWS

## AWS Organizations

| Compte | Nom | Email | Account ID | Role |
|---|---|---|---|---|
| Management | aromaestro-mgmt | aws-management@aromaestro.com | *(ID)* | Facturation, Organizations, IAM Identity Center |
| Prod | aromaestro-prod | *(email existant)* | *(ID existant)* | Workloads production, IoT, SES |
| Dev | aromaestro-dev | aws-dev@aromaestro.com | *(ID)* | Environnement de developpement |
| LogArchive | aromaestro-logarchive | aws-logarchive@aromaestro.com | *(ID)* | Centralisation des logs d'audit |

## IAM Identity Center (SSO)

| Role | Permissions | Comptes |
|---|---|---|
| Admin | AdministratorAccess | Tous |
| Developer | Full access dev, ReadOnly prod | Dev, Prod |
| Emergency | AdministratorAccess (break-glass) | Tous |

- MFA obligatoire sur tous les utilisateurs
- Acces via https://aromaestro.awsapps.com/start

## SCPs

Voir [securite/services.md](../security/services.md) pour le detail des SCPs.
```

- [ ] **Step 8: Update docs/README.md to add accounts link**

Add under Architecture section:
```markdown
- [Structure des comptes](architecture/accounts.md)
```

- [ ] **Step 9: Commit**

```bash
git add docs/
git commit -m "docs: add account structure documentation"
```

---

### Task 3: Terraform State Backend (Bootstrap)

**Files:**
- Create: `terraform/backend/main.tf`
- Create: `terraform/backend/variables.tf`
- Create: `terraform/backend/outputs.tf`
- Update: `terraform/environments/dev/versions.tf` (add backend config)
- Update: `terraform/environments/management/versions.tf` (add backend config)
- Update: `terraform/environments/logarchive/versions.tf` (add backend config)
- Update: `terraform/environments/prod/versions.tf` (add backend config)

- [ ] **Step 1: Create the bootstrap backend configuration**

This is a chicken-and-egg: the backend itself must be created before other Terraform can use it. We create it with local state first, then migrate.

`terraform/backend/main.tf`:
```hcl
terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "management"
      ManagedBy   = "terraform"
      Owner       = "aromaestro"
    }
  }
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "aromaestro-terraform-state"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "aromaestro-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
```

- [ ] **Step 2: Create backend variables.tf**

`terraform/backend/variables.tf`:
```hcl
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ca-central-1"
}
```

- [ ] **Step 3: Create backend outputs.tf**

`terraform/backend/outputs.tf`:
```hcl
output "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.id
}

output "state_bucket_arn" {
  description = "ARN of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.arn
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for Terraform locks"
  value       = aws_dynamodb_table.terraform_locks.id
}
```

- [ ] **Step 4: Initialize and apply backend (user must run)**

Instruct the user:
```bash
cd terraform/backend
terraform init
terraform plan
terraform apply
```

Expected: S3 bucket `aromaestro-terraform-state` and DynamoDB table `aromaestro-terraform-locks` created.

- [ ] **Step 5: Add backend config to all environments**

Update `terraform/environments/dev/versions.tf`:
```hcl
terraform {
  required_version = ">= 1.7.0"

  backend "s3" {
    bucket         = "aromaestro-terraform-state"
    key            = "env/dev/terraform.tfstate"
    region         = "ca-central-1"
    dynamodb_table = "aromaestro-terraform-locks"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

Update `terraform/environments/management/versions.tf`:
```hcl
terraform {
  required_version = ">= 1.7.0"

  backend "s3" {
    bucket         = "aromaestro-terraform-state"
    key            = "env/management/terraform.tfstate"
    region         = "ca-central-1"
    dynamodb_table = "aromaestro-terraform-locks"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

Update `terraform/environments/logarchive/versions.tf`:
```hcl
terraform {
  required_version = ">= 1.7.0"

  backend "s3" {
    bucket         = "aromaestro-terraform-state"
    key            = "env/logarchive/terraform.tfstate"
    region         = "ca-central-1"
    dynamodb_table = "aromaestro-terraform-locks"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

Update `terraform/environments/prod/versions.tf`:
```hcl
terraform {
  required_version = ">= 1.7.0"

  backend "s3" {
    bucket         = "aromaestro-terraform-state"
    key            = "env/prod/terraform.tfstate"
    region         = "ca-central-1"
    dynamodb_table = "aromaestro-terraform-locks"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

- [ ] **Step 6: Validate backend config**

Instruct the user:
```bash
cd terraform/environments/dev
terraform init
```

Expected: `Terraform has been successfully initialized!` with S3 backend.

- [ ] **Step 7: Commit**

```bash
git add terraform/backend/ terraform/environments/
git commit -m "feat: add Terraform state backend (S3 + DynamoDB)"
```

---

### Task 4: Organizations SCPs Module

**Files:**
- Create: `terraform/modules/organizations/main.tf`
- Create: `terraform/modules/organizations/variables.tf`
- Create: `terraform/modules/organizations/outputs.tf`
- Update: `terraform/environments/management/main.tf`
- Create: `docs/security/services.md`

- [ ] **Step 1: Create the organizations module**

`terraform/modules/organizations/variables.tf`:
```hcl
variable "allowed_regions" {
  description = "List of allowed AWS regions"
  type        = list(string)
  default     = ["ca-central-1"]
}
```

- [ ] **Step 2: Create the SCP policies**

`terraform/modules/organizations/main.tf`:
```hcl
# Region Deny SCP
data "aws_iam_policy_document" "region_deny" {
  statement {
    sid       = "RegionDeny"
    effect    = "Deny"
    actions   = ["*"]
    resources = ["*"]

    condition {
      test     = "StringNotEquals"
      variable = "aws:RequestedRegion"
      values   = var.allowed_regions
    }

    condition {
      test     = "StringNotLike"
      variable = "aws:PrincipalArn"
      values   = ["arn:aws:iam::*:role/OrganizationAccountAccessRole"]
    }

    # Exclude global services
    condition {
      test     = "StringNotEquals"
      variable = "aws:Service"
      values = [
        "iam",
        "organizations",
        "sts",
        "support",
        "budgets",
        "ce",
        "health",
        "route53",
      ]
    }
  }
}

resource "aws_organizations_policy" "region_deny" {
  name        = "region-deny"
  description = "Restrict operations to ca-central-1 only"
  type        = "SERVICE_CONTROL_POLICY"
  content     = data.aws_iam_policy_document.region_deny.json
}

resource "aws_organizations_policy_attachment" "region_deny" {
  policy_id = aws_organizations_policy.region_deny.id
  target_id = data.aws_organizations_organization.current.roots[0].id
}

# Deny Root Account Usage on member accounts
data "aws_iam_policy_document" "deny_root" {
  statement {
    sid       = "DenyRootUser"
    effect    = "Deny"
    actions   = ["*"]
    resources = ["*"]

    condition {
      test     = "StringLike"
      variable = "aws:PrincipalArn"
      values   = ["arn:aws:iam::*:root"]
    }
  }
}

resource "aws_organizations_policy" "deny_root" {
  name        = "deny-root-usage"
  description = "Deny root account usage on member accounts"
  type        = "SERVICE_CONTROL_POLICY"
  content     = data.aws_iam_policy_document.deny_root.json
}

resource "aws_organizations_policy_attachment" "deny_root" {
  policy_id = aws_organizations_policy.deny_root.id
  target_id = data.aws_organizations_organization.current.roots[0].id
}

# Protect CloudTrail
data "aws_iam_policy_document" "protect_cloudtrail" {
  statement {
    sid    = "ProtectCloudTrail"
    effect = "Deny"
    actions = [
      "cloudtrail:DeleteTrail",
      "cloudtrail:StopLogging",
      "cloudtrail:UpdateTrail",
      "cloudtrail:PutEventSelectors",
    ]
    resources = ["*"]
  }
}

resource "aws_organizations_policy" "protect_cloudtrail" {
  name        = "protect-cloudtrail"
  description = "Prevent disabling or modifying CloudTrail"
  type        = "SERVICE_CONTROL_POLICY"
  content     = data.aws_iam_policy_document.protect_cloudtrail.json
}

resource "aws_organizations_policy_attachment" "protect_cloudtrail" {
  policy_id = aws_organizations_policy.protect_cloudtrail.id
  target_id = data.aws_organizations_organization.current.roots[0].id
}

# Protect Config
data "aws_iam_policy_document" "protect_config" {
  statement {
    sid    = "ProtectConfig"
    effect = "Deny"
    actions = [
      "config:DeleteConfigRule",
      "config:DeleteConfigurationRecorder",
      "config:DeleteDeliveryChannel",
      "config:StopConfigurationRecorder",
    ]
    resources = ["*"]
  }
}

resource "aws_organizations_policy" "protect_config" {
  name        = "protect-config"
  description = "Prevent disabling or modifying Config"
  type        = "SERVICE_CONTROL_POLICY"
  content     = data.aws_iam_policy_document.protect_config.json
}

resource "aws_organizations_policy_attachment" "protect_config" {
  policy_id = aws_organizations_policy.protect_config.id
  target_id = data.aws_organizations_organization.current.roots[0].id
}

# Protect GuardDuty
data "aws_iam_policy_document" "protect_guardduty" {
  statement {
    sid    = "ProtectGuardDuty"
    effect = "Deny"
    actions = [
      "guardduty:DeleteDetector",
      "guardduty:DisassociateFromMasterAccount",
      "guardduty:UpdateDetector",
    ]
    resources = ["*"]
  }
}

resource "aws_organizations_policy" "protect_guardduty" {
  name        = "protect-guardduty"
  description = "Prevent disabling GuardDuty"
  type        = "SERVICE_CONTROL_POLICY"
  content     = data.aws_iam_policy_document.protect_guardduty.json
}

resource "aws_organizations_policy_attachment" "protect_guardduty" {
  policy_id = aws_organizations_policy.protect_guardduty.id
  target_id = data.aws_organizations_organization.current.roots[0].id
}

# Deny S3 Public Access
data "aws_iam_policy_document" "deny_s3_public" {
  statement {
    sid    = "DenyS3PublicAccess"
    effect = "Deny"
    actions = [
      "s3:PutBucketPublicAccessBlock",
    ]
    resources = ["*"]

    condition {
      test     = "StringNotEquals"
      variable = "s3:PublicAccessBlockConfiguration/BlockPublicAcls"
      values   = ["true"]
    }
  }
}

resource "aws_organizations_policy" "deny_s3_public" {
  name        = "deny-s3-public-access"
  description = "Prevent creating public S3 buckets"
  type        = "SERVICE_CONTROL_POLICY"
  content     = data.aws_iam_policy_document.deny_s3_public.json
}

resource "aws_organizations_policy_attachment" "deny_s3_public" {
  policy_id = aws_organizations_policy.deny_s3_public.id
  target_id = data.aws_organizations_organization.current.roots[0].id
}

# Data source for current organization
data "aws_organizations_organization" "current" {}
```

- [ ] **Step 3: Create the organizations outputs**

`terraform/modules/organizations/outputs.tf`:
```hcl
output "region_deny_policy_id" {
  value = aws_organizations_policy.region_deny.id
}

output "organization_root_id" {
  value = data.aws_organizations_organization.current.roots[0].id
}
```

- [ ] **Step 4: Wire up in management environment**

`terraform/environments/management/main.tf`:
```hcl
module "organizations" {
  source          = "../../modules/organizations"
  allowed_regions = ["ca-central-1"]
}
```

- [ ] **Step 5: Validate**

Instruct the user:
```bash
cd terraform/environments/management
terraform init
terraform validate
```

Expected: `Success! The configuration is valid.`

- [ ] **Step 6: Write docs/security/services.md**

```markdown
# Services de securite AWS

## SCPs (Service Control Policies)

Appliquees au niveau racine de l'Organisation, ces politiques s'appliquent a tous les comptes membres.

| SCP | Description | Justification |
|---|---|---|
| region-deny | Restreint toutes les operations a ca-central-1 | Residences des donnees au Canada |
| deny-root-usage | Bloque l'utilisation du root user sur les comptes membres | Securite - root ne devrait jamais etre utilise |
| protect-cloudtrail | Empeche la suppression/modification de CloudTrail | Integrite du journal d'audit |
| protect-config | Empeche la suppression/modification de Config | Conformite continue |
| protect-guardduty | Empeche la desactivation de GuardDuty | Detection de menaces toujours active |
| deny-s3-public-access | Empeche la creation de buckets S3 publics | Prevention de fuites de donnees |

## Services de detection (par compte)

| Service | Role | Configuration |
|---|---|---|
| GuardDuty | Detection de menaces en temps reel | Active sur tous les comptes |
| Inspector | Scan de vulnerabilites EC2 | Active sur Prod et Dev |
| SecurityHub | Dashboard centralise | Agrege findings de tous les services |
| CloudTrail | Journal d'audit API | Logs centralises vers LogArchive |
| Config | Conformite des ressources | 5 regles configurees |

### Config Rules

| Regle | Description |
|---|---|
| required-tags | Verifie la presence des tags obligatoires |
| ebs-encryption-by-default | Verifie le chiffrement EBS |
| s3-bucket-public-read-prohibited | Detecte les buckets publics |
| rds-storage-encrypted | Verifie le chiffrement RDS |
| restricted-ssh | Detecte les SGs avec SSH ouvert |
```

- [ ] **Step 7: Update docs/README.md**

Add under the Securite section:
```markdown
### Securite
- [Services de securite](security/services.md)
```

- [ ] **Step 8: Commit**

```bash
git add terraform/modules/organizations/ terraform/environments/management/main.tf docs/security/
git commit -m "feat: add Organizations SCPs module and security documentation"
```

---

## Phase 2: Dev Environment

### Task 5: VPC Module

**Files:**
- Create: `terraform/modules/vpc/main.tf`
- Create: `terraform/modules/vpc/variables.tf`
- Create: `terraform/modules/vpc/outputs.tf`
- Create: `docs/architecture/network.md`

- [ ] **Step 1: Create VPC module variables**

`terraform/modules/vpc/variables.tf`:
```hcl
variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name (development, production)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_nat_cidr" {
  description = "CIDR block for the public NAT subnet"
  type        = string
}

variable "private_app_cidrs" {
  description = "CIDR blocks for private app subnets (one per AZ)"
  type        = list(string)
}

variable "private_data_cidrs" {
  description = "CIDR blocks for private data subnets (one per AZ)"
  type        = list(string)
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "use_nat_gateway" {
  description = "Use NAT Gateway (true) or NAT instance (false)"
  type        = bool
  default     = true
}

variable "nat_instance_type" {
  description = "Instance type for NAT instance (when use_nat_gateway = false)"
  type        = string
  default     = "t4g.nano"
}

variable "logs_bucket_arn" {
  description = "S3 bucket ARN for VPC Flow Logs"
  type        = string
}
```

- [ ] **Step 2: Create VPC module main.tf**

`terraform/modules/vpc/main.tf`:
```hcl
locals {
  name_prefix = "${var.project}-${var.environment}"
}

# ============================================================
# VPC
# ============================================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}

# ============================================================
# Internet Gateway
# ============================================================

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-igw"
  }
}

# ============================================================
# Public Subnet (NAT only)
# ============================================================

resource "aws_subnet" "public_nat" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_nat_cidr
  availability_zone       = var.availability_zones[0]
  map_public_ip_on_launch = false

  tags = {
    Name = "${local.name_prefix}-public-nat-a"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-rt-public"
  }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public_nat" {
  subnet_id      = aws_subnet.public_nat.id
  route_table_id = aws_route_table.public.id
}

# ============================================================
# NAT Gateway (prod) or NAT Instance (dev)
# ============================================================

# NAT Gateway (when use_nat_gateway = true)
resource "aws_eip" "nat" {
  count  = var.use_nat_gateway ? 1 : 0
  domain = "vpc"

  tags = {
    Name = "${local.name_prefix}-nat-eip"
  }
}

resource "aws_nat_gateway" "main" {
  count         = var.use_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public_nat.id

  tags = {
    Name = "${local.name_prefix}-nat-gw"
  }

  depends_on = [aws_internet_gateway.main]
}

# NAT Instance (when use_nat_gateway = false)
data "aws_ami" "nat_instance" {
  count       = var.use_nat_gateway ? 0 : 1
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-vpc-nat-*-arm64-ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "nat_instance" {
  count  = var.use_nat_gateway ? 0 : 1
  name   = "${local.name_prefix}-sg-nat-instance"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "All traffic from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-sg-nat-instance"
  }
}

resource "aws_instance" "nat" {
  count                       = var.use_nat_gateway ? 0 : 1
  ami                         = data.aws_ami.nat_instance[0].id
  instance_type               = var.nat_instance_type
  subnet_id                   = aws_subnet.public_nat.id
  vpc_security_group_ids      = [aws_security_group.nat_instance[0].id]
  source_dest_check           = false
  associate_public_ip_address = true

  tags = {
    Name        = "${local.name_prefix}-nat-instance"
    Application = "shared"
  }
}

# ============================================================
# Private App Subnets
# ============================================================

resource "aws_subnet" "private_app" {
  count             = length(var.private_app_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_app_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${local.name_prefix}-private-app-${count.index == 0 ? "a" : "b"}"
  }
}

# ============================================================
# Private Data Subnets
# ============================================================

resource "aws_subnet" "private_data" {
  count             = length(var.private_data_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_data_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${local.name_prefix}-private-data-${count.index == 0 ? "a" : "b"}"
  }
}

# ============================================================
# Private Route Table
# ============================================================

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-rt-private"
  }
}

resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.use_nat_gateway ? aws_nat_gateway.main[0].id : null
  network_interface_id   = var.use_nat_gateway ? null : aws_instance.nat[0].primary_network_interface_id
}

resource "aws_route_table_association" "private_app" {
  count          = length(var.private_app_cidrs)
  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_data" {
  count          = length(var.private_data_cidrs)
  subnet_id      = aws_subnet.private_data[count.index].id
  route_table_id = aws_route_table.private.id
}

# ============================================================
# VPC Flow Logs
# ============================================================

resource "aws_flow_log" "vpc" {
  vpc_id               = aws_vpc.main.id
  traffic_type         = "ALL"
  log_destination      = var.logs_bucket_arn
  log_destination_type = "s3"
  max_aggregation_interval = 600

  tags = {
    Name = "${local.name_prefix}-flow-logs"
  }
}

# ============================================================
# S3 Gateway Endpoint (free)
# ============================================================

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.ca-central-1.s3"

  route_table_ids = [
    aws_route_table.private.id,
    aws_route_table.public.id,
  ]

  tags = {
    Name = "${local.name_prefix}-vpce-s3"
  }
}
```

- [ ] **Step 3: Create VPC module outputs**

`terraform/modules/vpc/outputs.tf`:
```hcl
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

output "public_nat_subnet_id" {
  description = "Public NAT subnet ID"
  value       = aws_subnet.public_nat.id
}

output "private_app_subnet_ids" {
  description = "Private app subnet IDs"
  value       = aws_subnet.private_app[*].id
}

output "private_data_subnet_ids" {
  description = "Private data subnet IDs"
  value       = aws_subnet.private_data[*].id
}

output "private_route_table_id" {
  description = "Private route table ID"
  value       = aws_route_table.private.id
}

output "s3_endpoint_id" {
  description = "S3 VPC endpoint ID"
  value       = aws_vpc_endpoint.s3.id
}

output "nat_instance_sg_id" {
  description = "NAT instance security group ID (null if using NAT Gateway)"
  value       = var.use_nat_gateway ? null : aws_security_group.nat_instance[0].id
}
```

- [ ] **Step 4: Validate the module**

```bash
cd terraform/modules/vpc
terraform init
terraform validate
```

Expected: `Success! The configuration is valid.`

- [ ] **Step 5: Write docs/architecture/network.md**

```markdown
# Architecture reseau

## VPC

Chaque environnement (Prod, Dev) dispose de son propre VPC isole.

| VPC | CIDR | Region |
|---|---|---|
| Prod | 10.0.0.0/16 | ca-central-1 |
| Dev | 10.1.0.0/16 | ca-central-1 |

Les VPCs ne sont pas peeres (isolation complete).

## Subnets

### Prod

| Subnet | Type | CIDR | AZ | Role |
|---|---|---|---|---|
| public-nat-a | Public | 10.0.100.0/24 | ca-central-1a | NAT Gateway |
| private-app-a | Prive | 10.0.1.0/24 | ca-central-1a | EC2 serveurs web |
| private-app-b | Prive | 10.0.2.0/24 | ca-central-1b | Redundance AZ |
| private-data-a | Prive | 10.0.10.0/24 | ca-central-1a | RDS |
| private-data-b | Prive | 10.0.11.0/24 | ca-central-1b | RDS (2e AZ) |

### Dev

| Subnet | Type | CIDR | AZ | Role |
|---|---|---|---|---|
| public-nat-a | Public | 10.1.100.0/24 | ca-central-1a | NAT instance |
| private-app-a | Prive | 10.1.1.0/24 | ca-central-1a | EC2 serveurs web |
| private-data-a | Prive | 10.1.10.0/24 | ca-central-1a | RDS |
| private-data-b | Prive | 10.1.11.0/24 | ca-central-1b | RDS (2e AZ) |

## Route Tables

**Publique (NAT subnet):** `0.0.0.0/0 -> Internet Gateway`

**Privee (app + data subnets):** `0.0.0.0/0 -> NAT Gateway/instance`, `S3 prefix -> VPC Endpoint`

## VPC Endpoints

| Endpoint | Type | Environnement |
|---|---|---|
| S3 | Gateway (gratuit) | Prod + Dev |
| SSM, SSMMessages, EC2Messages | Interface | Prod seulement |

## VPC Flow Logs

Actives sur chaque VPC, destination S3, trafic ALL.

## Network ACLs

Default (allow all). Securite enforcee au niveau des Security Groups.

## DNS

- `enableDnsSupport: true`
- `enableDnsHostnames: true`
```

- [ ] **Step 6: Update docs/README.md**

Add under Architecture:
```markdown
- [Architecture reseau](architecture/network.md)
```

- [ ] **Step 7: Commit**

```bash
git add terraform/modules/vpc/ docs/architecture/network.md docs/README.md
git commit -m "feat: add VPC module with NAT, subnets, flow logs, S3 endpoint"
```

---

### Task 6: S3 Module

**Files:**
- Create: `terraform/modules/s3/main.tf`
- Create: `terraform/modules/s3/variables.tf`
- Create: `terraform/modules/s3/outputs.tf`
- Create: `docs/infrastructure/storage.md`

- [ ] **Step 1: Create S3 module variables**

`terraform/modules/s3/variables.tf`:
```hcl
variable "bucket_name" {
  description = "S3 bucket name"
  type        = string
}

variable "enable_versioning" {
  description = "Enable versioning"
  type        = bool
  default     = true
}

variable "lifecycle_expiration_days" {
  description = "Days before objects expire (0 = no expiration)"
  type        = number
  default     = 0
}

variable "lifecycle_glacier_days" {
  description = "Days before transition to Glacier (0 = no transition)"
  type        = number
  default     = 0
}

variable "force_tls" {
  description = "Deny non-TLS requests via bucket policy"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
```

- [ ] **Step 2: Create S3 module main.tf**

`terraform/modules/s3/main.tf`:
```hcl
resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
  tags   = var.tags
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "force_tls" {
  count  = var.force_tls ? 1 : 0
  bucket = aws_s3_bucket.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.this.arn,
          "${aws_s3_bucket.this.arn}/*",
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count  = var.lifecycle_expiration_days > 0 || var.lifecycle_glacier_days > 0 ? 1 : 0
  bucket = aws_s3_bucket.this.id

  dynamic "rule" {
    for_each = var.lifecycle_expiration_days > 0 ? [1] : []
    content {
      id     = "expire-objects"
      status = "Enabled"

      expiration {
        days = var.lifecycle_expiration_days
      }
    }
  }

  dynamic "rule" {
    for_each = var.lifecycle_glacier_days > 0 ? [1] : []
    content {
      id     = "transition-glacier"
      status = "Enabled"

      transition {
        days          = var.lifecycle_glacier_days
        storage_class = "GLACIER"
      }
    }
  }
}
```

- [ ] **Step 3: Create S3 module outputs**

`terraform/modules/s3/outputs.tf`:
```hcl
output "bucket_id" {
  description = "Bucket name"
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "Bucket ARN"
  value       = aws_s3_bucket.this.arn
}

output "bucket_domain_name" {
  description = "Bucket domain name"
  value       = aws_s3_bucket.this.bucket_domain_name
}
```

- [ ] **Step 4: Validate**

```bash
cd terraform/modules/s3
terraform init
terraform validate
```

Expected: `Success! The configuration is valid.`

- [ ] **Step 5: Write docs/infrastructure/storage.md**

```markdown
# Stockage S3

## Buckets

### Existants (importes dans Terraform)

| Bucket | Usage | Modifications |
|---|---|---|
| aromaestro-backups | Backups manuels | Object Lock, versioning, Glacier apres 30j |
| aromaestro-diffuser-ota | OTA firmware diffuseurs (IoT) | Aucune |
| aromaestro-ota | OTA firmware | Aucune |

### Nouveaux

| Bucket | Env | Usage |
|---|---|---|
| aromaestro-prod-assets | Prod | Fichiers statiques apps web |
| aromaestro-prod-logs | Prod | CloudTrail, VPC Flow Logs |
| aromaestro-dev-assets | Dev | Fichiers statiques |
| aromaestro-dev-logs | Dev | Logs |
| aromaestro-logarchive | LogArchive | CloudTrail centralise |

## Securite

- **Block Public Access** sur tous les buckets
- **TLS enforce** via bucket policy (deny aws:SecureTransport = false)
- **SSE-S3** chiffrement au repos
- **Versioning** active sur tous les buckets (sauf logs)

## Lifecycle

| Bucket | Regle |
|---|---|
| *-logs | Suppression apres 90 jours |
| aromaestro-backups | Transition Glacier apres 30 jours |
```

- [ ] **Step 6: Update docs/README.md**

Add under Infrastructure:
```markdown
### Infrastructure
- [Stockage S3](infrastructure/storage.md)
```

- [ ] **Step 7: Commit**

```bash
git add terraform/modules/s3/ docs/infrastructure/storage.md docs/README.md
git commit -m "feat: add S3 module with encryption, TLS enforcement, lifecycle"
```

---

### Task 7: EC2 Module (Security Groups + Instances)

**Files:**
- Create: `terraform/modules/ec2/main.tf`
- Create: `terraform/modules/ec2/variables.tf`
- Create: `terraform/modules/ec2/outputs.tf`
- Create: `terraform/modules/ec2/user_data.sh.tpl`
- Create: `docs/infrastructure/compute.md`

- [ ] **Step 1: Create EC2 module variables**

`terraform/modules/ec2/variables.tf`:
```hcl
variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR for DNS security group rule"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for instances"
  type        = string
}

variable "rds_security_group_id" {
  description = "RDS security group ID for outbound MySQL rule"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t4g.small"
}

variable "instances" {
  description = "Map of instance names to their application tag"
  type        = map(string)
  # Example: { "web-site" = "site", "web-admin" = "admin" }
}

variable "tailscale_auth_key_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the Tailscale auth key"
  type        = string
}

variable "cloudwatch_agent_config_ssm_param" {
  description = "SSM Parameter name for CloudWatch Agent config"
  type        = string
}
```

- [ ] **Step 2: Create user_data template**

`terraform/modules/ec2/user_data.sh.tpl`:
```bash
#!/bin/bash
set -euo pipefail

# Update system
apt-get update -y
apt-get upgrade -y

# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Get Tailscale auth key from Secrets Manager
TAILSCALE_AUTH_KEY=$(aws secretsmanager get-secret-value \
  --secret-id "${tailscale_secret_arn}" \
  --query SecretString \
  --output text \
  --region "${aws_region}")

# Start Tailscale
tailscale up --authkey="$TAILSCALE_AUTH_KEY" --hostname="${hostname}"

# Install and configure CloudWatch Agent
wget -q https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/arm64/latest/amazon-cloudwatch-agent.deb
dpkg -i amazon-cloudwatch-agent.deb
rm amazon-cloudwatch-agent.deb

# Fetch config from SSM and start agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c "ssm:${cw_agent_config_param}"
```

- [ ] **Step 3: Create EC2 module main.tf**

`terraform/modules/ec2/main.tf`:
```hcl
locals {
  name_prefix = "${var.project}-${var.environment}"
}

# ============================================================
# AMI - Ubuntu 24.04 ARM
# ============================================================

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-arm64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }
}

# ============================================================
# IAM Role for EC2 (SSM + Secrets Manager + CloudWatch)
# ============================================================

resource "aws_iam_role" "ec2" {
  name = "${local.name_prefix}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy" "secrets" {
  name = "${local.name_prefix}-secrets-access"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "secretsmanager:GetSecretValue"
        Resource = var.tailscale_auth_key_secret_arn
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${local.name_prefix}-ec2-profile"
  role = aws_iam_role.ec2.name
}

# ============================================================
# Security Group - Web App
# ============================================================

resource "aws_security_group" "web_app" {
  name   = "${local.name_prefix}-sg-web-app"
  vpc_id = var.vpc_id

  tags = {
    Name = "${local.name_prefix}-sg-web-app"
  }
}

# Outbound: HTTPS (APIs AWS, updates, Tailscale DERP)
resource "aws_vpc_security_group_egress_rule" "https" {
  security_group_id = aws_security_group.web_app.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "HTTPS - AWS APIs, updates, Tailscale DERP"
}

# Outbound: HTTP (package managers)
resource "aws_vpc_security_group_egress_rule" "http" {
  security_group_id = aws_security_group.web_app.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  description       = "HTTP - apt package manager"
}

# Outbound: Tailscale WireGuard direct
resource "aws_vpc_security_group_egress_rule" "tailscale" {
  security_group_id = aws_security_group.web_app.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 41641
  to_port           = 41641
  ip_protocol       = "udp"
  description       = "Tailscale WireGuard direct connections"
}

# Outbound: MySQL to RDS
resource "aws_vpc_security_group_egress_rule" "mysql" {
  security_group_id            = aws_security_group.web_app.id
  referenced_security_group_id = var.rds_security_group_id
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
  description                  = "MySQL to RDS"
}

# Outbound: DNS (UDP)
resource "aws_vpc_security_group_egress_rule" "dns_udp" {
  security_group_id = aws_security_group.web_app.id
  cidr_ipv4         = var.vpc_cidr
  from_port         = 53
  to_port           = 53
  ip_protocol       = "udp"
  description       = "DNS resolution"
}

# Outbound: DNS (TCP)
resource "aws_vpc_security_group_egress_rule" "dns_tcp" {
  security_group_id = aws_security_group.web_app.id
  cidr_ipv4         = var.vpc_cidr
  from_port         = 53
  to_port           = 53
  ip_protocol       = "tcp"
  description       = "DNS resolution (TCP)"
}

# ============================================================
# EC2 Instances
# ============================================================

resource "aws_instance" "web" {
  for_each = var.instances

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.web_app.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2.name

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh.tpl", {
    tailscale_secret_arn = var.tailscale_auth_key_secret_arn
    hostname             = "${each.key}-${var.environment}"
    aws_region           = "ca-central-1"
    cw_agent_config_param = var.cloudwatch_agent_config_ssm_param
  }))

  tags = {
    Name        = "${local.name_prefix}-${each.key}"
    Application = each.value
  }

  lifecycle {
    ignore_changes = [ami, user_data]
  }
}
```

- [ ] **Step 4: Create EC2 module outputs**

`terraform/modules/ec2/outputs.tf`:
```hcl
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
```

- [ ] **Step 5: Validate**

```bash
cd terraform/modules/ec2
terraform init
terraform validate
```

Expected: `Success! The configuration is valid.`

- [ ] **Step 6: Write docs/infrastructure/compute.md**

```markdown
# Compute (EC2)

## Instances

### Prod

| Nom | Role | Type | OS |
|---|---|---|---|
| web-site | Site internet | t4g.small | Ubuntu 24.04 ARM |
| web-admin | Admin Laravel | t4g.small | Ubuntu 24.04 ARM |
| web-wordpress | WordPress | t4g.small | Ubuntu 24.04 ARM |
| web-openclaw | Open Claw | t4g.small | Ubuntu 24.04 ARM |

### Dev

Meme structure en t4g.micro.

## Configuration

- **Tailscale** : installe au boot via user_data, auth key dans Secrets Manager
- **CloudWatch Agent** : installe au boot, config via SSM Parameter Store
- **SSM Agent** : pre-installe sur Ubuntu, IAM role attache
- **Aucune IP publique**
- **EBS chiffre** : gp3 20GB par defaut

## Security Groups

### sg-web-app

| Direction | Port | Protocole | Destination | Usage |
|---|---|---|---|---|
| Outbound | 443 | TCP | 0.0.0.0/0 | HTTPS (AWS APIs, updates, Tailscale DERP) |
| Outbound | 80 | TCP | 0.0.0.0/0 | HTTP (apt) |
| Outbound | 41641 | UDP | 0.0.0.0/0 | Tailscale WireGuard direct |
| Outbound | 3306 | TCP | sg-rds | MySQL |
| Outbound | 53 | UDP/TCP | VPC CIDR | DNS |
| Inbound | - | - | - | **Aucun port ouvert** |

## IAM Role

Les instances utilisent un role IAM avec :
- `AmazonSSMManagedInstanceCore` (SSM Session Manager)
- `CloudWatchAgentServerPolicy` (metriques et logs)
- Acces au secret Tailscale dans Secrets Manager
```

- [ ] **Step 7: Update docs/README.md**

Add under Infrastructure:
```markdown
- [Compute EC2](infrastructure/compute.md)
```

- [ ] **Step 8: Commit**

```bash
git add terraform/modules/ec2/ docs/infrastructure/compute.md docs/README.md
git commit -m "feat: add EC2 module with Tailscale, CloudWatch Agent, zero-inbound SGs"
```

---

### Task 8: RDS Module

**Files:**
- Create: `terraform/modules/rds/main.tf`
- Create: `terraform/modules/rds/variables.tf`
- Create: `terraform/modules/rds/outputs.tf`
- Create: `docs/infrastructure/database.md`

- [ ] **Step 1: Create RDS module variables**

`terraform/modules/rds/variables.tf`:
```hcl
variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for DB subnet group"
  type        = list(string)
}

variable "allowed_security_group_id" {
  description = "Security group ID allowed to connect to RDS"
  type        = string
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.small"
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Max storage for auto-scaling in GB"
  type        = number
  default     = 100
}

variable "backup_retention_period" {
  description = "Backup retention in days"
  type        = number
  default     = 7
}

variable "multi_az" {
  description = "Enable Multi-AZ"
  type        = bool
  default     = false
}
```

- [ ] **Step 2: Create RDS module main.tf**

`terraform/modules/rds/main.tf`:
```hcl
locals {
  name_prefix = "${var.project}-${var.environment}"
}

# ============================================================
# Security Group
# ============================================================

resource "aws_security_group" "rds" {
  name   = "${local.name_prefix}-sg-rds"
  vpc_id = var.vpc_id

  tags = {
    Name = "${local.name_prefix}-sg-rds"
  }
}

resource "aws_vpc_security_group_ingress_rule" "mysql" {
  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = var.allowed_security_group_id
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
  description                  = "MySQL from web app instances"
}

# ============================================================
# DB Subnet Group
# ============================================================

resource "aws_db_subnet_group" "main" {
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${local.name_prefix}-db-subnet-group"
  }
}

# ============================================================
# Parameter Group (require TLS)
# ============================================================

resource "aws_db_parameter_group" "main" {
  name   = "${local.name_prefix}-mysql-params"
  family = "mysql8.0"

  parameter {
    name  = "require_secure_transport"
    value = "1"
  }

  tags = {
    Name = "${local.name_prefix}-mysql-params"
  }
}

# ============================================================
# RDS Instance
# ============================================================

resource "aws_db_instance" "main" {
  identifier = "${local.name_prefix}-mysql"

  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.main.name

  multi_az            = var.multi_az
  publicly_accessible = false

  backup_retention_period = var.backup_retention_period
  backup_window           = "06:00-07:00" # 2 AM EST
  maintenance_window      = "sun:07:00-sun:08:00" # Sunday 3 AM EST

  skip_final_snapshot       = var.environment == "development"
  final_snapshot_identifier = var.environment == "development" ? null : "${local.name_prefix}-final-snapshot"

  tags = {
    Name        = "${local.name_prefix}-mysql"
    Application = "shared"
  }
}
```

- [ ] **Step 3: Create RDS module outputs**

`terraform/modules/rds/outputs.tf`:
```hcl
output "endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.main.endpoint
}

output "address" {
  description = "RDS hostname"
  value       = aws_db_instance.main.address
}

output "port" {
  description = "RDS port"
  value       = aws_db_instance.main.port
}

output "security_group_id" {
  description = "RDS security group ID"
  value       = aws_security_group.rds.id
}

output "db_instance_id" {
  description = "RDS instance ID"
  value       = aws_db_instance.main.id
}
```

- [ ] **Step 4: Validate**

```bash
cd terraform/modules/rds
terraform init
terraform validate
```

Expected: `Success! The configuration is valid.`

- [ ] **Step 5: Write docs/infrastructure/database.md**

```markdown
# Base de donnees (RDS)

## Configuration

| Parametre | Prod | Dev |
|---|---|---|
| Moteur | MySQL 8.0 | MySQL 8.0 |
| Instance | db.t4g.small | db.t4g.micro |
| Stockage | 20 GB gp3, auto-scaling 100 GB | 20 GB gp3, auto-scaling 100 GB |
| Multi-AZ | Non (upgrade possible) | Non |
| Backup | 7 jours | 1 jour |
| Chiffrement | KMS | KMS |
| TLS | require_secure_transport = ON | require_secure_transport = ON |
| Acces public | Non | Non |

## Databases

Une seule instance RDS par environnement, 4 bases separees :

| Database | Application |
|---|---|
| db_site | Site internet |
| db_admin | Admin Laravel |
| db_wordpress | WordPress |
| db_openclaw | Open Claw |

## Acces

- Seulement depuis les instances EC2 (sg-web-app -> sg-rds sur port 3306)
- Via Tailscale : se connecter a une instance EC2 puis `mysql -h <endpoint-rds> -u <user> -p`
- Aucune IP publique, aucun acces direct depuis internet

## Backup

- Backup automatique AWS (fenetre 2h-3h AM EST)
- Maintenance automatique dimanche 3h-4h AM EST
- Snapshot final en prod avant suppression
```

- [ ] **Step 6: Update docs/README.md**

Add under Infrastructure:
```markdown
- [Base de donnees RDS](infrastructure/database.md)
```

- [ ] **Step 7: Commit**

```bash
git add terraform/modules/rds/ docs/infrastructure/database.md docs/README.md
git commit -m "feat: add RDS module with MySQL 8.0, TLS enforcement, auto-scaling"
```

---

### Task 9: Security Services Module

**Files:**
- Create: `terraform/modules/security/main.tf`
- Create: `terraform/modules/security/variables.tf`
- Create: `terraform/modules/security/outputs.tf`

- [ ] **Step 1: Create security module variables**

`terraform/modules/security/variables.tf`:
```hcl
variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "logs_bucket_name" {
  description = "S3 bucket name for CloudTrail logs"
  type        = string
}

variable "logs_bucket_arn" {
  description = "S3 bucket ARN for CloudTrail logs"
  type        = string
}
```

- [ ] **Step 2: Create security module main.tf**

`terraform/modules/security/main.tf`:
```hcl
locals {
  name_prefix = "${var.project}-${var.environment}"
}

data "aws_caller_identity" "current" {}

# ============================================================
# GuardDuty
# ============================================================

resource "aws_guardduty_detector" "main" {
  enable = true

  tags = {
    Name = "${local.name_prefix}-guardduty"
  }
}

# ============================================================
# Inspector
# ============================================================

resource "aws_inspector2_enabler" "main" {
  account_ids    = [data.aws_caller_identity.current.account_id]
  resource_types = ["EC2"]
}

# ============================================================
# Security Hub
# ============================================================

resource "aws_securityhub_account" "main" {}

resource "aws_securityhub_standards_subscription" "aws_foundational" {
  standards_arn = "arn:aws:securityhub:ca-central-1::standards/aws-foundational-security-best-practices/v/1.0.0"
  depends_on    = [aws_securityhub_account.main]
}

# ============================================================
# CloudTrail
# ============================================================

resource "aws_cloudtrail" "main" {
  name                       = "${local.name_prefix}-trail"
  s3_bucket_name             = var.logs_bucket_name
  include_global_service_events = true
  is_multi_region_trail      = false
  enable_log_file_validation = true

  tags = {
    Name = "${local.name_prefix}-trail"
  }
}

# ============================================================
# Config
# ============================================================

resource "aws_config_configuration_recorder" "main" {
  name     = "${local.name_prefix}-config-recorder"
  role_arn = aws_iam_role.config.arn

  recording_group {
    all_supported = true
  }
}

resource "aws_config_delivery_channel" "main" {
  name           = "${local.name_prefix}-config-delivery"
  s3_bucket_name = var.logs_bucket_name

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_configuration_recorder_status" "main" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.main]
}

resource "aws_iam_role" "config" {
  name = "${local.name_prefix}-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "config" {
  role       = aws_iam_role.config.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

resource "aws_iam_role_policy" "config_s3" {
  name = "${local.name_prefix}-config-s3"
  role = aws_iam_role.config.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetBucketAcl",
        ]
        Resource = [
          var.logs_bucket_arn,
          "${var.logs_bucket_arn}/*",
        ]
      }
    ]
  })
}

# ============================================================
# Config Rules
# ============================================================

resource "aws_config_config_rule" "ebs_encryption" {
  name = "ebs-encryption-by-default"

  source {
    owner             = "AWS"
    source_identifier = "EC2_EBS_ENCRYPTION_BY_DEFAULT"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "s3_public_read" {
  name = "s3-bucket-public-read-prohibited"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "rds_encrypted" {
  name = "rds-storage-encrypted"

  source {
    owner             = "AWS"
    source_identifier = "RDS_STORAGE_ENCRYPTED"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "restricted_ssh" {
  name = "restricted-ssh"

  source {
    owner             = "AWS"
    source_identifier = "INCOMING_SSH_DISABLED"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

# ============================================================
# EBS Encryption by Default
# ============================================================

resource "aws_ebs_encryption_by_default" "main" {
  enabled = true
}
```

- [ ] **Step 3: Create security module outputs**

`terraform/modules/security/outputs.tf`:
```hcl
output "guardduty_detector_id" {
  value = aws_guardduty_detector.main.id
}

output "cloudtrail_arn" {
  value = aws_cloudtrail.main.arn
}

output "config_recorder_id" {
  value = aws_config_configuration_recorder.main.id
}
```

- [ ] **Step 4: Validate**

```bash
cd terraform/modules/security
terraform init
terraform validate
```

- [ ] **Step 5: Update docs/security/services.md with config details**

Append to the existing file:
```markdown

## EBS Encryption

Chiffrement active par defaut au niveau du compte. Toute nouvelle instance EC2 aura ses volumes EBS automatiquement chiffres.

## CloudTrail

- Trail active sur chaque compte
- Validation des fichiers de log activee
- Logs envoyes vers le bucket du compte (et centralises vers LogArchive)
```

- [ ] **Step 6: Commit**

```bash
git add terraform/modules/security/ docs/security/
git commit -m "feat: add security module (GuardDuty, Inspector, SecurityHub, CloudTrail, Config)"
```

---

### Task 10: Monitoring Module

**Files:**
- Create: `terraform/modules/monitoring/main.tf`
- Create: `terraform/modules/monitoring/variables.tf`
- Create: `terraform/modules/monitoring/outputs.tf`
- Create: `docs/operations/monitoring.md`

- [ ] **Step 1: Create monitoring module variables**

`terraform/modules/monitoring/variables.tf`:
```hcl
variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "alert_email" {
  description = "Email address for alerts"
  type        = string
}

variable "ec2_instance_ids" {
  description = "Map of instance name to instance ID"
  type        = map(string)
}

variable "rds_instance_id" {
  description = "RDS instance identifier"
  type        = string
}

variable "nat_instance_id" {
  description = "NAT instance ID (null if using NAT Gateway)"
  type        = string
  default     = null
}
```

- [ ] **Step 2: Create monitoring module main.tf**

`terraform/modules/monitoring/main.tf`:
```hcl
locals {
  name_prefix = "${var.project}-${var.environment}"
}

# ============================================================
# SNS Topic
# ============================================================

resource "aws_sns_topic" "alerts" {
  name = "${local.name_prefix}-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ============================================================
# EC2 Alarms
# ============================================================

resource "aws_cloudwatch_metric_alarm" "ec2_cpu" {
  for_each = var.ec2_instance_ids

  alarm_name          = "${local.name_prefix}-${each.key}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "CPU > 80% on ${each.key}"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = each.value
  }
}

resource "aws_cloudwatch_metric_alarm" "ec2_status_check" {
  for_each = var.ec2_instance_ids

  alarm_name          = "${local.name_prefix}-${each.key}-status-check"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed_System"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 1
  alarm_description   = "System status check failed on ${each.key}"
  alarm_actions       = [
    aws_sns_topic.alerts.arn,
    "arn:aws:automate:ca-central-1:ec2:recover",
  ]

  dimensions = {
    InstanceId = each.value
  }
}

resource "aws_cloudwatch_metric_alarm" "ec2_memory" {
  for_each = var.ec2_instance_ids

  alarm_name          = "${local.name_prefix}-${each.key}-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = 300
  statistic           = "Average"
  threshold           = 85
  alarm_description   = "Memory > 85% on ${each.key}"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = each.value
  }
}

resource "aws_cloudwatch_metric_alarm" "ec2_disk" {
  for_each = var.ec2_instance_ids

  alarm_name          = "${local.name_prefix}-${each.key}-disk-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "disk_used_percent"
  namespace           = "CWAgent"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Disk > 80% on ${each.key}"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = each.value
    path       = "/"
  }
}

# ============================================================
# RDS Alarms
# ============================================================

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${local.name_prefix}-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "RDS CPU > 80%"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  alarm_name          = "${local.name_prefix}-rds-connections-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 50 # ~80% of db.t4g.small max (66)
  alarm_description   = "RDS connections > 80% of max"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  alarm_name          = "${local.name_prefix}-rds-storage-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 4294967296 # 4 GB in bytes
  alarm_description   = "RDS free storage < 4 GB"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_memory" {
  alarm_name          = "${local.name_prefix}-rds-memory-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 134217728 # 128 MB in bytes
  alarm_description   = "RDS freeable memory < 128 MB"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_read_latency" {
  alarm_name          = "${local.name_prefix}-rds-read-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ReadLatency"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 0.02 # 20ms in seconds
  alarm_description   = "RDS read latency > 20ms"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_write_latency" {
  alarm_name          = "${local.name_prefix}-rds-write-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "WriteLatency"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 0.02 # 20ms in seconds
  alarm_description   = "RDS write latency > 20ms"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }
}

# ============================================================
# NAT Instance Alarm (dev only)
# ============================================================

resource "aws_cloudwatch_metric_alarm" "nat_status_check" {
  count = var.nat_instance_id != null ? 1 : 0

  alarm_name          = "${local.name_prefix}-nat-status-check"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed_System"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 1
  alarm_description   = "NAT instance system status check failed"
  alarm_actions       = [
    aws_sns_topic.alerts.arn,
    "arn:aws:automate:ca-central-1:ec2:recover",
  ]

  dimensions = {
    InstanceId = var.nat_instance_id
  }
}

# ============================================================
# EventBridge Rules
# ============================================================

resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  name        = "${local.name_prefix}-guardduty-findings"
  description = "Route GuardDuty HIGH/CRITICAL findings to SNS"

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
    detail = {
      severity = [{ numeric = [">=", 7] }]
    }
  })
}

resource "aws_cloudwatch_event_target" "guardduty_sns" {
  rule      = aws_cloudwatch_event_rule.guardduty_findings.name
  target_id = "guardduty-to-sns"
  arn       = aws_sns_topic.alerts.arn
}

resource "aws_cloudwatch_event_rule" "inspector_findings" {
  name        = "${local.name_prefix}-inspector-findings"
  description = "Route Inspector HIGH/CRITICAL findings to SNS"

  event_pattern = jsonencode({
    source      = ["aws.inspector2"]
    detail-type = ["Inspector2 Finding"]
    detail = {
      severity = ["HIGH", "CRITICAL"]
    }
  })
}

resource "aws_cloudwatch_event_target" "inspector_sns" {
  rule      = aws_cloudwatch_event_rule.inspector_findings.name
  target_id = "inspector-to-sns"
  arn       = aws_sns_topic.alerts.arn
}

resource "aws_sns_topic_policy" "allow_eventbridge" {
  arn = aws_sns_topic.alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEventBridgePublish"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.alerts.arn
      }
    ]
  })
}
```

- [ ] **Step 3: Create monitoring module outputs**

`terraform/modules/monitoring/outputs.tf`:
```hcl
output "sns_topic_arn" {
  value = aws_sns_topic.alerts.arn
}
```

- [ ] **Step 4: Validate**

```bash
cd terraform/modules/monitoring
terraform init
terraform validate
```

- [ ] **Step 5: Write docs/operations/monitoring.md**

```markdown
# Monitoring et Alertes

## CloudWatch Alarmes

### EC2 (par instance)

| Metrique | Seuil | Evaluation | Action |
|---|---|---|---|
| CPUUtilization | > 80% | 3x 5min | SNS alert |
| StatusCheckFailed_System | >= 1 | 2x 1min | SNS alert + auto-recovery |
| mem_used_percent | > 85% | 2x 5min | SNS alert |
| disk_used_percent | > 80% | 2x 5min | SNS alert |

### RDS

| Metrique | Seuil | Evaluation |
|---|---|---|
| CPUUtilization | > 80% | 3x 5min |
| DatabaseConnections | > 80% max | 2x 5min |
| FreeStorageSpace | < 4 GB | 1x 5min |
| FreeableMemory | < 128 MB | 2x 5min |
| ReadLatency | > 20ms | 2x 5min |
| WriteLatency | > 20ms | 2x 5min |

### NAT Instance (dev)

| Metrique | Seuil | Action |
|---|---|---|
| StatusCheckFailed_System | >= 1 | Auto-recovery |

## EventBridge

| Regle | Source | Filtre | Destination |
|---|---|---|---|
| guardduty-findings | GuardDuty | Severity >= 7 (HIGH/CRITICAL) | SNS |
| inspector-findings | Inspector | HIGH/CRITICAL | SNS |

## Notifications

- Topic SNS : `aromaestro-{env}-alerts`
- Protocole : email
- Inclut : alarmes CloudWatch + findings GuardDuty/Inspector

## CloudWatch Agent

Installe sur chaque EC2, collecte :
- `mem_used_percent` (namespace CWAgent)
- `disk_used_percent` (namespace CWAgent, path `/`)
```

- [ ] **Step 6: Update docs/README.md**

Add under Operations:
```markdown
### Operations
- [Monitoring et alertes](operations/monitoring.md)
```

- [ ] **Step 7: Commit**

```bash
git add terraform/modules/monitoring/ docs/operations/monitoring.md docs/README.md
git commit -m "feat: add monitoring module (CloudWatch alarms, EventBridge, SNS)"
```

---

### Task 11: Backup and Patching Modules

**Files:**
- Create: `terraform/modules/backup/main.tf`
- Create: `terraform/modules/backup/variables.tf`
- Create: `terraform/modules/backup/outputs.tf`
- Create: `terraform/modules/patching/main.tf`
- Create: `terraform/modules/patching/variables.tf`
- Create: `docs/operations/backup.md`
- Create: `docs/operations/patching.md`

- [ ] **Step 1: Create backup module variables**

`terraform/modules/backup/variables.tf`:
```hcl
variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "is_production" {
  description = "Whether this is production (enables weekly/monthly backups)"
  type        = bool
  default     = false
}
```

- [ ] **Step 2: Create backup module main.tf**

`terraform/modules/backup/main.tf`:
```hcl
locals {
  name_prefix = "${var.project}-${var.environment}"
}

resource "aws_backup_vault" "main" {
  name = "${local.name_prefix}-backup-vault"
}

# ============================================================
# Daily Backup Plan
# ============================================================

resource "aws_backup_plan" "daily" {
  name = "${local.name_prefix}-daily"

  rule {
    rule_name         = "daily-backup"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 7 * * ? *)" # 2 AM EST = 7 AM UTC

    lifecycle {
      delete_after = var.is_production ? 7 : 3
    }
  }

  dynamic "rule" {
    for_each = var.is_production ? [1] : []
    content {
      rule_name         = "weekly-backup"
      target_vault_name = aws_backup_vault.main.name
      schedule          = "cron(0 7 ? * 1 *)" # Sunday 2 AM EST

      lifecycle {
        delete_after = 28
      }
    }
  }

  dynamic "rule" {
    for_each = var.is_production ? [1] : []
    content {
      rule_name         = "monthly-backup"
      target_vault_name = aws_backup_vault.main.name
      schedule          = "cron(0 7 1 * ? *)" # 1st of month 2 AM EST

      lifecycle {
        cold_storage_after = 30
        delete_after       = 365
      }
    }
  }
}

# ============================================================
# Backup Selection (tag-based)
# ============================================================

resource "aws_iam_role" "backup" {
  name = "${local.name_prefix}-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "restore" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

resource "aws_backup_selection" "tagged_resources" {
  name         = "${local.name_prefix}-tagged-resources"
  iam_role_arn = aws_iam_role.backup.arn
  plan_id      = aws_backup_plan.daily.id

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "Environment"
    value = var.environment == "development" ? "development" : "production"
  }
}
```

- [ ] **Step 3: Create backup outputs**

`terraform/modules/backup/outputs.tf`:
```hcl
output "vault_arn" {
  value = aws_backup_vault.main.arn
}

output "plan_id" {
  value = aws_backup_plan.daily.id
}
```

- [ ] **Step 4: Create patching module**

`terraform/modules/patching/variables.tf`:
```hcl
variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}
```

`terraform/modules/patching/main.tf`:
```hcl
locals {
  name_prefix = "${var.project}-${var.environment}"
}

resource "aws_ssm_patch_baseline" "ubuntu" {
  name             = "${local.name_prefix}-ubuntu-baseline"
  operating_system = "UBUNTU"

  approval_rule {
    approve_after_days = 7
    compliance_level   = "HIGH"

    patch_filter {
      key    = "PRIORITY"
      values = ["Required", "Important"]
    }
  }
}

resource "aws_ssm_maintenance_window" "patching" {
  name              = "${local.name_prefix}-patching-window"
  schedule          = "cron(0 8 ? * 1 *)" # Sunday 3 AM EST = 8 AM UTC
  duration          = 3
  cutoff            = 1
  allow_unassociated_targets = false
}

resource "aws_ssm_maintenance_window_target" "tagged" {
  window_id     = aws_ssm_maintenance_window.patching.id
  name          = "tagged-instances"
  resource_type = "INSTANCE"

  targets {
    key    = "tag:Environment"
    values = [var.environment == "development" ? "development" : "production"]
  }
}

resource "aws_ssm_maintenance_window_task" "patch" {
  window_id        = aws_ssm_maintenance_window.patching.id
  task_type        = "RUN_COMMAND"
  task_arn         = "AWS-RunPatchBaseline"
  priority         = 1
  max_concurrency  = "50%"
  max_errors       = "0"

  targets {
    key    = "WindowTargetIds"
    values = [aws_ssm_maintenance_window_target.tagged.id]
  }

  task_invocation_parameters {
    run_command_parameters {
      parameter {
        name   = "Operation"
        values = ["Install"]
      }
      parameter {
        name   = "RebootOption"
        values = ["RebootIfNeeded"]
      }
    }
  }
}
```

- [ ] **Step 5: Validate both modules**

```bash
cd terraform/modules/backup && terraform init && terraform validate
cd ../patching && terraform init && terraform validate
```

- [ ] **Step 6: Write docs/operations/backup.md**

```markdown
# Backups (AWS Backup)

## Politique de retention

### Prod

| Frequence | Heure | Retention | Stockage |
|---|---|---|---|
| Quotidien | 2h AM EST | 7 jours | Standard |
| Hebdomadaire | Dimanche 2h AM | 4 semaines | Standard |
| Mensuel | 1er du mois 2h AM | 12 mois | Cold storage apres 30j |

### Dev

| Frequence | Heure | Retention |
|---|---|---|
| Quotidien | 2h AM EST | 3 jours |

## Selection des ressources

Basee sur les tags : toutes les ressources avec `Environment: production` ou `Environment: development`.

## RTO / RPO

| Metrique | Cible |
|---|---|
| RPO | 24 heures (backup quotidien) |
| RTO | 1 heure |

## Procedure de restauration

Voir [runbooks/restore-ec2.md](../runbooks/restore-ec2.md) et [runbooks/restore-rds.md](../runbooks/restore-rds.md).
```

- [ ] **Step 7: Write docs/operations/patching.md**

```markdown
# Patching (SSM Patch Manager)

## Configuration

- **Baseline** : Ubuntu, priorite Required + Important, approbation apres 7 jours
- **Fenetre de maintenance** : dimanche 3h00 AM EST (8h00 UTC)
- **Duree** : 3 heures
- **Operation** : Install avec reboot si necessaire
- **Concurrence** : 50% des instances a la fois

## Selection

Basee sur le tag `Environment` (production ou development).

## Processus

1. SSM scanne les instances quotidiennement
2. Dimanche 3h AM : installation automatique des patches approuves
3. Reboot si necessaire
4. Instances non-conformes signalees dans Security Hub
```

- [ ] **Step 8: Update docs/README.md**

Add:
```markdown
- [Backups](operations/backup.md)
- [Patching](operations/patching.md)
```

- [ ] **Step 9: Commit**

```bash
git add terraform/modules/backup/ terraform/modules/patching/ docs/operations/
git commit -m "feat: add backup and patching modules"
```

---

### Task 12: Budgets Module

**Files:**
- Create: `terraform/modules/budgets/main.tf`
- Create: `terraform/modules/budgets/variables.tf`

- [ ] **Step 1: Create budgets module**

`terraform/modules/budgets/variables.tf`:
```hcl
variable "project" {
  description = "Project name"
  type        = string
}

variable "budget_limit" {
  description = "Monthly budget limit in USD"
  type        = string
  default     = "350"
}

variable "alert_email" {
  description = "Email for budget alerts"
  type        = string
}
```

`terraform/modules/budgets/main.tf`:
```hcl
resource "aws_budgets_budget" "monthly" {
  name         = "${var.project}-monthly-budget"
  budget_type  = "COST"
  limit_amount = var.budget_limit
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }
}

resource "aws_ce_anomaly_monitor" "main" {
  name              = "${var.project}-cost-anomaly-monitor"
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"
}

resource "aws_ce_anomaly_subscription" "main" {
  name = "${var.project}-cost-anomaly-alerts"

  monitor_arn_list = [aws_ce_anomaly_monitor.main.arn]

  subscriber {
    type    = "EMAIL"
    address = var.alert_email
  }

  frequency = "DAILY"

  threshold_expression {
    dimension {
      key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
      match_options = ["GREATER_THAN_OR_EQUAL"]
      values        = ["20"]
    }
  }
}
```

- [ ] **Step 2: Validate**

```bash
cd terraform/modules/budgets
terraform init
terraform validate
```

- [ ] **Step 3: Commit**

```bash
git add terraform/modules/budgets/
git commit -m "feat: add budgets module with monthly alerts and anomaly detection"
```

---

### Task 13: Wire Up Dev Environment

This is the task that actually connects all modules and deploys the dev environment.

**Files:**
- Create: `terraform/environments/dev/main.tf`
- Create: `terraform/environments/dev/outputs.tf`
- Create: `terraform/environments/dev/terraform.tfvars.example`

- [ ] **Step 1: Create the dev environment main.tf**

`terraform/environments/dev/main.tf`:
```hcl
# ============================================================
# S3 Buckets (must be created first for VPC Flow Logs)
# ============================================================

module "logs_bucket" {
  source = "../../modules/s3"

  bucket_name              = "aromaestro-dev-logs"
  enable_versioning        = false
  lifecycle_expiration_days = 90
  force_tls                = true

  tags = { Application = "shared" }
}

module "assets_bucket" {
  source = "../../modules/s3"

  bucket_name       = "aromaestro-dev-assets"
  enable_versioning = true
  force_tls         = true

  tags = { Application = "shared" }
}

# ============================================================
# VPC
# ============================================================

module "vpc" {
  source = "../../modules/vpc"

  project     = var.project
  environment = var.environment

  vpc_cidr       = "10.1.0.0/16"
  public_nat_cidr = "10.1.100.0/24"
  private_app_cidrs  = ["10.1.1.0/24"]
  private_data_cidrs = ["10.1.10.0/24", "10.1.11.0/24"]
  availability_zones = ["ca-central-1a", "ca-central-1b"]

  use_nat_gateway   = false
  nat_instance_type = "t4g.nano"

  logs_bucket_arn = module.logs_bucket.bucket_arn
}

# ============================================================
# RDS (must be created before EC2 for SG reference)
# ============================================================

module "rds" {
  source = "../../modules/rds"

  project     = var.project
  environment = var.environment

  vpc_id                    = module.vpc.vpc_id
  subnet_ids                = module.vpc.private_data_subnet_ids
  allowed_security_group_id = module.ec2.web_app_security_group_id

  instance_class          = "db.t4g.micro"
  allocated_storage       = 20
  max_allocated_storage   = 100
  backup_retention_period = 1
  multi_az                = false
}

# ============================================================
# Secrets Manager (Tailscale auth key)
# ============================================================

resource "aws_secretsmanager_secret" "tailscale" {
  name        = "${var.project}-${var.environment}-tailscale-auth-key"
  description = "Tailscale auth key for EC2 instances"
}

# CloudWatch Agent config in SSM Parameter Store
resource "aws_ssm_parameter" "cw_agent_config" {
  name  = "/${var.project}/${var.environment}/cloudwatch-agent-config"
  type  = "String"
  value = jsonencode({
    metrics = {
      namespace = "CWAgent"
      metrics_collected = {
        mem = {
          measurement = ["mem_used_percent"]
        }
        disk = {
          measurement = ["disk_used_percent"]
          resources   = ["/"]
        }
      }
      append_dimensions = {
        InstanceId = "$${aws:InstanceId}"
      }
    }
  })
}

# ============================================================
# EC2
# ============================================================

module "ec2" {
  source = "../../modules/ec2"

  project     = var.project
  environment = var.environment

  vpc_id    = module.vpc.vpc_id
  vpc_cidr  = "10.1.0.0/16"
  subnet_id = module.vpc.private_app_subnet_ids[0]

  rds_security_group_id = module.rds.security_group_id

  instance_type = "t4g.micro"
  instances = {
    "web-site"      = "site"
    "web-admin"     = "admin"
    "web-wordpress" = "wordpress"
    "web-openclaw"  = "openclaw"
  }

  tailscale_auth_key_secret_arn  = aws_secretsmanager_secret.tailscale.arn
  cloudwatch_agent_config_ssm_param = aws_ssm_parameter.cw_agent_config.name
}

# ============================================================
# Security Services
# ============================================================

module "security" {
  source = "../../modules/security"

  project     = var.project
  environment = var.environment

  logs_bucket_name = module.logs_bucket.bucket_id
  logs_bucket_arn  = module.logs_bucket.bucket_arn
}

# ============================================================
# Monitoring
# ============================================================

module "monitoring" {
  source = "../../modules/monitoring"

  project     = var.project
  environment = var.environment

  alert_email      = var.alert_email
  ec2_instance_ids = module.ec2.instance_ids
  rds_instance_id  = module.rds.db_instance_id
  nat_instance_id  = null # NAT instance ID not exposed yet - add to VPC module outputs if needed
}

# ============================================================
# Backup
# ============================================================

module "backup" {
  source = "../../modules/backup"

  project       = var.project
  environment   = var.environment
  is_production = false
}

# ============================================================
# Patching
# ============================================================

module "patching" {
  source = "../../modules/patching"

  project     = var.project
  environment = var.environment
}
```

- [ ] **Step 2: Add alert_email variable**

Append to `terraform/environments/dev/variables.tf`:
```hcl
variable "alert_email" {
  description = "Email for CloudWatch and budget alerts"
  type        = string
}
```

- [ ] **Step 3: Create outputs.tf**

`terraform/environments/dev/outputs.tf`:
```hcl
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "ec2_instance_ids" {
  value = module.ec2.instance_ids
}

output "ec2_private_ips" {
  value = module.ec2.instance_private_ips
}

output "rds_endpoint" {
  value     = module.rds.endpoint
  sensitive = true
}

output "tailscale_secret_arn" {
  value = aws_secretsmanager_secret.tailscale.arn
}
```

- [ ] **Step 4: Create terraform.tfvars.example**

`terraform/environments/dev/terraform.tfvars.example`:
```hcl
aws_region  = "ca-central-1"
environment = "development"
project     = "aromaestro"
alert_email = "your-email@aromaestro.com"
```

- [ ] **Step 5: Validate**

```bash
cd terraform/environments/dev
terraform init
terraform validate
```

Expected: `Success! The configuration is valid.`

- [ ] **Step 6: Plan (dry run)**

Instruct the user:
```bash
cd terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with real email
terraform plan
```

Review the plan output. Expected: creation of ~40-50 resources.

- [ ] **Step 7: Apply**

Instruct the user:
```bash
terraform apply
```

After apply, instruct the user to:
1. Set the Tailscale auth key in Secrets Manager
2. Confirm SNS email subscription (check inbox)
3. Verify instances are running in EC2 console

- [ ] **Step 8: Commit**

```bash
git add terraform/environments/dev/
git commit -m "feat: wire up complete dev environment"
```

---

### Task 14: Runbooks and Final Documentation

**Files:**
- Create: `docs/runbooks/incident-response.md`
- Create: `docs/runbooks/restore-rds.md`
- Create: `docs/runbooks/restore-ec2.md`
- Create: `docs/security/encryption.md`
- Create: `docs/security/iam.md`
- Update: `docs/README.md` (final version)

- [ ] **Step 1: Write incident response runbook**

`docs/runbooks/incident-response.md`:
```markdown
# Incident Response

## Niveaux de severite

| Niveau | Critere | Temps de reponse |
|---|---|---|
| P1 - Critique | Infra down, donnees a risque | Immediat |
| P2 - Majeur | Degradation service | < 4 heures |
| P3 - Mineur | Alarme non-critique | Prochain jour ouvrable |

## Procedure

### 1. Detection
- Alerte email via SNS (CloudWatch, GuardDuty, Inspector)
- Dashboard SecurityHub

### 2. Evaluation
- Identifier la ressource affectee
- Determiner la severite (P1/P2/P3)

### 3. Containment
- **Instance compromise** : modifier le Security Group pour couper tout trafic
- **Credentials compromises** : revoquer les cles IAM immediatement
- **S3 breach** : activer le deny all sur le bucket

### 4. Investigation
- CloudTrail : qui a fait quoi, quand
- CloudWatch Logs : logs applicatifs
- GuardDuty : detail du finding
- VPC Flow Logs : trafic reseau suspect

### 5. Remediation
- Corriger la vulnerabilite
- Patcher si necessaire
- Restaurer depuis backup si donnees corrompues

### 6. Post-mortem
- Documenter l'incident
- Identifier la cause racine
- Ajuster les controles pour prevenir la recurrence
```

- [ ] **Step 2: Write RDS restore runbook**

`docs/runbooks/restore-rds.md`:
```markdown
# Restauration RDS

## Depuis un snapshot automatique

### Via Console
1. RDS > Snapshots > Automated
2. Selectionner le snapshot desire
3. Actions > Restore snapshot
4. Configuration :
   - DB instance identifier : `aromaestro-{env}-mysql-restored`
   - Instance class : identique a l'original
   - VPC : identique
   - Subnet group : identique
   - Security group : sg-rds
5. Restore DB instance
6. Attendre ~15 minutes
7. Mettre a jour l'endpoint dans les applications

### Via CLI
```bash
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier aromaestro-dev-mysql-restored \
  --db-snapshot-identifier <snapshot-id> \
  --db-instance-class db.t4g.micro \
  --db-subnet-group-name aromaestro-development-db-subnet-group \
  --vpc-security-group-ids <sg-rds-id>
```

## Validation post-restauration

1. Verifier la connectivite depuis une instance EC2
2. Verifier l'integrite des donnees (compter les tables/rows)
3. Tester les applications
```

- [ ] **Step 3: Write EC2 restore runbook**

`docs/runbooks/restore-ec2.md`:
```markdown
# Restauration EC2

## Depuis une AMI (AWS Backup)

### Via Console
1. EC2 > AMIs > Owned by me
2. Selectionner l'AMI la plus recente pour l'instance
3. Launch instance from AMI
4. Configuration :
   - Instance type : identique (t4g.small prod / t4g.micro dev)
   - Subnet : private-app-a
   - Security group : sg-web-app
   - IAM role : ec2-role
   - Pas d'IP publique
5. Launch

### Post-restauration
1. Tailscale se reconnecte automatiquement (auth key dans Secrets Manager)
2. CloudWatch Agent redemarre automatiquement
3. Verifier la connectivite Tailscale : `tailscale status`
4. Verifier l'application
```

- [ ] **Step 4: Write encryption doc**

`docs/security/encryption.md`:
```markdown
# Chiffrement

## Au repos

| Service | Methode | Cle |
|---|---|---|
| EBS | Chiffrement par defaut au compte | AWS managed KMS |
| S3 | SSE-S3 | AWS managed |
| RDS | KMS | AWS managed KMS |

## En transit

| Service | Methode |
|---|---|
| S3 | Bucket policy deny non-TLS |
| RDS | require_secure_transport = ON |
| Tailscale | WireGuard (chiffrement bout-en-bout) |
| SSM Session Manager | TLS |
```

- [ ] **Step 5: Write IAM doc**

`docs/security/iam.md`:
```markdown
# IAM et Acces

## IAM Identity Center (SSO)

| Role | Permissions | Comptes |
|---|---|---|
| Admin | AdministratorAccess | Tous |
| Developer | Full dev, ReadOnly prod | Dev, Prod |
| Emergency | AdministratorAccess (break-glass) | Tous |

- URL : https://aromaestro.awsapps.com/start
- MFA obligatoire

## Roles IAM (service)

| Role | Service | Permissions |
|---|---|---|
| ec2-role | EC2 | SSM, CloudWatch Agent, Secrets Manager (tailscale key) |
| config-role | Config | S3 write (logs bucket) |
| backup-role | AWS Backup | Backup + Restore |
```

- [ ] **Step 6: Update docs/README.md (final version)**

```markdown
# Aromaestro - Documentation Technique AWS

Documentation technique de l'infrastructure AWS Aromaestro.

**Version :** 1.0
**Date :** 2026-04-02
**Region :** ca-central-1 (Canada)
**IaC :** Terraform

---

## Table des matieres

### 1. Architecture
- [Vue d'ensemble](architecture/overview.md)
- [Structure des comptes](architecture/accounts.md)
- [Architecture reseau](architecture/network.md)

### 2. Infrastructure
- [Compute EC2](infrastructure/compute.md)
- [Base de donnees RDS](infrastructure/database.md)
- [Stockage S3](infrastructure/storage.md)

### 3. Securite
- [Services de securite (SCPs, GuardDuty, Inspector, etc.)](security/services.md)
- [IAM et acces](security/iam.md)
- [Chiffrement](security/encryption.md)

### 4. Operations
- [Monitoring et alertes](operations/monitoring.md)
- [Backups](operations/backup.md)
- [Patching](operations/patching.md)

### 5. Runbooks
- [Incident Response](runbooks/incident-response.md)
- [Restauration RDS](runbooks/restore-rds.md)
- [Restauration EC2](runbooks/restore-ec2.md)

---

## Estimation des couts

| | Prod | Dev |
|---|---|---|
| **Total** | ~$221/mois | ~$84/mois |
| **Total combine** | **~$305/mois** | |

## Contacts

| Role | Responsable |
|---|---|
| Administrateur AWS | *(a completer)* |
| Contact securite | *(a completer)* |
```

- [ ] **Step 7: Commit**

```bash
git add docs/
git commit -m "docs: add runbooks, IAM, encryption, and final README index"
```

---

## Phase 3: Prod Environment

### Task 15: Deploy Prod Environment

After dev is validated, prod deployment reuses the same modules with production-specific values.

**Files:**
- Create: `terraform/environments/prod/main.tf`
- Create: `terraform/environments/prod/outputs.tf`
- Create: `terraform/environments/prod/terraform.tfvars.example`

- [ ] **Step 1: Create prod main.tf**

`terraform/environments/prod/main.tf`:

Same structure as dev (Task 13, Step 1) with these differences:
- `vpc_cidr = "10.0.0.0/16"` and matching subnet CIDRs (`10.0.x.x`)
- `use_nat_gateway = true` (NAT Gateway instead of NAT instance)
- `private_app_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]` (2 AZs)
- `instance_type = "t4g.small"` for EC2
- `instance_class = "db.t4g.small"` for RDS
- `backup_retention_period = 7`
- `is_production = true`
- Add VPC Endpoints module for SSM (see spec section 3)

```hcl
# terraform/environments/prod/main.tf

# ============================================================
# S3 Buckets
# ============================================================

module "logs_bucket" {
  source = "../../modules/s3"

  bucket_name              = "aromaestro-prod-logs"
  enable_versioning        = false
  lifecycle_expiration_days = 90
  force_tls                = true

  tags = { Application = "shared" }
}

module "assets_bucket" {
  source = "../../modules/s3"

  bucket_name       = "aromaestro-prod-assets"
  enable_versioning = true
  force_tls         = true

  tags = { Application = "shared" }
}

# ============================================================
# VPC
# ============================================================

module "vpc" {
  source = "../../modules/vpc"

  project     = var.project
  environment = var.environment

  vpc_cidr        = "10.0.0.0/16"
  public_nat_cidr = "10.0.100.0/24"
  private_app_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_data_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
  availability_zones = ["ca-central-1a", "ca-central-1b"]

  use_nat_gateway = true

  logs_bucket_arn = module.logs_bucket.bucket_arn
}

# ============================================================
# VPC Endpoints (SSM - prod only)
# ============================================================

resource "aws_security_group" "vpc_endpoints" {
  name   = "${var.project}-${var.environment}-sg-vpc-endpoints"
  vpc_id = module.vpc.vpc_id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  tags = {
    Name = "${var.project}-${var.environment}-sg-vpc-endpoints"
  }
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.ca-central-1.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_app_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ssm_messages" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.ca-central-1.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_app_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ec2_messages" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.ca-central-1.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_app_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
}

# ============================================================
# RDS
# ============================================================

module "rds" {
  source = "../../modules/rds"

  project     = var.project
  environment = var.environment

  vpc_id                    = module.vpc.vpc_id
  subnet_ids                = module.vpc.private_data_subnet_ids
  allowed_security_group_id = module.ec2.web_app_security_group_id

  instance_class          = "db.t4g.small"
  allocated_storage       = 20
  max_allocated_storage   = 100
  backup_retention_period = 7
  multi_az                = false
}

# ============================================================
# Secrets + CloudWatch Agent Config
# ============================================================

resource "aws_secretsmanager_secret" "tailscale" {
  name        = "${var.project}-${var.environment}-tailscale-auth-key"
  description = "Tailscale auth key for EC2 instances"
}

resource "aws_ssm_parameter" "cw_agent_config" {
  name  = "/${var.project}/${var.environment}/cloudwatch-agent-config"
  type  = "String"
  value = jsonencode({
    metrics = {
      namespace = "CWAgent"
      metrics_collected = {
        mem = {
          measurement = ["mem_used_percent"]
        }
        disk = {
          measurement = ["disk_used_percent"]
          resources   = ["/"]
        }
      }
      append_dimensions = {
        InstanceId = "$${aws:InstanceId}"
      }
    }
  })
}

# ============================================================
# EC2
# ============================================================

module "ec2" {
  source = "../../modules/ec2"

  project     = var.project
  environment = var.environment

  vpc_id    = module.vpc.vpc_id
  vpc_cidr  = "10.0.0.0/16"
  subnet_id = module.vpc.private_app_subnet_ids[0]

  rds_security_group_id = module.rds.security_group_id

  instance_type = "t4g.small"
  instances = {
    "web-site"      = "site"
    "web-admin"     = "admin"
    "web-wordpress" = "wordpress"
    "web-openclaw"  = "openclaw"
  }

  tailscale_auth_key_secret_arn  = aws_secretsmanager_secret.tailscale.arn
  cloudwatch_agent_config_ssm_param = aws_ssm_parameter.cw_agent_config.name
}

# ============================================================
# Security + Monitoring + Backup + Patching
# ============================================================

module "security" {
  source = "../../modules/security"

  project          = var.project
  environment      = var.environment
  logs_bucket_name = module.logs_bucket.bucket_id
  logs_bucket_arn  = module.logs_bucket.bucket_arn
}

module "monitoring" {
  source = "../../modules/monitoring"

  project          = var.project
  environment      = var.environment
  alert_email      = var.alert_email
  ec2_instance_ids = module.ec2.instance_ids
  rds_instance_id  = module.rds.db_instance_id
}

module "backup" {
  source = "../../modules/backup"

  project       = var.project
  environment   = var.environment
  is_production = true
}

module "patching" {
  source = "../../modules/patching"

  project     = var.project
  environment = var.environment
}
```

- [ ] **Step 2: Add alert_email variable to prod**

Append to `terraform/environments/prod/variables.tf`:
```hcl
variable "alert_email" {
  description = "Email for CloudWatch and budget alerts"
  type        = string
}
```

- [ ] **Step 3: Create prod outputs and tfvars example**

`terraform/environments/prod/outputs.tf`:
```hcl
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "ec2_instance_ids" {
  value = module.ec2.instance_ids
}

output "ec2_private_ips" {
  value = module.ec2.instance_private_ips
}

output "rds_endpoint" {
  value     = module.rds.endpoint
  sensitive = true
}
```

`terraform/environments/prod/terraform.tfvars.example`:
```hcl
aws_region  = "ca-central-1"
environment = "production"
project     = "aromaestro"
alert_email = "your-email@aromaestro.com"
```

- [ ] **Step 4: Validate**

```bash
cd terraform/environments/prod
terraform init
terraform validate
```

- [ ] **Step 5: Plan and apply (user runs)**

```bash
terraform plan
terraform apply
```

- [ ] **Step 6: Commit**

```bash
git add terraform/environments/prod/
git commit -m "feat: wire up complete prod environment"
```

---

### Task 16: Import Existing S3 Buckets

**Files:**
- Create: `terraform/imports/s3.tf`

- [ ] **Step 1: Create import configuration**

`terraform/imports/s3.tf`:
```hcl
# Import existing S3 buckets into the prod Terraform state
# Run these commands from the prod environment:
#
# terraform import module.existing_backups.aws_s3_bucket.this aromaestro-backups
# terraform import module.existing_diffuser_ota.aws_s3_bucket.this aromaestro-diffuser-ota
# terraform import module.existing_ota.aws_s3_bucket.this aromaestro-ota
```

Add to `terraform/environments/prod/main.tf`:
```hcl
# ============================================================
# Existing S3 Buckets (imported)
# ============================================================

module "existing_backups" {
  source = "../../modules/s3"

  bucket_name          = "aromaestro-backups"
  enable_versioning    = true
  lifecycle_glacier_days = 30
  force_tls            = true

  tags = { Application = "shared" }
}

module "existing_diffuser_ota" {
  source = "../../modules/s3"

  bucket_name       = "aromaestro-diffuser-ota"
  enable_versioning = true
  force_tls         = true

  tags = { Application = "shared" }
}

module "existing_ota" {
  source = "../../modules/s3"

  bucket_name       = "aromaestro-ota"
  enable_versioning = true
  force_tls         = true

  tags = { Application = "shared" }
}
```

- [ ] **Step 2: Run imports (user action)**

Instruct the user:
```bash
cd terraform/environments/prod
terraform import module.existing_backups.aws_s3_bucket.this aromaestro-backups
terraform import module.existing_diffuser_ota.aws_s3_bucket.this aromaestro-diffuser-ota
terraform import module.existing_ota.aws_s3_bucket.this aromaestro-ota
terraform plan # Verify no destructive changes
terraform apply # Apply versioning/encryption/TLS changes
```

- [ ] **Step 3: Commit**

```bash
git add terraform/imports/ terraform/environments/prod/main.tf
git commit -m "feat: import existing S3 buckets into Terraform"
```

---

### Task 17: Management Account - Budgets

**Files:**
- Update: `terraform/environments/management/main.tf`

- [ ] **Step 1: Add budgets to management environment**

Append to `terraform/environments/management/main.tf`:
```hcl
module "budgets" {
  source = "../../modules/budgets"

  project      = var.project
  budget_limit = "350"
  alert_email  = var.alert_email
}
```

Add variable:
```hcl
variable "alert_email" {
  description = "Email for budget alerts"
  type        = string
}
```

- [ ] **Step 2: Apply**

```bash
cd terraform/environments/management
terraform init
terraform plan
terraform apply
```

- [ ] **Step 3: Commit**

```bash
git add terraform/environments/management/
git commit -m "feat: add AWS Budgets and Cost Anomaly Detection"
```

---

## Post-Deployment Checklist

- [ ] Confirm SNS email subscriptions (check inbox for both envs)
- [ ] Set Tailscale auth keys in Secrets Manager (dev + prod)
- [ ] Verify Tailscale connectivity to all instances
- [ ] Verify SSM Session Manager works on all instances
- [ ] Verify CloudWatch Agent metrics appear (CWAgent namespace)
- [ ] Verify RDS connectivity from EC2 instances
- [ ] Verify GuardDuty/Inspector are active in SecurityHub
- [ ] Verify CloudTrail is logging
- [ ] Create the 4 databases on RDS (db_site, db_admin, db_wordpress, db_openclaw)
- [ ] Review SecurityHub findings and remediate
- [ ] Update docs with actual account IDs and endpoints
