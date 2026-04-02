# Restauration EC2

## Depuis une AMI (AWS Backup)

### Via Console

1. EC2 > AMIs > Owned by me
2. Selectionner l'AMI la plus recente pour l'instance
3. Launch instance from AMI
4. Configuration :
   - Instance type : identique (t4g.small prod / t4g.micro dev)
   - Subnet : selon l'instance (public-nat pour web-site, private-app pour les autres)
   - Security group : sg-web-app ou sg-web-site-public
   - IAM role : aromaestro-{env}-ec2-profile
   - Pas d'IP publique (sauf web-site)
5. Launch

### Post-restauration

1. Installer Tailscale via SSM Run Command (voir ci-dessous)
2. Installer CloudWatch Agent via SSM Run Command
3. Verifier la connectivite Tailscale : `tailscale status`
4. Verifier l'application
5. Pour web-site : reassocier l'Elastic IP

### Commande SSM pour reinstaller Tailscale + CloudWatch Agent

```bash
aws ssm send-command \
  --document-name "AWS-RunShellScript" \
  --targets "Key=instanceids,Values=<instance-id>" \
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
  ]'
```
