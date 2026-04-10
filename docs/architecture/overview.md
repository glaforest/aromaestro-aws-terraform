# Vue d'ensemble de l'architecture

## Resume

Infrastructure AWS multi-compte pour Aromaestro utilisant une approche zero-trust avec Tailscale.

## Structure des comptes

| Compte | Role | ID |
|---|---|---|
| Management | Facturation, Organizations, IAM Identity Center, SCPs | 589389426408 |
| Prod | Workloads de production, IoT, SES | 872515273944 |
| Dev | Miroir simplifie de Prod | 051370880327 |
| LogArchive | Centralisation des logs CloudTrail | 315466292610 |

> Le compte Prod heberge deux environnements Terraform isoles : `prod/` (workloads Phase 3) et `prod-ota/` (pipeline IoT OTA pour firmware ESP32-C5). Meme compte AWS, state files distincts. Voir [infrastructure/ota.md](../infrastructure/ota.md).

## Principes architecturaux

- **Zero-trust** : Tailscale comme overlay reseau, aucun port inbound sur les instances privees
- **Subnets prives** : 1 seul subnet public par VPC (NAT + web-site avec EIP)
- **Infrastructure as Code** : 100% Terraform, state distant S3 + DynamoDB
- **Dev-first** : tout est valide en Dev avant deploiement en Prod
- **Chiffrement partout** : EBS, S3 (SSE-KMS + TLS), RDS (KMS + TLS)

## Estimation des couts

| | Prod | Dev |
|---|---|---|
| **Total** | ~$221/mois | ~$84/mois |
| **Total combine** | **~$305/mois** | |
