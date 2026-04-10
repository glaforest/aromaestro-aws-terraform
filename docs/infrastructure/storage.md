# Stockage S3

## Buckets

### Existants (compte Prod, a importer en Phase 3)

Geres dans l'environnement `prod/` (non encore deploye) :

| Bucket | Usage |
|---|---|
| aromaestro-backups | Backups manuels |
| aromaestro-ota | OTA firmware (legacy, ESP_Wrover) |

### Prod-OTA (compte Prod, environnement isole, deploye)

Geres dans l'environnement `prod-ota/` (state `env/prod-ota/terraform.tfstate`) :

| Bucket | Usage | Config |
|---|---|---|
| aromaestro-diffuser-ota | OTA firmware diffuseurs ESP32-C5 (IoT, en prod) | Versioning active, SSE-S3 (AES256), TLS enforce, lifecycle expiration 90j sur prefix `signed/` |

Voir [ota.md](ota.md) pour le pipeline complet (ACM cert, Signer profile, IoT role, ota_user).

### Dev

| Bucket | Usage | Config |
|---|---|---|
| aromaestro-dev-assets | Fichiers statiques apps web | SSE-KMS, versioning, TLS enforce |
| aromaestro-dev-logs | CloudTrail, VPC Flow Logs, Config | AES256, lifecycle 90j, policy CloudTrail/Config |

### Terraform State (Management)

| Bucket | Usage |
|---|---|
| aromaestro-terraform-state | State Terraform (tous les environnements) |

## Securite

- **Block Public Access** sur tous les buckets
- **TLS enforce** via bucket policy (deny aws:SecureTransport = false)
- **Chiffrement au repos** : AES256 pour les buckets logs (compatibilite CloudTrail), KMS pour les autres
- **Versioning** active sur assets et terraform state
- **Lifecycle** : suppression apres 90 jours sur les buckets logs
