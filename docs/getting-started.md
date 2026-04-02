# Guide de demarrage (nouvel ordinateur)

Ce guide te permet de configurer ton environnement de travail et de deployer l'infrastructure Aromaestro a partir de zero.

## Prerequis a installer

### 1. Homebrew (gestionnaire de paquets macOS)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 2. Terraform

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

Verifie :
```bash
terraform version
# Doit etre >= 1.7.0
```

### 3. AWS CLI v2

```bash
brew install awscli
```

Verifie :
```bash
aws --version
# Doit etre >= 2.x
```

### 4. Git

```bash
brew install git
```

### 5. Claude Code (optionnel, pour assistance AI)

```bash
brew install claude-code
```

## Cloner le repo

```bash
cd ~/Desktop
git clone https://github.com/glaforest/aromaestro-aws-terraform.git
cd aromaestro-aws-terraform
```

## Configurer AWS SSO

### Creer les profils

```bash
aws configure sso --profile aromaestro-dev
```

Repondre aux questions :
- **SSO session name** : `aromaestro`
- **SSO start URL** : `https://d-9d674000e9.awsapps.com/start`
- **SSO region** : `ca-central-1`
- **SSO registration scopes** : appuyer Enter (defaut)
- Le navigateur s'ouvre, se connecter avec ton compte Identity Center
- Choisir le compte **Aromaestro Dev** (051370880327)
- Role : **AdministratorAccess**
- **CLI default client Region** : `ca-central-1`
- **CLI default output format** : `json`

Repeter pour les autres comptes :

```bash
aws configure sso --profile aromaestro-mgmt
# Choisir : Aromaestro Inc. (589389426408)

aws configure sso --profile aromaestro-prod
# Choisir : Aromaestro.com (872515273944)

aws configure sso --profile aromaestro-logarchive
# Choisir : Log Archive (315466292610)
```

### Verifier les profils

```bash
aws sts get-caller-identity --profile aromaestro-dev
aws sts get-caller-identity --profile aromaestro-mgmt
aws sts get-caller-identity --profile aromaestro-prod
aws sts get-caller-identity --profile aromaestro-logarchive
```

Chaque commande doit retourner un Account ID different.

### Renouveler la session SSO (quand elle expire)

```bash
aws sso login --profile aromaestro-dev
```

La session est partagee entre tous les profils aromaestro-*, donc un seul login suffit.

## Structure du fichier ~/.aws/config

Apres configuration, ton fichier `~/.aws/config` devrait ressembler a :

```ini
[profile aromaestro-dev]
sso_session = aromaestro
sso_account_id = 051370880327
sso_role_name = AdministratorAccess
region = ca-central-1
output = json

[profile aromaestro-mgmt]
sso_session = aromaestro
sso_account_id = 589389426408
sso_role_name = AdministratorAccess
region = ca-central-1
output = json

[profile aromaestro-prod]
sso_session = aromaestro
sso_account_id = 872515273944
sso_role_name = AdministratorAccess
region = ca-central-1
output = json

[profile aromaestro-logarchive]
sso_session = aromaestro
sso_account_id = 315466292610
sso_role_name = AdministratorAccess
region = ca-central-1
output = json

[sso-session aromaestro]
sso_start_url = https://d-9d674000e9.awsapps.com/start
sso_region = ca-central-1
sso_registration_scopes = sso:account:access
```

## Initialiser Terraform

### Backend (deja deploye, pas besoin de refaire)

Le state backend (S3 + DynamoDB) existe deja dans le Management account. Il n'y a rien a faire ici sauf si tu recrees tout de zero.

### Environnement Dev

```bash
cd terraform/environments/dev

# Creer le fichier de variables
cp terraform.tfvars.example terraform.tfvars
# Editer terraform.tfvars avec ton email pour les alertes
nano terraform.tfvars

# Initialiser (telecharge les providers et connecte au backend S3)
AWS_PROFILE=aromaestro-dev terraform init

# Verifier l'etat actuel
AWS_PROFILE=aromaestro-dev terraform plan
# Devrait afficher : No changes. Your infrastructure matches the configuration.
```

