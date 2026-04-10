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
| aromaestro-prod | 872515273944 | Terraform prod (Phase 3) + prod-ota (IoT OTA pipeline) |
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

## Environnements Terraform dans le compte Prod

Le compte Prod heberge **deux environnements Terraform isoles** avec des state files distincts :

| Environnement | Terraform dir | State key | Statut | Scope |
|---|---|---|---|---|
| `prod` | `terraform/environments/prod/` | `env/prod/terraform.tfstate` | Code pret, non deploye (Phase 3) | VPC, EC2, RDS, S3 generiques, Backup, Security services |
| `prod-ota` | `terraform/environments/prod-ota/` | `env/prod-ota/terraform.tfstate` | Deploye | Pipeline IoT OTA (bucket firmware, ACM cert, Signer, IoT role, ota_user) |

Les deux environnements utilisent le meme backend S3 (`aromaestro-terraform-state` avec profil `aromaestro-mgmt`) mais des cles distinctes, donc aucun risque de collision sur les locks ou les ressources en state. Voir [infrastructure/ota.md](../infrastructure/ota.md) pour le detail de prod-ota.
