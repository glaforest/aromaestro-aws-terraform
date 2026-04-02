# Aromaestro - Presentation de l'infrastructure AWS

Document de presentation pour revue KPMG.

---

## 1. Vue d'ensemble

Aromaestro a deploye une infrastructure AWS multi-compte suivant les bonnes pratiques de l'industrie et le AWS Well-Architected Framework.

L'infrastructure est entierement geree par **Infrastructure as Code** (Terraform), documentee, auditee et conforme aux standards CIS AWS Foundations Benchmark.

**Region :** ca-central-1 (Canada - donnees residentes au Canada)
**Approche reseau :** Zero-trust avec Tailscale (aucun port SSH ouvert)
**Environnements :** Dev (deploye), Prod (code pret)

---

## 2. Structure des comptes

L'infrastructure utilise AWS Organizations avec une separation stricte des responsabilites :

| Compte | Role | Account ID |
|---|---|---|
| **Management** | Facturation, Organizations, SCPs, Budgets, Terraform state | 589389426408 |
| **Dev** | Environnement de developpement | 051370880327 |
| **Prod** | Production, IoT, SES | 872515273944 |
| **LogArchive** | Centralisation des logs d'audit | 315466292610 |

**Pourquoi cette structure :**
- Isolation par compte : un incident dans un compte ne peut pas affecter les autres
- Facturation separee par environnement
- Le Management account ne contient aucun workload (bonne pratique AWS)
- Les logs d'audit sont isoles dans un compte dedie pour empecher la falsification

---

## 3. Controles d'acces

### IAM Identity Center (SSO)

Tous les acces humains passent par **IAM Identity Center** avec :
- **MFA obligatoire** sur tous les utilisateurs
- **Roles bases sur les responsabilites** : Admin (tous les comptes), Developer (dev complet, prod lecture seule), Emergency (break-glass audite)
- **Sessions temporaires** : pas de cles d'acces statiques, les credentials expirent automatiquement
- **Un seul point d'entree** pour tous les comptes

### Service Control Policies (SCPs)

6 guardrails appliques au niveau de l'Organisation entiere :

| Guardrail | Protection |
|---|---|
| **Region Deny** | Toutes les operations restreintes a ca-central-1 (donnees au Canada) |
| **Deny Root User** | Le compte root ne peut pas etre utilise sur les comptes membres |
| **Protect CloudTrail** | Impossible de supprimer ou arreter le journal d'audit |
| **Protect Config** | Impossible de supprimer le suivi de conformite |
| **Protect GuardDuty** | Impossible de desactiver la detection de menaces |
| **Deny S3 Public** | Impossible de rendre un bucket S3 public |

Ces guardrails s'appliquent meme si un utilisateur a les permissions administrateur. C'est une couche de protection au-dessus de l'IAM.

---

## 4. Architecture reseau

### Approche zero-trust

Contrairement a une architecture traditionnelle avec VPN et pare-feu, Aromaestro utilise une approche **zero-trust** :

- **Aucun port SSH (22) ouvert** sur aucune instance
- **Aucun port d'administration expose** a internet
- L'acces aux serveurs se fait exclusivement via **Tailscale** (mesh VPN chiffre WireGuard) ou **AWS SSM Session Manager**
- Seul le site web (port 80/443) est accessible depuis internet

### Segmentation reseau

Chaque environnement a son propre VPC isole (non-connecte aux autres) :

```
VPC Dev (10.1.0.0/16)
|
+-- Subnet public (10.1.100.0/24)
|   +-- NAT instance (trafic sortant uniquement)
|   +-- web-site (seule instance exposee, ports 80/443)
|
+-- Subnet prive app (10.1.1.0/24)
|   +-- web-admin (zero ports ouverts)
|   +-- web-wordpress (zero ports ouverts)
|   +-- web-openclaw (zero ports ouverts)
|
+-- Subnets prives data (10.1.10.0/24, 10.1.11.0/24)
    +-- RDS MySQL (accessible seulement depuis les EC2)
```

**Principe :** les serveurs dans les subnets prives peuvent sortir vers internet (via le NAT) mais personne ne peut entrer. L'acces se fait uniquement via Tailscale.

### Security Groups

