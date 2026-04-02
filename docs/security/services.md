# Services de securite AWS

## SCPs (Service Control Policies)

Une SCP combinee `aromaestro-guardrails` est appliquee au niveau racine de l'Organisation et s'applique a tous les comptes membres.

| Regle | Description |
|---|---|
| RegionDeny | Restreint toutes les operations a ca-central-1 (exclut les services globaux) |
| DenyRootUser | Bloque l'utilisation du root user sur les comptes membres |
| ProtectCloudTrail | Empeche la suppression/modification de CloudTrail |
| ProtectConfig | Empeche la suppression/modification de Config |
| ProtectGuardDuty | Empeche la desactivation de GuardDuty |
| DenyS3PublicAccess | Empeche la desactivation du Block Public Access sur les buckets S3 |

## Services de detection (par compte)

| Service | Role | Status |
|---|---|---|
| GuardDuty | Detection de menaces en temps reel | Actif sur Dev |
| Inspector | Scan de vulnerabilites EC2 | Actif sur Dev |
| SecurityHub | Dashboard centralise | Actif sur Dev |
| CloudTrail | Journal d'audit API | Actif sur Dev, logs vers S3 |
| Config | Conformite des ressources | Actif sur Dev, 4 regles |

### Config Rules

| Regle | Description |
|---|---|
| ebs-encryption-by-default | Verifie le chiffrement EBS par defaut |
| s3-bucket-public-read-prohibited | Detecte les buckets publics |
| rds-storage-encrypted | Verifie le chiffrement RDS |
| restricted-ssh | Detecte les SGs avec SSH ouvert a 0.0.0.0/0 |

## EBS Encryption

Chiffrement active par defaut au niveau du compte. Toute nouvelle instance EC2 aura ses volumes EBS automatiquement chiffres.
