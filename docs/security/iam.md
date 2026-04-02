# IAM et Acces

## IAM Identity Center (SSO)

URL du portail : `https://d-9d674000e9.awsapps.com/start`

| Role | Permissions | Comptes |
|---|---|---|
| Admin | AdministratorAccess | Tous |
| Developer | Full dev, ReadOnly prod | Dev, Prod |
| Emergency | AdministratorAccess (break-glass) | Tous |

MFA obligatoire sur tous les utilisateurs.

## Roles IAM (service)

| Role | Compte | Service | Permissions |
|---|---|---|---|
| ec2-role | Dev/Prod | EC2 | SSM, CloudWatch Agent, Secrets Manager (tailscale key) |
| config-role | Dev/Prod | Config | S3 write (logs bucket) |
| backup-role | Dev/Prod | AWS Backup | Backup + Restore |

## Acces aux instances

L'acces aux instances se fait via :

1. **Tailscale** (principal) : mesh VPN zero-trust, acces SSH/HTTP via overlay
2. **SSM Session Manager** (fallback) : `aws ssm start-session --target <instance-id>`

Aucun port SSH (22) n'est ouvert dans les Security Groups.
