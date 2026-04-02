#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# Update system
apt-get update -y
apt-get upgrade -y

# Install AWS CLI v2
apt-get install -y unzip curl
curl -fsSL https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install
rm -rf /tmp/aws /tmp/awscliv2.zip

# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Get metadata
TOKEN=$(curl -s -X PUT http://169.254.169.254/latest/api/token -H "X-aws-ec2-metadata-token-ttl-seconds:60")
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region)

# Get Tailscale auth key from Secrets Manager
TAILSCALE_AUTH_KEY=$(/usr/local/bin/aws secretsmanager get-secret-value \
  --secret-id "${tailscale_secret_arn}" \
  --query SecretString \
  --output text \
  --region "$REGION")

# Start Tailscale
tailscale up --authkey="$TAILSCALE_AUTH_KEY" --hostname="${hostname}"

# Install and configure CloudWatch Agent
wget -q https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/arm64/latest/amazon-cloudwatch-agent.deb
dpkg -i amazon-cloudwatch-agent.deb
rm -f amazon-cloudwatch-agent.deb

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c "ssm:${cw_agent_config_param}"
