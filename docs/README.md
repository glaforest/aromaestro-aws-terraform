# Aromaestro - Documentation Technique AWS

Documentation technique de l'infrastructure AWS Aromaestro.

**Version :** 1.0
**Date :** 2026-04-02
**Region :** ca-central-1 (Canada)
**IaC :** Terraform

---

## Demarrage rapide

**Nouvel ordinateur?** Voir le [Guide de demarrage](getting-started.md) pour tout installer et configurer.

---

## Table des matieres

### 0. Demarrage
- [Guide de demarrage (nouvel ordinateur)](getting-started.md)
- [Presentation KPMG](presentation-kpmg.md)

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

### 6. Specs et Plans
- [Design spec (rev.2)](specs/2026-04-02-aromaestro-aws-infrastructure-design.md)
- [Plan d'implementation](specs/2026-04-02-aromaestro-aws-infrastructure.md)

---

## Estimation des couts

| | Prod | Dev |
|---|---|---|
| **Total** | ~$221/mois | ~$84/mois |
| **Total combine** | **~$305/mois** | |

## Comptes AWS

| Compte | Account ID | Role |
|---|---|---|
| Management | 589389426408 | Facturation, Organizations, SCPs |
| Prod | 872515273944 | Workloads production, IoT, SES |
| Dev | 051370880327 | Environnement de developpement |
| LogArchive | 315466292610 | Logs d'audit |

## Commandes rapides

```bash
# Renouveler la session SSO
aws sso login --profile aromaestro-dev

# Terraform dev
cd terraform/environments/dev
AWS_PROFILE=aromaestro-dev terraform plan

# Terraform management
cd terraform/environments/management
AWS_PROFILE=aromaestro-mgmt terraform plan

# Se connecter a une instance via SSM
AWS_PROFILE=aromaestro-dev aws ssm start-session --target <instance-id>
```