### Environnement Management

```bash
cd terraform/environments/management

cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars

AWS_PROFILE=aromaestro-mgmt terraform init
AWS_PROFILE=aromaestro-mgmt terraform plan
```

### Environnement Prod

```bash
cd terraform/environments/prod

cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars

AWS_PROFILE=aromaestro-prod terraform init
AWS_PROFILE=aromaestro-prod terraform plan
```

## Deployer a partir de zero (nouvelle infra complete)

Si tu dois tout recreer (nouveau compte AWS, disaster recovery, etc.) :

### Etape 1 : Creer les comptes AWS

Voir [accounts.md](architecture/accounts.md) pour la structure. Il faut :

1. Creer un nouveau Management account (email dedie)
2. Activer AWS Organizations (All features)
3. Creer le Dev account depuis Organizations
4. Creer le LogArchive account depuis Organizations
5. Inviter le compte Prod existant
6. Activer IAM Identity Center et creer les utilisateurs
7. Configurer les profils AWS CLI (voir section ci-dessus)

### Etape 2 : Deployer le state backend

```bash
cd terraform/backend
AWS_PROFILE=aromaestro-mgmt terraform init
AWS_PROFILE=aromaestro-mgmt terraform plan
AWS_PROFILE=aromaestro-mgmt terraform apply
```

### Etape 3 : Deployer le Management (SCPs + Budgets)

```bash
# Activer les SCPs dans Organizations
AWS_PROFILE=aromaestro-mgmt aws organizations enable-policy-type \
  --root-id <root-id> \
  --policy-type SERVICE_CONTROL_POLICY

# Activer Cost Explorer dans la console AWS (Billing > Cost Explorer)

cd terraform/environments/management
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
AWS_PROFILE=aromaestro-mgmt terraform init
AWS_PROFILE=aromaestro-mgmt terraform apply
```

### Etape 4 : Deployer le Dev

```bash
cd terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
AWS_PROFILE=aromaestro-dev terraform init
AWS_PROFILE=aromaestro-dev terraform apply
```

Apres le deploiement :

```bash
# Configurer la cle Tailscale dans Secrets Manager
# 1. Generer une auth key sur https://login.tailscale.com/admin/settings/keys
#    (Reusable: oui, Expiration: 90 jours)
# 2. La stocker dans Secrets Manager :
AWS_PROFILE=aromaestro-dev aws secretsmanager put-secret-value \
  --secret-id "aromaestro-development-tailscale-auth-key" \
  --secret-string "tskey-auth-XXXXXXXXXXXX"

# Installer Tailscale + CloudWatch Agent sur toutes les instances via SSM
AWS_PROFILE=aromaestro-dev aws ssm send-command \
  --document-name "AWS-RunShellScript" \
  --targets "Key=tag:Owner,Values=aromaestro" \
  --parameters 'commands=[
    "apt-get update -y && apt-get install -y unzip curl",
    "curl -fsSL https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip -o /tmp/awscliv2.zip && unzip -q /tmp/awscliv2.zip -d /tmp && /tmp/aws/install && rm -rf /tmp/aws /tmp/awscliv2.zip",
    "curl -fsSL https://tailscale.com/install.sh | sh",
    "TOKEN=$(curl -s -X PUT http://169.254.169.254/latest/api/token -H X-aws-ec2-metadata-token-ttl-seconds:60)",
    "REGION=$(curl -s -H \"X-aws-ec2-metadata-token: $TOKEN\" http://169.254.169.254/latest/meta-data/placement/region)",
    "INSTANCE_ID=$(curl -s -H \"X-aws-ec2-metadata-token: $TOKEN\" http://169.254.169.254/latest/meta-data/instance-id)",
    "TAILSCALE_AUTH_KEY=$(/usr/local/bin/aws secretsmanager get-secret-value --secret-id aromaestro-development-tailscale-auth-key --query SecretString --output text --region $REGION)",
    "HOSTNAME=$(/usr/local/bin/aws ec2 describe-tags --filters Name=resource-id,Values=$INSTANCE_ID Name=key,Values=Name --query Tags[0].Value --output text --region $REGION)",
    "tailscale up --authkey=\"$TAILSCALE_AUTH_KEY\" --hostname=\"$HOSTNAME\"",
    "wget -q https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/arm64/latest/amazon-cloudwatch-agent.deb && dpkg -i amazon-cloudwatch-agent.deb && rm -f amazon-cloudwatch-agent.deb",
    "/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:/aromaestro/development/cloudwatch-agent-config"
  ]' \
  --timeout-seconds 600

# Confirmer l'abonnement SNS (verifier sa boite email)
```

