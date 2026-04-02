# Stockage S3

## Buckets

### Existants (compte Prod, a importer en Phase 3)

| Bucket | Usage |
|---|---|
| aromaestro-backups | Backups manuels |
| aromaestro-diffuser-ota | OTA firmware diffuseurs (IoT) |
| aromaestro-ota | OTA firmware |

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
