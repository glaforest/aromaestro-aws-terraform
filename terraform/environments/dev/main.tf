# ============================================================
# S3 Buckets (created first for VPC Flow Logs + CloudTrail)
# ============================================================

module "logs_bucket" {
  source = "../../modules/s3"

  bucket_name              = "aromaestro-dev-logs"
  enable_versioning        = false
  lifecycle_expiration_days = 90
  force_tls                = false # Policy managed by security module (CloudTrail + Config + TLS)
  sse_algorithm            = "AES256" # SSE-S3 for CloudTrail/Config compatibility

  tags = { Application = "shared" }
}

module "assets_bucket" {
  source = "../../modules/s3"

  bucket_name       = "aromaestro-dev-assets"
  enable_versioning = true
  force_tls         = true

  tags = { Application = "shared" }
}

# ============================================================
# VPC
# ============================================================

module "vpc" {
  source = "../../modules/vpc"

  project     = var.project
  environment = var.environment

  vpc_cidr        = "10.1.0.0/16"
  public_nat_cidr = "10.1.100.0/24"
  private_app_cidrs  = ["10.1.1.0/24"]
  private_data_cidrs = ["10.1.10.0/24", "10.1.11.0/24"]
  availability_zones = ["ca-central-1a", "ca-central-1b"]

  use_nat_gateway   = false
  nat_instance_type = "t4g.nano"

  logs_bucket_arn = module.logs_bucket.bucket_arn
}

# ============================================================
# Secrets Manager (Tailscale auth key)
# ============================================================

resource "aws_secretsmanager_secret" "tailscale" {
  name        = "${var.project}-${var.environment}-tailscale-auth-key"
  description = "Tailscale auth key for EC2 instances"
}

# ============================================================
# CloudWatch Agent config in SSM Parameter Store
# ============================================================

resource "aws_ssm_parameter" "cw_agent_config" {
  name = "/${var.project}/${var.environment}/cloudwatch-agent-config"
  type = "String"
  value = jsonencode({
    metrics = {
      namespace = "CWAgent"
      metrics_collected = {
        mem = {
          measurement = ["mem_used_percent"]
        }
        disk = {
          measurement = ["disk_used_percent"]
          resources   = ["/"]
        }
      }
      append_dimensions = {
        InstanceId = "$${aws:InstanceId}"
      }
    }
  })
}

# ============================================================
# RDS (created before EC2 for SG reference)
# ============================================================

module "rds" {
  source = "../../modules/rds"

  project     = var.project
  environment = var.environment

  vpc_id                    = module.vpc.vpc_id
  subnet_ids                = module.vpc.private_data_subnet_ids
  allowed_security_group_id = module.ec2.web_app_security_group_id

  instance_class          = "db.t4g.micro"
  allocated_storage       = 20
  max_allocated_storage   = 100
  backup_retention_period = 1
  multi_az                = false
}

# ============================================================
# EC2
# ============================================================

module "ec2" {
  source = "../../modules/ec2"

  project     = var.project
  environment = var.environment

  vpc_id    = module.vpc.vpc_id
  vpc_cidr  = "10.1.0.0/16"
  subnet_id = module.vpc.private_app_subnet_ids[0]

  rds_security_group_id = module.rds.security_group_id

  instance_type = "t4g.micro"
  instances = {
    "web-admin"     = "admin"
    "web-wordpress" = "wordpress"
    "web-openclaw"  = "openclaw"
  }

  tailscale_auth_key_secret_arn      = aws_secretsmanager_secret.tailscale.arn
  cloudwatch_agent_config_ssm_param  = aws_ssm_parameter.cw_agent_config.name
}

# ============================================================
# Web-Site (public instance with EIP)
# ============================================================

resource "aws_security_group" "web_site_public" {
  name   = "${var.project}-${var.environment}-sg-web-site-public"
  vpc_id = module.vpc.vpc_id

  tags = {
    Name = "${var.project}-${var.environment}-sg-web-site-public"
  }
}

# Inbound: HTTP
resource "aws_vpc_security_group_ingress_rule" "web_site_http" {
  security_group_id = aws_security_group.web_site_public.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  description       = "HTTP from internet"
}

# Inbound: HTTPS
resource "aws_vpc_security_group_ingress_rule" "web_site_https" {
  security_group_id = aws_security_group.web_site_public.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "HTTPS from internet"
}

