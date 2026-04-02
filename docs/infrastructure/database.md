# Base de donnees (RDS)

## Configuration

| Parametre | Dev | Prod (Phase 3) |
|---|---|---|
| Moteur | MySQL 8.0 | MySQL 8.0 |
| Instance | db.t4g.micro | db.t4g.small |
| Stockage | 20 GB gp3, auto-scaling 100 GB | 20 GB gp3, auto-scaling 100 GB |
| Multi-AZ | Non | Non (upgrade possible) |
| Backup | 1 jour | 7 jours |
| Chiffrement | KMS | KMS |
| TLS | require_secure_transport = ON | require_secure_transport = ON |
| Acces public | Non | Non |
| Username | admin | admin |
| Password | Gere par AWS (Secrets Manager) | Gere par AWS (Secrets Manager) |

## Acces

- Seulement depuis les instances EC2 (sg-web-app et sg-web-site-public -> sg-rds sur port 3306)
- Via Tailscale : se connecter a une instance EC2 puis `mysql -h <endpoint-rds> -u admin -p`
- Le mot de passe master est dans Secrets Manager (gere automatiquement par RDS)
- Aucune IP publique, aucun acces direct depuis internet

## Fenetre de maintenance

- Backup : 2h-3h AM EST (06:00-07:00 UTC)
- Maintenance : dimanche 3h-4h AM EST (07:00-08:00 UTC)
