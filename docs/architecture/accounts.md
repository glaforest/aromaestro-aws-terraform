# Structure des comptes AWS

## AWS Organizations

| Compte | Nom | Account ID | Role |
|---|---|---|---|
| Management | Aromaestro Inc. | 589389426408 | Facturation, Organizations, IAM Identity Center, SCPs |
| Prod | Aromaestro.com | 872515273944 | Workloads production, IoT, SES |
| Dev | Aromaestro Dev | 051370880327 | Environnement de developpement |
| LogArchive | Log Archive | 315466292610 | Centralisation des logs d'audit |

## IAM Identity Center (SSO)

URL du portail : `https://d-9d674000e9.awsapps.com/start`

| Role | Permissions | Comptes |
|---|---|---|
| Admin | AdministratorAccess | Tous |
| Developer | Full access dev, ReadOnly prod | Dev, Prod |
| Emergency | AdministratorAccess (break-glass) | Tous |

MFA obligatoire sur tous les utilisateurs.

## Profils AWS CLI

| Profil | Compte | Usage |
|---|---|---|
| aromaestro-dev | 051370880327 | Terraform dev, operations dev |
| aromaestro-mgmt | 589389426408 | Terraform management, SCPs, budgets |
| aromaestro-prod | 872515273944 | Terraform prod (Phase 3) |
| aromaestro-logarchive | 315466292610 | Terraform logarchive |

### Commandes Terraform

```bash
# Dev environment
AWS_PROFILE=aromaestro-dev terraform plan

# Management (SCPs, budgets)
AWS_PROFILE=aromaestro-mgmt terraform plan

# Renouveler la session SSO
aws sso login --profile aromaestro-dev
```

Le backend S3 utilise toujours le profil `aromaestro-mgmt` (configure dans `versions.tf`).