# Outbound: HTTPS
resource "aws_vpc_security_group_egress_rule" "web_site_https" {
  security_group_id = aws_security_group.web_site_public.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "HTTPS - AWS APIs, updates, Tailscale DERP"
}

# Outbound: HTTP
resource "aws_vpc_security_group_egress_rule" "web_site_http" {
  security_group_id = aws_security_group.web_site_public.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  description       = "HTTP - apt package manager"
}

# Outbound: Tailscale
resource "aws_vpc_security_group_egress_rule" "web_site_tailscale" {
  security_group_id = aws_security_group.web_site_public.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 41641
  to_port           = 41641
  ip_protocol       = "udp"
  description       = "Tailscale WireGuard direct connections"
}

# Outbound: MySQL to RDS
resource "aws_vpc_security_group_egress_rule" "web_site_mysql" {
  security_group_id            = aws_security_group.web_site_public.id
  referenced_security_group_id = module.rds.security_group_id
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
  description                  = "MySQL to RDS"
}

# Outbound: DNS
resource "aws_vpc_security_group_egress_rule" "web_site_dns_udp" {
  security_group_id = aws_security_group.web_site_public.id
  cidr_ipv4         = "10.1.0.0/16"
  from_port         = 53
  to_port           = 53
  ip_protocol       = "udp"
  description       = "DNS resolution"
}

resource "aws_vpc_security_group_egress_rule" "web_site_dns_tcp" {
  security_group_id = aws_security_group.web_site_public.id
  cidr_ipv4         = "10.1.0.0/16"
  from_port         = 53
  to_port           = 53
  ip_protocol       = "tcp"
  description       = "DNS resolution (TCP)"
}

# Outbound: ICMP
resource "aws_vpc_security_group_egress_rule" "web_site_icmp" {
  security_group_id = aws_security_group.web_site_public.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = -1
  to_port           = -1
  ip_protocol       = "icmp"
  description       = "ICMP ping for diagnostics"
}

# Allow web-site to access RDS
resource "aws_vpc_security_group_ingress_rule" "rds_from_web_site" {
  security_group_id            = module.rds.security_group_id
  referenced_security_group_id = aws_security_group.web_site_public.id
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
  description                  = "MySQL from web-site public instance"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-arm64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }
}

resource "aws_instance" "web_site" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t4g.micro"
  subnet_id              = module.vpc.public_nat_subnet_id
  vpc_security_group_ids = [aws_security_group.web_site_public.id]
  iam_instance_profile   = "${var.project}-${var.environment}-ec2-profile"

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = base64encode(templatefile("../../modules/ec2/user_data.sh.tpl", {
    tailscale_secret_arn  = aws_secretsmanager_secret.tailscale.arn
    hostname              = "web-site-${var.environment}"
    aws_region            = "ca-central-1"
    cw_agent_config_param = aws_ssm_parameter.cw_agent_config.name
  }))

  tags = {
    Name        = "${var.project}-${var.environment}-web-site"
    Application = "site"
  }

  lifecycle {
    ignore_changes = [ami, user_data]
  }
}

resource "aws_eip" "web_site" {
  domain   = "vpc"
  instance = aws_instance.web_site.id

  tags = {
    Name = "${var.project}-${var.environment}-web-site-eip"
  }
}

# ============================================================
# Security Services
# ============================================================

module "security" {
  source = "../../modules/security"

  project          = var.project
  environment      = var.environment
  logs_bucket_name = module.logs_bucket.bucket_id
  logs_bucket_arn  = module.logs_bucket.bucket_arn
}

# ============================================================
# Monitoring
# ============================================================

module "monitoring" {
  source = "../../modules/monitoring"

  project          = var.project
  environment      = var.environment
  alert_email      = var.alert_email
  ec2_instance_ids = merge(module.ec2.instance_ids, { "web-site" = aws_instance.web_site.id })
  rds_instance_id  = module.rds.db_instance_id
  has_nat_instance = true
  nat_instance_id  = module.vpc.nat_instance_id
}

# ============================================================
# Backup
# ============================================================

module "backup" {
  source = "../../modules/backup"

  project       = var.project
  environment   = var.environment
  is_production = false
}

# ============================================================
# Patching
# ============================================================

module "patching" {
  source = "../../modules/patching"

  project     = var.project
  environment = var.environment
}
