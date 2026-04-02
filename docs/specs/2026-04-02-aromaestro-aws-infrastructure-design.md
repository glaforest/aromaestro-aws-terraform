# Aromaestro - AWS Infrastructure Design

**Date:** 2026-04-02
**Status:** Approved (rev.2 - post-audit)
**Reference:** Documentation AWS KPMG (Solist) - used as baseline
**Deployment order:** Dev first, then Prod

---

## 1. Overview

Infrastructure AWS multi-compte pour Aromaestro, suivant les bonnes pratiques inspirees de l'implementation KPMG/Solist mais simplifiee et adaptee :

- Approche zero-trust avec Tailscale (pas de VPN AWS ni de Network Firewall)
- Aucun port expose a internet sur les instances
- Subnets prives + 1 subnet public minimal (NAT uniquement) par VPC
- Terraform pour l'Infrastructure as Code (state distant S3 + DynamoDB)
- Region : ca-central-1 (Canada)

---

## 2. Structure des comptes

```
AWS Organizations
+-- Management account (nouveau, email dedie)
|   +-- Facturation, Organizations, IAM Identity Center
|   +-- Terraform state backend (S3 + DynamoDB)
|   +-- SCPs (guardrails organisationnels)
|   +-- Aucun workload
+-- Prod account (= compte Aromaestro existant)
|   +-- Toutes les ressources de production
|   +-- AWS IoT (deja configure, on preserve)
|   +-- SES (deja configure, on preserve)
|   +-- S3 buckets existants (import Terraform)
+-- Dev account (nouveau, cree depuis Organizations)
|   +-- Miroir simplifie de Prod
+-- LogArchive account (nouveau)
    +-- CloudTrail logs (tous les comptes)
    +-- Bucket isole, non modifiable par les comptes workload
```

### SCPs (Service Control Policies)

Appliquees au niveau de l'Organisation :

| SCP | Role |
|---|---|
| Region Deny | Restreint les operations a ca-central-1 uniquement |
| Deny Root Account Usage | Empeche l'utilisation du root user sur les comptes membres |
| Protect CloudTrail | Empeche la desactivation/modification de CloudTrail |
| Protect Config | Empeche la desactivation/modification de Config |
| Protect GuardDuty | Empeche la desactivation de GuardDuty |
| Deny S3 Public Access | Empeche la creation de buckets publics |

### Ressources existantes a importer (compte Aromaestro/Prod)

