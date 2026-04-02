# Backups (AWS Backup)

## Politique de retention

### Dev

| Frequence | Heure | Retention |
|---|---|---|
| Quotidien | 2h AM EST (7h UTC) | 3 jours |

### Prod (Phase 3)

| Frequence | Heure | Retention | Stockage |
|---|---|---|---|
| Quotidien | 2h AM EST | 7 jours | Standard |
| Hebdomadaire | Dimanche 2h AM | 4 semaines | Standard |
| Mensuel | 1er du mois 2h AM | 12 mois | Cold storage apres 30j |

## Selection des ressources

Basee sur les tags : toutes les ressources avec `Environment: development` ou `Environment: production`.

## RTO / RPO

| Metrique | Cible |
|---|---|
| RPO | 24 heures (backup quotidien) |
| RTO | 1 heure |

## Vault

- Nom : `aromaestro-{env}-backup-vault`
- Chiffrement : KMS par defaut
