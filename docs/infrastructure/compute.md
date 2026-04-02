# Compute (EC2)

## Instances

### Dev

| Nom | Role | Type | OS | Subnet | IP publique |
|---|---|---|---|---|---|
| web-site | Site internet | t4g.micro | Ubuntu 24.04 ARM | public-nat-a | Oui (EIP) |
| web-admin | Admin Laravel | t4g.micro | Ubuntu 24.04 ARM | private-app-a | Non |
| web-wordpress | WordPress | t4g.micro | Ubuntu 24.04 ARM | private-app-a | Non |
| web-openclaw | Open Claw | t4g.micro | Ubuntu 24.04 ARM | private-app-a | Non |

### Prod

Meme structure en t4g.small. Code pret, pas encore deploye.

## Configuration commune

- **Tailscale** : installe au premier boot via user_data, auth key dans Secrets Manager. Fallback : installation via SSM Run Command si le user_data echoue.
- **CloudWatch Agent** : installe au premier boot via user_data, config dans SSM Parameter Store
- **AWS CLI v2** : installe au premier boot via user_data (requis sur Ubuntu 24.04 ARM)
- **SSM Agent** : pre-installe sur Ubuntu, IAM role attache
- **EBS chiffre** : gp3 20GB, chiffrement par defaut au niveau du compte

## Security Groups

### sg-web-app (instances privees)

| Direction | Port | Protocole | Destination | Usage |
|---|---|---|---|---|
| Outbound | 443 | TCP | 0.0.0.0/0 | HTTPS (AWS APIs, updates, Tailscale DERP) |
| Outbound | 80 | TCP | 0.0.0.0/0 | HTTP (apt) |
| Outbound | 41641 | UDP | 0.0.0.0/0 | Tailscale WireGuard direct |
| Outbound | 3306 | TCP | sg-rds | MySQL |
| Outbound | 53 | UDP/TCP | VPC CIDR | DNS |
| Outbound | ICMP | ICMP | 0.0.0.0/0 | Ping (diagnostics) |
| Inbound | - | - | - | **Aucun port ouvert** |

### sg-web-site-public (web-site expose)

| Direction | Port | Protocole | Source/Destination | Usage |
|---|---|---|---|---|
| Inbound | 80 | TCP | 0.0.0.0/0 | HTTP depuis internet |
| Inbound | 443 | TCP | 0.0.0.0/0 | HTTPS depuis internet |
| Outbound | 443 | TCP | 0.0.0.0/0 | HTTPS |
| Outbound | 80 | TCP | 0.0.0.0/0 | HTTP |
| Outbound | 41641 | UDP | 0.0.0.0/0 | Tailscale |
| Outbound | 3306 | TCP | sg-rds | MySQL |
| Outbound | 53 | UDP/TCP | VPC CIDR | DNS |
| Outbound | ICMP | ICMP | 0.0.0.0/0 | Ping |

## IAM Role (ec2-role)

Permissions :
- `AmazonSSMManagedInstanceCore` (SSM Session Manager)
- `CloudWatchAgentServerPolicy` (metriques et logs)
- Acces au secret Tailscale dans Secrets Manager

## Tailscale

- Auth key dans Secrets Manager : `aromaestro-{env}-tailscale-auth-key`
- Expiration : 90 jours (rotation manuelle pour l'instant)
- Installation : automatique au premier boot via user_data
- Fallback : SSM Run Command (voir getting-started.md)
