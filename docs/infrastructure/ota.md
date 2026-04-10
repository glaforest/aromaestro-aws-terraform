# IoT OTA (Firmware Delivery)

Pipeline de livraison OTA (Over-The-Air) de firmware pour la flotte de diffuseurs ESP32-C5 en production, via AWS FreeRTOS OTA.

## Environnement

| | Valeur |
|---|---|
| Terraform dir | `terraform/environments/prod-ota/` |
| Compte AWS | Prod (872515273944) |
| Profil CLI | `aromaestro-prod` (backend: `aromaestro-mgmt`) |
| State S3 key | `env/prod-ota/terraform.tfstate` |
| Region | ca-central-1 |

State isole du `prod/` main pour ne pas coupler la pipeline OTA au deploiement Phase 3 non encore applique. Les deux environnements vivent dans le meme compte AWS.

## Ressources

### S3 bucket `aromaestro-diffuser-ota`

| | Valeur |
|---|---|
| Versioning | Active (obligatoire pour AWS IoT OTA) |
| Chiffrement | SSE-S3 (AES256) |
| TLS enforce | Oui |
| Block Public Access | Complet (4/4) |
| Lifecycle | Expiration 90j sur le prefix `signed/` (+ versions non-courantes) |

Layout des cles :
- `firmwares/v{X.Y.Z}/aromaestro_ESP32_C5_diffuser.bin` - uploade par le script de deploiement
- `signed/<uuid>` - ecrits par AWS Signer lors du signing job

Le bucket pre-existait et a ete importe dans le state `prod-ota` via `terraform import module.diffuser_ota_bucket.aws_s3_bucket.this aromaestro-diffuser-ota` (plus 3 sous-ressources : versioning, encryption, public_access_block).

### Certificat ACM (code signing)

| | Valeur |
|---|---|
| Subject | CN=DiffuserOTACodeSign, O=Aromaestro, C=CA |
| Serial | 091AC033257B23E5BB494764E4CA5B9213F3E4C7 |
| Algorithme | ECDSA P-256 / SHA256 |
| Validite | 2025-12-06 -> 2035-12-04 |
| Lifecycle | `prevent_destroy = true` |

**Critique : ne jamais regenerer.** Le cert est embarque dans le firmware de chaque diffuseur en prod via `components/aws_ota/include/codesign_cert.h` au compile-time. Un cert different = les devices rejettent tous les updates, requirement re-flash manuel.

PEM + cle privee stockes dans `terraform/environments/prod-ota/ota.auto.tfvars` (gitignored via `*.tfvars`). Reference dans le repo firmware : `codesign_cert.pem` + `codesign_key.pem` a la racine.

### AWS Signer profile `AromaestroESP32C5OTACodeSign`

| | Valeur |
|---|---|
| Platform | AmazonFreeRTOS-Default |
| Signing material | ARN du cert ACM ci-dessus |
| signingParameters.certname | `/cert.pem` (placeholder ; les devices ignorent ce chemin car le cert est en ROM) |

**Gere via `terraform_data` + `local-exec`**, pas via `aws_signer_signing_profile` direct, parce que le provider hashicorp/aws n'expose pas l'argument `signing_parameters` que AWS FreeRTOS exige. Le local-exec appelle `aws signer put-signing-profile --signing-parameters certname=/cert.pem` et est create-only : si le profil existe deja et est Active, le bloc skip (idempotent).

Historique : l'ancien profil `DiffuserOTACodeSign` (sans `certname`) a ete cancel le 2026-04-10 et son nom est permanently reserve (AWS Signer ne permet pas la reutilisation d'un nom cancel). Le nouveau profil porte le nom du hardware pour eviter la collision. Pour changer le cert dans le futur : choisir un nouveau nom, mettre a jour `local.ota_signing_profile_name` dans `main.tf` et `OTA_SIGNING_PROFILE` dans `scripts/.env` du repo firmware.

### IAM role `AWSIoTOTAUpdateRole`

Role service assume par `iot.amazonaws.com` pendant l'execution d'un job OTA. Perms inline (`OtaUpdatePolicy`) :

- **S3** : `GetObjectVersion`, `GetObject`, `PutObject` sur `aromaestro-diffuser-ota/*` ; `GetBucketLocation`, `ListBucket`, `ListBucketVersions` sur le bucket
- **Signer** : `DescribeSigningJob`, `GetSigningProfile`, `StartSigningJob` (`*`)
- **IoT Jobs & Streams** : `CreateJob`, `DescribeJob`, `UpdateJob`, `CancelJob`, `DeleteJob`, `DescribeJobExecution`, `CreateStream`, `DescribeStream`, `DeleteStream`, `GetOTAUpdate` (`*`) - requis pour que `CreateOTAUpdate` provisionne les ressources downstream
- **iam:PassRole** : sur son propre ARN - requis parce que IoT passe le role au service Stream downstream

### IAM user `ota_user`

Compte de service (pas de console, pas de MFA) utilise par le script `scripts/deploy-ota.sh` du repo firmware. Path `/service-accounts/`. Inline policy `OtaDeployPolicy` :

