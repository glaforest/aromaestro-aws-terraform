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
| AWSIoTOTAUpdateRole | Prod-OTA | AWS IoT | S3 read/write (aromaestro-diffuser-ota), Signer, IoT Jobs/Streams, PassRole self |

## Comptes de service IAM (users)

| User | Compte | Usage | Permissions |
|---|---|---|---|
| ota_user | Prod-OTA | Automation du script `scripts/deploy-ota.sh` dans le repo firmware | S3 firmware upload, IoT CreateOTAUpdate, Signer, PassRole scope a AWSIoTOTAUpdateRole (condition `iam:PassedToService=iot.amazonaws.com`) |

Path : `/service-accounts/`. Pas de console, pas de MFA. Access key geree par Terraform, exposee via output sensitive `ota_user_access_key_id` / `ota_user_secret_access_key`. Rotation manuelle : `terraform taint aws_iam_access_key.ota_user && terraform apply`.

Voir [infrastructure/ota.md](../infrastructure/ota.md) pour le flow complet.

## Acces aux instances

L'acces aux instances se fait via :

1. **Tailscale** (principal) : mesh VPN zero-trust, acces SSH/HTTP via overlay
2. **SSM Session Manager** (fallback) : `aws ssm start-session --target <instance-id>`

Aucun port SSH (22) n'est ouvert dans les Security Groups.
