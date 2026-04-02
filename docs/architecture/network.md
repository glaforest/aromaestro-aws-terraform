# Architecture reseau

## VPC

Chaque environnement (Prod, Dev) dispose de son propre VPC isole.

| VPC | CIDR | Region |
|---|---|---|
| Prod | 10.0.0.0/16 | ca-central-1 |
| Dev | 10.1.0.0/16 | ca-central-1 |

Les VPCs ne sont pas peeres (isolation complete).

## Subnets

### Dev

| Subnet | Type | CIDR | AZ | Role |
|---|---|---|---|---|
| public-nat-a | Public | 10.1.100.0/24 | ca-central-1a | NAT instance + web-site (EIP) |
| private-app-a | Prive | 10.1.1.0/24 | ca-central-1a | EC2 serveurs web prives |
| private-data-a | Prive | 10.1.10.0/24 | ca-central-1a | RDS |
| private-data-b | Prive | 10.1.11.0/24 | ca-central-1b | RDS (2e AZ requise) |

### Prod (Phase 3)

| Subnet | Type | CIDR | AZ | Role |
|---|---|---|---|---|
| public-nat-a | Public | 10.0.100.0/24 | ca-central-1a | NAT Gateway + web-site (EIP) |
| private-app-a | Prive | 10.0.1.0/24 | ca-central-1a | EC2 serveurs web prives |
| private-app-b | Prive | 10.0.2.0/24 | ca-central-1b | Redundance AZ |
| private-data-a | Prive | 10.0.10.0/24 | ca-central-1a | RDS |
| private-data-b | Prive | 10.0.11.0/24 | ca-central-1b | RDS (2e AZ) |

## Route Tables

**Publique (NAT subnet) :**
- `10.x.0.0/16 -> local`
- `0.0.0.0/0 -> Internet Gateway`

**Privee (app + data subnets) :**
- `10.x.0.0/16 -> local`
- `0.0.0.0/0 -> NAT Gateway/instance`
- `S3 prefix -> VPC Endpoint S3`

## NAT

| Environnement | Type | Cout |
|---|---|---|
| Dev | NAT instance (t4g.nano) | ~$4/mois |
| Prod | NAT Gateway | ~$45/mois |

La NAT instance utilise Amazon Linux 2023 avec IP forwarding et iptables MASQUERADE.

## VPC Endpoints

| Endpoint | Type | Environnement |
|---|---|---|
| S3 | Gateway (gratuit) | Dev + Prod |
| SSM, SSMMessages, EC2Messages | Interface | Prod seulement |

## VPC Flow Logs

Actives sur chaque VPC, destination S3 (`aromaestro-{env}-logs`), trafic ALL.

## Network ACLs

Default (allow all). Securite enforcee au niveau des Security Groups.