- **S3** : PutObject/GetObject/GetObjectVersion/AbortMultipartUpload/ListBucket/ListBucketVersions/GetBucketLocation sur le bucket OTA
- **IoT OTA** : CreateOTAUpdate, DescribeOTAUpdate, GetOTAUpdate, ListOTAUpdates, DeleteOTAUpdate, CreateJob, DescribeJob, DescribeJobExecution, CancelJob, DescribeThing, ListThings, ListThingGroups (`*`)
- **Signer** : StartSigningJob, DescribeSigningJob, GetSigningProfile, ListSigningProfiles (`*`)
- **iam:PassRole** : sur `AWSIoTOTAUpdateRole` uniquement, conditionne a `iam:PassedToService=iot.amazonaws.com` (anti-escalation)

Access key et secret exposes via les outputs Terraform `ota_user_access_key_id` / `ota_user_secret_access_key` (marques `sensitive`). Copies manuellement dans le `scripts/.env` du repo firmware. Rotation manuelle : `terraform taint aws_iam_access_key.ota_user && terraform apply`.

## Flow de deploiement

Le script `scripts/deploy-ota.sh` dans le repo firmware (separe, a `/Applications/Work/Diffusers_Firmwares/diffuser_firmware_esp32`) orchestre :

1. Bump `PROJECT_VER` dans `CMakeLists.txt`
2. Build via `idf.py build`
3. Upload le binaire a `s3://aromaestro-diffuser-ota/firmwares/v{X.Y.Z}/aromaestro_ESP32_C5_diffuser.bin`
4. Lookup du `VersionId` S3 du nouvel upload (requis par IoT OTA meme sur bucket versionne)
5. `aws iot create-ota-update` avec `files_json` referencant bucket/key/version + `signingProfileName: AromaestroESP32C5OTACodeSign` + `role-arn: AWSIoTOTAUpdateRole`
6. AWS IoT assume `AWSIoTOTAUpdateRole`, lance un signing job Signer, cree un IoT Job et un Stream, publie au Thing Group `Diffusers`
7. Le device recoit le job via MQTT, telecharge depuis le presigned URL dans `signed/`, verifie la signature ECDSA contre le cert embarque, flash et reboot

Mode `--check` : n'execute que les verifications de credentials et d'acces aux ressources AWS, utile pour debug.

## Outputs Terraform

| Output | Valeur |
|---|---|
| `ota_s3_bucket` | `aromaestro-diffuser-ota` |
| `ota_signing_profile` | `AromaestroESP32C5OTACodeSign` |
| `ota_iam_role_arn` | ARN de `AWSIoTOTAUpdateRole` |
| `ota_acm_cert_arn` | ARN du cert ACM |
| `ota_user_access_key_id` | (sensitive) |
| `ota_user_secret_access_key` | (sensitive) |

Lecture :

```bash
cd terraform/environments/prod-ota
AWS_PROFILE=aromaestro-prod terraform output -raw ota_user_access_key_id
AWS_PROFILE=aromaestro-prod terraform output -raw ota_user_secret_access_key
```

## Commandes utiles

```bash
# Status du signer profile
AWS_PROFILE=aromaestro-prod aws signer get-signing-profile \
  --profile-name AromaestroESP32C5OTACodeSign --region ca-central-1

# Liste des OTA updates
AWS_PROFILE=aromaestro-prod aws iot list-ota-updates --region ca-central-1

# Status d'un OTA update specifique
AWS_PROFILE=aromaestro-prod aws iot get-ota-update \
  --ota-update-id OTA-v3_4_1-<timestamp> --region ca-central-1

# Supprimer un OTA update et son job IoT (pour relancer un deploy)
AWS_PROFILE=aromaestro-prod aws iot delete-ota-update \
  --ota-update-id OTA-v3_4_1-<timestamp> \
  --delete-stream --force-delete-aws-job

# Content du bucket
AWS_PROFILE=aromaestro-prod aws s3 ls s3://aromaestro-diffuser-ota/
```

## Historique des regressions resolues

- **2026-04-10** : `put-signing-profile` n'accepte pas de `signature_validity_period` sur la plateforme `AmazonFreeRTOS-Default` (la validite est fixee par la plateforme). Le provider Terraform l'envoyait par defaut ; solution = `terraform_data` + CLI directe sans le flag.
- **2026-04-10** : description IAM role rejetee par AWS parce qu'elle contenait un em-dash unicode. Le regex de validation IAM n'accepte que Latin-1. Remplace par hyphen ASCII.
- **2026-04-10** : signing job failed pour `ota_user` avec `AccessDenied` sur l'objet S3 source. Le brief initial n'incluait pas `s3:GetObjectVersion` dans `OtaDeployPolicy`, requis par Signer sur un bucket versionne.
- **2026-04-10** : `CreateOTAUpdate` CREATE_FAILED avec `iot:CreateJob AccessDenied`. Le role `AWSIoTOTAUpdateRole` n'avait pas les perms IoT Jobs/Streams. Ajoutees a l'inline policy.
- **2026-04-10** : idem avec `iam:PassRole AccessDenied` sur son propre ARN. IoT passe le role au service Stream downstream. Ajout d'une statement `PassRole` sur `self.arn`.
- **2026-04-10** : signing profile `DiffuserOTACodeSign` cree sans `signingParameters.certname`, rejete par FreeRTOS OTA avec `Code signing job must have certificate path certname as the key in signing parameter`. Annulation du profil + nouveau nom `AromaestroESP32C5OTACodeSign` (noms annules sont permanently reserves chez AWS Signer).

## Voir aussi

- [Plan Terraform initial](../specs/2026-04-02-aromaestro-aws-infrastructure.md)
- [Guide de demarrage - Etape Prod-OTA](../getting-started.md)
- [IAM et acces](../security/iam.md)
- [Stockage S3](./storage.md)