### Etape 5 : Deployer la Prod

```bash
cd terraform/environments/prod
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars

AWS_PROFILE=aromaestro-prod terraform init

# Importer les buckets S3 existants
AWS_PROFILE=aromaestro-prod terraform import module.existing_backups.aws_s3_bucket.this aromaestro-backups
AWS_PROFILE=aromaestro-prod terraform import module.existing_diffuser_ota.aws_s3_bucket.this aromaestro-diffuser-ota
AWS_PROFILE=aromaestro-prod terraform import module.existing_ota.aws_s3_bucket.this aromaestro-ota

# Verifier le plan (attention aux ressources existantes)
AWS_PROFILE=aromaestro-prod terraform plan

# Deployer
AWS_PROFILE=aromaestro-prod terraform apply

# Configurer Tailscale (meme processus que dev, avec le bon secret-id)
```

## Operations courantes

### Se connecter a une instance

```bash
# Via SSM (toujours disponible)
AWS_PROFILE=aromaestro-dev aws ssm start-session --target <instance-id>

# Via Tailscale (si configure)
ssh ubuntu@<nom-tailscale>
```

### Voir les instances

```bash
AWS_PROFILE=aromaestro-dev aws ec2 describe-instances \
  --query "Reservations[].Instances[].[Tags[?Key=='Name'].Value|[0],InstanceId,PrivateIpAddress,State.Name]" \
  --output table
```

### Voir l'endpoint RDS

```bash
cd terraform/environments/dev
AWS_PROFILE=aromaestro-dev terraform output rds_endpoint
```

### Voir l'IP publique du site

```bash
cd terraform/environments/dev
AWS_PROFILE=aromaestro-dev terraform output web_site_public_ip
```

### Renouveler la cle Tailscale

1. Aller sur https://login.tailscale.com/admin/settings/keys
2. Generer une nouvelle auth key (Reusable, 90 jours)
3. Mettre a jour dans Secrets Manager :

```bash
AWS_PROFILE=aromaestro-dev aws secretsmanager put-secret-value \
  --secret-id "aromaestro-development-tailscale-auth-key" \
  --secret-string "tskey-auth-NOUVELLE-CLE"
```

### Modifier l'infrastructure

```bash
# 1. Editer les fichiers Terraform
# 2. Verifier les changements
AWS_PROFILE=aromaestro-dev terraform plan
# 3. Appliquer
AWS_PROFILE=aromaestro-dev terraform apply
# 4. Commiter
git add -A && git commit -m "description du changement"
git push
```

## Depannage

### Session SSO expiree

```
Error: ExpiredTokenException
```

Solution :
```bash
aws sso login --profile aromaestro-dev
```

### Terraform state lock

```
Error: Error acquiring the state lock
```

Solution (si personne d'autre ne travaille sur le Terraform) :
```bash
AWS_PROFILE=aromaestro-dev terraform force-unlock <LOCK-ID>
```

### Instance inaccessible via SSM

Verifier que l'instance a le bon IAM role et qu'elle peut sortir sur internet (NAT fonctionnel) :

```bash
AWS_PROFILE=aromaestro-dev aws ssm describe-instance-information \
  --query "InstanceInformationList[].[InstanceId,PingStatus]" \
  --output table
```

### Tailscale ne se connecte pas

1. Se connecter via SSM
2. Verifier le status : `tailscale status`
3. Si pas installe, relancer la commande SSM Run Command (voir section Deployer)
