# Vue d'ensemble de l'architecture

## Resume

Infrastructure AWS multi-compte pour Aromaestro utilisant une approche zero-trust avec Tailscale.

## Structure des comptes

| Compte | Role | ID |
|---|---|---|
| Management | Facturation, Organizations, IAM Identity Center, SCPs | *(a completer)* |
| Prod | Workloads de production, IoT, SES | *(compte Aromaestro existant)* |
| Dev | Miroir simplifie de Prod | *(a completer)* |
| LogArchive | Centralisation des logs CloudTrail | *(a completer)* |

## Principes architecturaux

- **Zero-trust** : Tailscale comme overlay reseau, aucun port inbound sur les instances
- **Subnets prives** : 1 seul subnet public par VPC (NAT uniquement)
- **Infrastructure as Code** : 100% Terraform, state distant S3 + DynamoDB
- **Dev-first** : tout est valide en Dev avant deploiement en Prod
- **Chiffrement partout** : EBS, S3 (SSE-S3 + TLS), RDS (KMS + TLS)

## Estimation des couts

| | Prod | Dev |
|---|---|---|
| **Total** | ~$221/mois | ~$84/mois |
| **Total combine** | **~$305/mois** | |
