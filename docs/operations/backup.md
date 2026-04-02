# Backups (AWS Backup)

## Politique de retention

### Dev

| Frequence | Heure | Retention |
|---|---|---|
| Quotidien | 2h AM EST (7h UTC) | 3 jours |

### Prod

| Frequence | Heure | Retention | Stockage |
|---|---|---|---|
| Quotidien | 2h AM EST | 7 jours | Standard |
| Hebdomadaire | Dimanche 2h AM | 4 semaines | Standard |
| Mensuel | 1er du mois 2h AM | 12 mois | Cold storage apres 30j |

## Selection des ressources

Basee sur les tags : toutes les ressources avec `Environment: development` ou `Environment: production`.

## RDS Point-in-Time Recovery (PITR)

En plus des snapshots quotidiens AWS Backup, RDS sauvegarde les transaction logs en continu (toutes les ~5 minutes). Ca permet de restaurer la base de donnees a **n'importe quelle seconde** dans la fenetre de retention.

- Dev : restauration possible a la seconde pres sur les 3 derniers jours
- Prod : restauration possible a la seconde pres sur les 7 derniers jours
- Inclus gratuitement avec RDS (actif des que backup_retention_period > 0)

Exemple de restauration a un point precis :
```bash
aws rds restore-db-instance-to-point-in-time \
  --source-db-instance-identifier aromaestro-development-mysql \
  --target-db-instance-identifier aromaestro-dev-mysql-restored \
  --restore-time "2026-04-02T14:31:59Z"
```

## RTO / RPO

| Metrique | Cible | Detail |
|---|---|---|
| **RPO** (perte de donnees max) | ~5 minutes | RDS Point-in-Time Recovery (transaction logs continus) |
| **RTO** (temps de retablissement) | 1 heure | Restauration depuis snapshot ou PITR |

Note : le RPO de 5 minutes s'applique a RDS. Pour les EC2 (fichiers locaux), le RPO est de 24 heures (snapshot quotidien AWS Backup).

## Vault

- Nom : `aromaestro-{env}-backup-vault`
- Chiffrement : KMS par defaut
