# Incident Response

## Niveaux de severite

| Niveau | Critere | Temps de reponse |
|---|---|---|
| P1 - Critique | Infra down, donnees a risque | Immediat |
| P2 - Majeur | Degradation service | < 4 heures |
| P3 - Mineur | Alarme non-critique | Prochain jour ouvrable |

## Procedure

### 1. Detection
- Alerte email via SNS (CloudWatch, GuardDuty, Inspector)
- Dashboard SecurityHub

### 2. Evaluation
- Identifier la ressource affectee
- Determiner la severite (P1/P2/P3)

### 3. Containment
- **Instance compromise** : modifier le Security Group pour couper tout trafic
- **Credentials compromises** : revoquer les cles IAM immediatement
- **S3 breach** : activer le deny all sur le bucket

### 4. Investigation
- CloudTrail : qui a fait quoi, quand
- CloudWatch Logs : logs applicatifs
- GuardDuty : detail du finding
- VPC Flow Logs : trafic reseau suspect

### 5. Remediation
- Corriger la vulnerabilite
- Patcher si necessaire
- Restaurer depuis backup si donnees corrompues

### 6. Post-mortem
- Documenter l'incident
- Identifier la cause racine
- Ajuster les controles pour prevenir la recurrence