- AWS IoT (on y touche pas)
- SES (on y touche pas)
- S3 : `aromaestro-backups`, `aromaestro-diffuser-ota`, `aromaestro-ota`
- EC2 instances existantes (a evaluer)
- IAM users/roles existants
- VPC par defaut (on ne l'utilise pas, on cree un nouveau VPC)

---

## 3. Reseau

### VPC Prod (10.0.0.0/16) - ca-central-1

| Subnet | Type | CIDR | AZ | Role |
|---|---|---|---|---|
| public-nat-a | **Public** | 10.0.100.0/24 | ca-central-1a | NAT Gateway + Internet Gateway |
| private-app-a | Prive | 10.0.1.0/24 | ca-central-1a | EC2 serveurs web + Tailscale |
| private-app-b | Prive | 10.0.2.0/24 | ca-central-1b | Redundance AZ (pas utilise au debut) |
| private-data-a | Prive | 10.0.10.0/24 | ca-central-1a | RDS primary |
| private-data-b | Prive | 10.0.11.0/24 | ca-central-1b | RDS (2e AZ requise pour DB subnet group) |

### VPC Dev (10.1.0.0/16) - ca-central-1

| Subnet | Type | CIDR | AZ | Role |
|---|---|---|---|---|
| public-nat-a | **Public** | 10.1.100.0/24 | ca-central-1a | NAT instance (t4g.nano) |
| private-app-a | Prive | 10.1.1.0/24 | ca-central-1a | EC2 serveurs web + Tailscale |
| private-data-a | Prive | 10.1.10.0/24 | ca-central-1a | RDS |
| private-data-b | Prive | 10.1.11.0/24 | ca-central-1b | RDS (2e AZ requise) |

### Route Tables

**Route table publique** (public-nat-a) :
- `10.x.0.0/16 -> local`
- `0.0.0.0/0 -> igw-xxx` (Internet Gateway)

**Route table privee** (tous les subnets prives) :
- `10.x.0.0/16 -> local`
- `0.0.0.0/0 -> nat-gw-xxx` (NAT Gateway/instance)
- `s3 prefix list -> vpce-xxx` (VPC Endpoint S3)

### VPC Endpoints

| Endpoint | Type | Cout | Raison |
|---|---|---|---|
| S3 | Gateway | Gratuit | Evite le NAT pour l'acces S3 |
| SSM | Interface | ~$7/mo | Requis pour SSM Session Manager en subnet prive |
| SSMMessages | Interface | ~$7/mo | Requis pour SSM Session Manager |
| EC2Messages | Interface | ~$7/mo | Requis pour SSM Session Manager |

Note : En dev, on peut utiliser SSM via le NAT au lieu des endpoints Interface pour economiser ~$21/mois.

### VPC DNS

- `enableDnsSupport: true`
- `enableDnsHostnames: true`
- DNS externe : a definir (Cloudflare ou Route 53)
- VPC resolver : 10.0.0.2 (prod), 10.1.0.2 (dev)

### VPC Flow Logs

- Active sur chaque VPC
- Destination : bucket logs S3 (`aromaestro-{env}-logs`)
- Format : version 5 (inclut vpc-id, subnet-id, instance-id)
- Trafic capture : ALL (accept + reject)

### Network ACLs

Default (allow all). La securite est enforced au niveau des Security Groups.
Choix delibere : les NACLs stateless ajoutent de la complexite sans valeur ajoutee vu que tous les subnets app/data sont prives avec des SGs stricts.

### Acces reseau

- 1 subnet public minimal (NAT seulement, aucune instance)
- NAT Gateway (prod) / NAT instance (dev) pour le trafic sortant
- Tailscale pour tout acces entrant aux instances
- SSM Session Manager en fallback (via VPC Endpoints en prod, via NAT en dev)
- VPCs non peeres (isolation complete prod/dev)

---

## 4. Compute (EC2)

### Prod - 4 instances (subnet private-app-a)

| Nom | Role | Taille | OS |
|---|---|---|---|
| web-site | Site internet Aromaestro | t4g.small | Ubuntu 24.04 (ARM) |
| web-admin | Admin Laravel | t4g.small | Ubuntu 24.04 (ARM) |
| web-wordpress | WordPress | t4g.small | Ubuntu 24.04 (ARM) |
| web-openclaw | Open Claw | t4g.small | Ubuntu 24.04 (ARM) |

### Dev - 4 instances (miroir en t4g.micro)

Meme structure, tailles reduites.

Note : t4g (Graviton/ARM) au lieu de t3 (x86) pour ~20% d'economies. Ubuntu 24.04 supporte ARM nativement.

### Configuration commune

- **Tailscale** installe au boot (user_data script), auth key dans AWS Secrets Manager
- **CloudWatch Agent** installe au boot (user_data script) pour metriques memoire/disque
- **SSM Agent** active (acces fallback)
- Aucune IP publique
- EBS chiffre par defaut
- Tags obligatoires (voir section Tagging)

### Security Groups

**sg-web-app :**
- Inbound : RIEN (zero ports ouverts)
- Outbound :
  - TCP 443 vers 0.0.0.0/0 (HTTPS - APIs AWS, updates, DERP relay Tailscale)
  - TCP 80 vers 0.0.0.0/0 (HTTP - package managers apt)
  - UDP 41641 vers 0.0.0.0/0 (Tailscale direct WireGuard - evite les relays)
  - TCP 3306 vers sg-rds (MySQL)
  - UDP/TCP 53 vers VPC CIDR (DNS resolution)

**sg-rds :**
- Inbound : TCP 3306 depuis sg-web-app seulement
- Outbound : RIEN

**sg-nat-instance (dev seulement) :**
- Inbound : ALL traffic depuis subnets prives (10.1.0.0/16)
- Outbound : ALL traffic vers 0.0.0.0/0

**sg-vpc-endpoints (prod seulement) :**
- Inbound : TCP 443 depuis VPC CIDR
- Outbound : RIEN

---

## 5. Base de donnees (RDS)

### Prod

| Parametre | Valeur |
|---|---|
| Moteur | MySQL 8.0 |
| Taille | db.t4g.small (Graviton) |
| Stockage | 20 GB gp3, auto-scaling jusqu'a 100 GB |
| Multi-AZ | Non (pour commencer, upgrade facile) |
| Backup automatique | 7 jours retention |
| Chiffrement | KMS par defaut |
| Acces | Subnet prive, sg-rds seulement |
| TLS | `require_secure_transport = ON` |

### Dev

Meme config mais db.t4g.micro, backup 1 jour, single-AZ.

### Organisation des bases

Une seule instance RDS par environnement, databases separees :
- `db_site`
- `db_admin`
- `db_wordpress`
- `db_openclaw`

---

## 6. Stockage S3

### Buckets existants (import Terraform)

| Bucket | Usage | Modifications |
|---|---|---|
| aromaestro-backups | Backups manuels | Object Lock mode Compliance, retention 30j, versioning |
| aromaestro-diffuser-ota | OTA firmware diffuseurs (IoT) | Aucune |
| aromaestro-ota | OTA firmware | Aucune |

### Nouveaux buckets

| Bucket | Env | Usage | Config |
|---|---|---|---|
| aromaestro-prod-assets | Prod | Fichiers statiques apps web | SSE-S3, versioning |
| aromaestro-prod-logs | Prod | CloudTrail, VPC Flow Logs | SSE-S3, lifecycle 90j |
| aromaestro-dev-assets | Dev | Miroir dev | SSE-S3, versioning |
| aromaestro-dev-logs | Dev | Logs dev | SSE-S3, lifecycle 90j |
| aromaestro-logarchive | LogArchive | CloudTrail centralise | SSE-S3, versioning, bucket policy deny delete |

### Securite commune

- Block Public Access sur tous les buckets
- Bucket policy : deny `aws:SecureTransport = false` (force TLS)
- Lifecycle rules sur les buckets logs (suppression 90 jours)
- Lifecycle sur aromaestro-backups : transition Glacier apres 30 jours

---

## 7. Securite

### Services AWS (Prod + Dev)

| Service | Role |
|---|---|
| GuardDuty | Detection de menaces |
| Inspector | Scan de vulnerabilites EC2 |
| SecurityHub | Dashboard centralise securite |
| CloudTrail | Journal d'audit (logs vers LogArchive account) |
| Config | Suivi conformite des ressources |

### Config Rules

| Regle | Description |
|---|---|
| required-tags | Force les tags obligatoires sur les ressources |
| ebs-encryption-by-default | Verifie que le chiffrement EBS est active |
| s3-bucket-public-read-prohibited | Detecte les buckets publics |
| rds-storage-encrypted | Verifie le chiffrement RDS |
| restricted-ssh | Detecte les SGs avec SSH ouvert a 0.0.0.0/0 |

### IAM - Identity Center (SSO)

| Role | Permissions | Usage |
|---|---|---|
| Admin | Full access prod + dev | Administrateur |
| Developer | Full access dev, read-only prod | Developpeurs |
| Emergency | Break-glass full access | Urgences seulement (audite) |

- **MFA obligatoire** sur tous les utilisateurs Identity Center
- **Break-glass procedure** : compte emergency avec MFA hardware, usage audite via CloudTrail

### Chiffrement

- EBS : chiffrement par defaut au niveau du compte
- S3 : SSE-S3 sur tous les buckets, TLS enforce via bucket policy
- RDS : chiffrement KMS, `require_secure_transport = ON`

### Patching

- SSM Patch Manager : scan + install automatique
- Fenetre de maintenance : dimanche 3h00 AM (prod et dev)
- Reboot automatique inclus

---

## 8. Backups (AWS Backup)

### Prod (tag `Environment: production`)

| Frequence | Heure | Retention | Stockage |
|---|---|---|---|
| Quotidien | 2h AM | 7 jours | Standard |
| Hebdomadaire | Dimanche | 4 semaines | Standard |
| Mensuel | 1er du mois | 12 mois | Cold storage apres 30j |

### Dev (tag `Environment: development`)

| Frequence | Heure | Retention | Stockage |
|---|---|---|---|
| Quotidien | 2h AM | 3 jours | Standard |

### RTO / RPO

| Metrique | Cible |
|---|---|
| **RPO** (perte de donnees max) | 24 heures (backup quotidien a 2h AM) |
| **RTO** (temps de retablissement max) | 1 heure |

---

## 9. Monitoring et Alertes

### CloudWatch Agent (installe sur chaque EC2)

Metriques collectees :
- `mem_used_percent` (memoire)
- `disk_used_percent` (disque, path `/`)
- Namespace : `CWAgent`

### CloudWatch Alarmes

**Par instance EC2 :**

| Metrique | Seuil | Evaluation | Source |
|---|---|---|---|
| CPUUtilization | > 80% | 3 periodes de 5 min | AWS/EC2 |
| StatusCheckFailed_System | >= 1 | 2 periodes de 1 min | AWS/EC2 (auto-recovery action) |
| mem_used_percent | > 85% | 2 periodes de 5 min | CWAgent |
| disk_used_percent | > 80% | 2 periodes de 5 min | CWAgent |

**RDS :**

| Metrique | Seuil | Evaluation |
|---|---|---|
| CPUUtilization | > 80% | 3 periodes de 5 min |
| DatabaseConnections | > 80% du max | 2 periodes de 5 min |
| FreeStorageSpace | < 4 GB | 1 periode de 5 min |
| FreeableMemory | < 128 MB | 2 periodes de 5 min |
| ReadLatency | > 20 ms | 2 periodes de 5 min |
| WriteLatency | > 20 ms | 2 periodes de 5 min |

**NAT instance (dev) :**

| Metrique | Seuil | Action |
|---|---|---|
| StatusCheckFailed_System | >= 1 | Auto-recovery |

### Alertes

**EventBridge Rules :**

| Regle | Source | Filtre | Destination |
|---|---|---|---|
| guardduty-findings | GuardDuty | Severity HIGH/CRITICAL | SNS aromaestro-alerts |
| inspector-findings | Inspector | Severity HIGH/CRITICAL | SNS aromaestro-alerts |

**SNS Topics :**
- `aromaestro-alerts` : notifications par email

### Incident Response

**Severite :**

| Niveau | Critere | Action |
|---|---|---|
| P1 - Critique | Infra down, donnees a risque | Intervention immediate |
| P2 - Majeur | Degradation service | Intervention < 4h |
| P3 - Mineur | Alarme non-critique | Next business day |

**Procedure de base :**
1. Recevoir l'alerte (email SNS)
2. Evaluer la severite
3. Containment : isoler la ressource (modifier le SG pour couper le trafic)
4. Investigation : CloudTrail, CloudWatch Logs, GuardDuty findings
5. Remediation : corriger le probleme
6. Post-mortem : documenter et ajuster les controles

---

## 10. Disaster Recovery

### Strategie : Backup & Restore

| Element | Methode | RTO estime |
|---|---|---|
| EC2 | AMI via AWS Backup | ~30 min |
| RDS | Snapshot automatique | ~15 min |
| S3 | Versioning (protege nativement) | Immediat |
| Infra | Re-deploy via Terraform | ~15 min |

### Procedure

1. `terraform apply` dans une autre AZ ou region (variable parametrable)
2. Restaurer RDS depuis le dernier snapshot
3. Restaurer EC2 depuis les AMI
4. Tailscale se reconnecte automatiquement

### Validation

- Test de restauration trimestriel (snapshot RDS -> instance temporaire)
- Documenter les temps reels de restauration

### Hors scope (pour l'instant)

- Pas de replication cross-region
- Pas de multi-AZ actif-actif

---

## 11. Terraform - Structure des modules

```
terraform/
+-- backend/               # S3 bucket + DynamoDB table pour le state (bootstrap)
+-- modules/
|   +-- vpc/               # VPC, subnets, route tables, NAT, IGW, Flow Logs
|   +-- vpc-endpoints/     # Gateway (S3) et Interface (SSM) endpoints
|   +-- ec2/               # Instances, security groups, user_data (Tailscale + CW Agent)
|   +-- rds/               # RDS instance, DB subnet group, security group, parameter group
|   +-- s3/                # Buckets, policies, lifecycle rules, encryption
|   +-- backup/            # AWS Backup vault, plans, selections
|   +-- security/          # GuardDuty, Inspector, SecurityHub, CloudTrail, Config
|   +-- monitoring/        # CloudWatch alarmes, SNS topics, EventBridge rules
|   +-- iam/               # Identity Center, roles, policies
|   +-- patching/          # SSM Patch Manager, maintenance windows
|   +-- budgets/           # AWS Budgets, Cost Anomaly Detection
|   +-- organizations/     # Organizations, SCPs, accounts
+-- environments/
|   +-- management/        # Compte Management (Organizations, Identity Center, state backend)
|   +-- logarchive/        # Compte LogArchive (bucket centralise)
|   +-- dev/               # Compte Dev (deploye en premier)
|   +-- prod/              # Compte Prod (deploye apres validation dev)
+-- imports/               # Import des ressources existantes (S3, SES, IoT refs)
```

### State Backend

- S3 bucket dans le Management account : `aromaestro-terraform-state`
- DynamoDB table : `aromaestro-terraform-locks`
- Un state file par environnement (key: `env/{env}/terraform.tfstate`)
- Versioning active sur le bucket

---

## 12. Tagging Strategy

### Tags obligatoires (toutes les ressources)

| Tag | Valeurs | Usage |
|---|---|---|
| Environment | production, development | Backup selection, patching, cost tracking |
| Application | site, admin, wordpress, openclaw, shared | Cost attribution par app |
| ManagedBy | terraform | Distinguer les ressources IaC vs manuelles |
| Owner | aromaestro | Identification |

### Enforcement

- AWS Config rule `required-tags` pour detecter les ressources non taguees
- Terraform locals avec tags par defaut herites par tous les modules

---

## 13. Cost Governance

### AWS Budgets

| Budget | Montant | Alertes |
|---|---|---|
| Total mensuel | $350 | 80% ($280) et 100% ($350) |

- Alerte par email via SNS
- Cost Anomaly Detection active sur le Management account

### Optimisations prevues

| Optimisation | Economies estimees | Phase |
|---|---|---|
| t4g Graviton (au lieu de t3) | ~$23/mois | Phase 1 (inclus) |
| VPC Endpoints S3 | ~$8/mois NAT data | Phase 1 (inclus) |
| Dev instance scheduling (8h-19h semaine) | ~$37/mois | Phase 2 |
| Cold storage backups mensuels | ~$6/mois | Phase 1 (inclus) |
| Compute Savings Plans | ~$40/mois | Phase 2 (apres 1 mois de baseline) |

### Estimation couts mensuels

| | Prod | Dev |
|---|---|---|
| EC2 (4x t4g.small / t4g.micro) | $60 | $24 |
| RDS (db.t4g.small / t4g.micro) | $35 | $18 |
| NAT Gateway / NAT instance | $45 | $4 |
| VPC Endpoints (SSM) | $21 | $0 |
| EBS (4x 20GB gp3) | $13 | $13 |
| S3 | $5 | $2 |
| AWS Backup | $12 | $3 |
| Security stack | $20 | $15 |
| CloudWatch | $10 | $5 |
| **Total** | **~$221** | **~$84** |
| **Total combine** | **~$305/mois** | |

---

## 14. Decisions et compromis

| Decision | Raison |
|---|---|
| Pas de LZA/Control Tower | Trop complexe pour 4 comptes, SCPs manuels via Terraform suffisants |
| Tailscale au lieu de AWS Client VPN | Plus simple, zero-trust, pas de config reseau complexe |
| Security Groups au lieu de Network Firewall | Suffisant avec zero ports inbound + Tailscale |
| NAT instance en dev | Economie ~$40/mois vs NAT Gateway |
| SSM via NAT en dev (pas de VPC Endpoints) | Economie ~$21/mois, SSM est un fallback |
| RDS single-AZ | Suffisant pour commencer, upgrade facile vers multi-AZ |
| 1 seul RDS par env | 4 databases separees, pas besoin de 4 instances |
| Patching automatique | Workloads web standard, reboot dimanche 3h AM acceptable |
| t4g Graviton | ~20% moins cher que t3, Ubuntu ARM supporte nativement |
| LogArchive account | Isolation des logs d'audit - un compte compromis ne peut pas effacer ses traces |
| Dev-first deployment | Valider l'infra en dev avant de deployer en prod |

---

## 15. Deployment Order

### Phase 1 : Fondation
1. Creer le Management account
2. Configurer AWS Organizations
3. Creer le Dev account et LogArchive account
4. Deployer le Terraform state backend (S3 + DynamoDB)
5. Configurer IAM Identity Center + MFA
6. Deployer les SCPs

### Phase 2 : Dev Environment
7. Deployer VPC Dev (subnets, route tables, NAT instance, Flow Logs)
8. Deployer les Security Groups
9. Deployer les EC2 Dev (avec Tailscale + CloudWatch Agent)
10. Deployer RDS Dev
11. Deployer S3 buckets Dev
12. Configurer securite (GuardDuty, Inspector, SecurityHub, CloudTrail, Config)
13. Configurer monitoring (CloudWatch alarmes, SNS, EventBridge)
14. Configurer backup + patching
15. Valider l'ensemble en Dev

### Phase 3 : Prod Environment
16. Inviter le compte Aromaestro dans l'Organisation
17. Importer les ressources existantes dans Terraform
18. Deployer VPC Prod (subnets, route tables, NAT GW, VPC Endpoints, Flow Logs)
19. Deployer les EC2 Prod + RDS Prod
20. Deployer S3 buckets Prod + logs
21. Configurer securite + monitoring + backup + patching
22. Migration des workloads vers le nouveau VPC

### Phase 4 : Optimisations
23. Dev instance scheduling
24. Compute Savings Plans (apres 1 mois de baseline)
25. Test DR trimestriel
