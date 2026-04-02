# Monitoring et Alertes

## CloudWatch Alarmes

### EC2 (par instance)

| Metrique | Seuil | Evaluation | Action |
|---|---|---|---|
| CPUUtilization | > 80% | 3x 5min | SNS alert |
| StatusCheckFailed_System | >= 1 | 2x 1min | SNS alert + auto-recovery |
| mem_used_percent | > 85% | 2x 5min | SNS alert |
| disk_used_percent | > 80% | 2x 5min | SNS alert |

### RDS

| Metrique | Seuil | Evaluation |
|---|---|---|
| CPUUtilization | > 80% | 3x 5min |
| DatabaseConnections | > 50 (~80% max) | 2x 5min |
| FreeStorageSpace | < 4 GB | 1x 5min |
| FreeableMemory | < 128 MB | 2x 5min |
| ReadLatency | > 20ms | 2x 5min |
| WriteLatency | > 20ms | 2x 5min |

### NAT Instance (dev)

| Metrique | Seuil | Action |
|---|---|---|
| StatusCheckFailed_System | >= 1 | Auto-recovery |

## EventBridge

| Regle | Source | Filtre | Destination |
|---|---|---|---|
| guardduty-findings | GuardDuty | Severity >= 7 (HIGH/CRITICAL) | SNS |
| inspector-findings | Inspector | HIGH/CRITICAL | SNS |

## Notifications

- Topic SNS : `aromaestro-{env}-alerts`
- Chiffrement : KMS (alias/aws/sns)
- Protocole : email

## CloudWatch Agent

Installe sur chaque EC2, collecte :
- `mem_used_percent` (namespace CWAgent)
- `disk_used_percent` (namespace CWAgent, path `/`)

Config stockee dans SSM Parameter Store : `/{project}/{env}/cloudwatch-agent-config`