| Security Group | Inbound | Outbound |
|---|---|---|
| sg-web-app (serveurs prives) | **Rien** | HTTPS, HTTP, Tailscale, MySQL, DNS, ICMP |
| sg-web-site-public (site web) | HTTP (80), HTTPS (443) | HTTPS, HTTP, Tailscale, MySQL, DNS, ICMP |
| sg-rds (base de donnees) | MySQL (3306) depuis EC2 seulement | Rien |
| sg-default (par defaut du VPC) | **Rien** (restreint, CIS 5.4) | **Rien** |

---

## 5. Chiffrement

### Au repos

| Ressource | Methode |
|---|---|
| Volumes EBS (disques EC2) | Chiffrement par defaut au niveau du compte (KMS) |
| S3 (fichiers) | SSE-KMS ou AES256 selon le bucket |
| RDS (base de donnees) | KMS |
| SNS (alertes) | KMS (alias/aws/sns) |
| Terraform state | SSE-KMS |

### En transit

| Connexion | Methode |
|---|---|
| Acces aux serveurs | Tailscale (WireGuard, chiffrement bout-en-bout) |
| S3 | TLS enforce via bucket policy (non-TLS rejete) |
| RDS | TLS obligatoire (`require_secure_transport = ON`) |
| SSM Session Manager | TLS |
| Toutes les API AWS | HTTPS (TLS 1.2+) |

---

## 6. Detection et surveillance

### Services de detection

| Service | Role | Status |
|---|---|---|
| **GuardDuty** | Detection de menaces en temps reel (comportements suspects, tentatives d'intrusion) | Actif, protege par SCP |
| **Inspector** | Scan automatique de vulnerabilites sur les EC2 (CVEs, paquets obsoletes) | Actif |
| **SecurityHub** | Dashboard centralise de tous les findings de securite, evalue contre le standard AWS Foundational Security Best Practices | Actif |
| **CloudTrail** | Journal d'audit complet de toutes les actions API (qui a fait quoi, quand) | Actif, multi-region, validation des fichiers activee |
| **Config** | Suivi continu de la conformite des ressources | Actif, 4 regles |

### Regles de conformite Config

| Regle | Verifie que... |
|---|---|
| ebs-encryption-by-default | Le chiffrement EBS est active par defaut |
| s3-bucket-public-read-prohibited | Aucun bucket S3 n'est public |
| rds-storage-encrypted | La base de donnees est chiffree |
| restricted-ssh | Aucun security group n'a SSH ouvert a 0.0.0.0/0 |

### Alertes automatiques

| Evenement | Acheminement | Notification |
|---|---|---|
| GuardDuty finding HIGH/CRITICAL | EventBridge -> SNS | Email |
| Inspector finding HIGH/CRITICAL | EventBridge -> SNS | Email |
| EC2 CPU > 80% | CloudWatch -> SNS | Email |
| EC2 instance down | CloudWatch -> SNS + auto-recovery | Email + redemarrage auto |
| EC2 memoire > 85% | CloudWatch -> SNS | Email |
| EC2 disque > 80% | CloudWatch -> SNS | Email |
| RDS CPU/memoire/stockage/latence | CloudWatch -> SNS | Email |
| Budget depasse 80% ou 100% | AWS Budgets | Email |
| Anomalie de couts > $20 | Cost Anomaly Detection | Email |

### VPC Flow Logs

Tout le trafic reseau (accepte et rejete) est journalise vers S3 pour analyse forensique en cas d'incident.

---

## 7. Protection des instances

### IMDSv2 (Instance Metadata Service v2)

Toutes les instances EC2 forcent **IMDSv2** (`http_tokens = required`), ce qui empeche les attaques SSRF contre le service de metadonnees. C'est une exigence du CIS Benchmark (EC2.8).

### Patching automatique

- **SSM Patch Manager** scanne et installe automatiquement les correctifs de securite
- **Fenetre de maintenance** : dimanche 3h00 AM EST
- **Priorite** : patches Required et Important
- **Reboot automatique** si necessaire

### Acces aux instances

1. **Tailscale** (principal) : mesh VPN zero-trust, chiffre WireGuard
2. **SSM Session Manager** (fallback) : acces via la console AWS, audite dans CloudTrail
3. **Aucun acces SSH direct** : pas de port 22 ouvert, pas de cles SSH

---

## 8. Sauvegarde et reprise apres sinistre

### Politique de sauvegarde (AWS Backup)

| | Dev | Prod |
|---|---|---|
| Quotidien | 3 jours de retention | 7 jours |
| Hebdomadaire | - | 4 semaines |
| Mensuel | - | 12 mois (cold storage apres 30j) |

Les sauvegardes sont selectionnees automatiquement via les tags (`Environment`). Toute nouvelle ressource taguee est automatiquement protegee.

### RDS Point-in-Time Recovery

En plus des snapshots quotidiens, RDS sauvegarde les transaction logs en continu (~5 minutes). Ca permet de restaurer la base de donnees a **n'importe quelle seconde** dans la fenetre de retention (3 jours en dev, 7 jours en prod). Inclus gratuitement.

### Objectifs de reprise

| Metrique | Cible | Detail |
|---|---|---|
| **RPO** (perte de donnees maximale) | ~5 minutes (RDS) | Point-in-Time Recovery via transaction logs |
| **RPO** (fichiers EC2) | 24 heures | Snapshot quotidien AWS Backup |
| **RTO** (temps de retablissement) | 1 heure | Restauration depuis snapshot ou PITR |

### Procedure de reprise

L'infrastructure est 100% codifiee en Terraform. En cas de sinistre :
1. `terraform apply` recree toute l'infrastructure dans une autre AZ ou region
2. Restaurer la base de donnees depuis le dernier snapshot RDS
3. Tailscale se reconnecte automatiquement (pas de reconfiguration reseau)

---

## 9. Infrastructure as Code

### Terraform

- **100% de l'infrastructure** est definie en code (Terraform)
- **State distant** : stocke dans un bucket S3 chiffre et versionne dans le Management account, avec verrouillage DynamoDB pour empecher les modifications concurrentes
- **Modules reutilisables** : les memes modules sont utilises pour Dev et Prod, garantissant la coherence
- **Revue des changements** : `terraform plan` montre exactement ce qui va changer avant application

### Gestion du code

- **Repository Git** : tout le code et la documentation sont dans un repo Git
- **Historique complet** : chaque changement est trace avec date, auteur et description
- **Documentation integree** : la documentation technique vit a cote du code et est mise a jour a chaque changement

---

## 10. Gouvernance des couts

### Budget

- Budget mensuel : **$350 USD**
- Alertes a **80%** ($280) et **100%** ($350)
- **Cost Anomaly Detection** : detecte automatiquement les depenses anormales (seuil $20)

### Estimation des couts

| | Dev | Prod |
|---|---|---|
| EC2 (serveurs) | $28 | $60 |
| RDS (base de donnees) | $18 | $35 |
| Reseau (NAT) | $4 | $45 |
| Stockage (S3, EBS) | $14 | $18 |
| Securite et monitoring | $20 | $20 |
| **Total** | **~$84/mois** | **~$221/mois** |

### Optimisations appliquees

- **Graviton (ARM)** : instances t4g ~20% moins cheres que x86
- **NAT instance en dev** : ~$4/mois vs $45/mois pour un NAT Gateway
- **VPC Endpoint S3** : gratuit, evite les frais de transfert NAT pour l'acces S3

---

## 11. Conformite

### CIS AWS Foundations Benchmark

L'infrastructure a ete auditee contre le CIS AWS Foundations Benchmark. Resultat : **32/32 controles adresses**.

| Domaine | Status |
|---|---|
| IAM (MFA, root deny, least privilege) | Conforme |
| Logging (CloudTrail, VPC Flow Logs, Config) | Conforme |
| Monitoring (CloudWatch, alertes securite) | Conforme |
| Networking (pas de SSH ouvert, VPC endpoints) | Conforme |
| Storage (chiffrement, TLS, pas de public access) | Conforme |

---

## 12. Documentation

Toute la documentation technique est disponible dans le repository Git :

| Document | Contenu |
|---|---|
| [README.md](README.md) | Index principal avec liens vers toutes les sections |
| [getting-started.md](getting-started.md) | Guide complet pour nouvel ordinateur et deploiement |
| [architecture/](architecture/) | Comptes, reseau, vue d'ensemble |
| [infrastructure/](infrastructure/) | EC2, RDS, S3 |
| [security/](security/) | SCPs, IAM, chiffrement |
| [operations/](operations/) | Monitoring, backup, patching |
| [runbooks/](runbooks/) | Procedures de restauration et incident response |

---

## 13. Points de contact

| Role | Responsable |
|---|---|
| Administrateur AWS | *(a completer)* |
| Contact securite | *(a completer)* |
| Repository | github.com/glaforest/aromaestro-aws-terraform |
