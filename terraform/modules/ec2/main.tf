locals {
  name_prefix = "${var.project}-${var.environment}"
}

# ============================================================
# AMI - Ubuntu 24.04 ARM
# ============================================================

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

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

# ============================================================
# IAM Role for EC2 (SSM + Secrets Manager + CloudWatch)
# ============================================================

resource "aws_iam_role" "ec2" {
  name = "${local.name_prefix}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy" "secrets" {
  name = "${local.name_prefix}-secrets-access"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "secretsmanager:GetSecretValue"
        Resource = var.tailscale_auth_key_secret_arn
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${local.name_prefix}-ec2-profile"
  role = aws_iam_role.ec2.name
}

# ============================================================
# Security Group - Web App
# ============================================================

resource "aws_security_group" "web_app" {
  name   = "${local.name_prefix}-sg-web-app"
  vpc_id = var.vpc_id

  tags = {
    Name = "${local.name_prefix}-sg-web-app"
  }
}

resource "aws_vpc_security_group_egress_rule" "https" {
  security_group_id = aws_security_group.web_app.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "HTTPS - AWS APIs, updates, Tailscale DERP"
}

resource "aws_vpc_security_group_egress_rule" "http" {
  security_group_id = aws_security_group.web_app.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  description       = "HTTP - apt package manager"
}

resource "aws_vpc_security_group_egress_rule" "tailscale" {
  security_group_id = aws_security_group.web_app.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 41641
  to_port           = 41641
  ip_protocol       = "udp"
  description       = "Tailscale WireGuard direct connections"
}

resource "aws_vpc_security_group_egress_rule" "mysql" {
  security_group_id            = aws_security_group.web_app.id
  referenced_security_group_id = var.rds_security_group_id
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
  description                  = "MySQL to RDS"
}

resource "aws_vpc_security_group_egress_rule" "dns_udp" {
  security_group_id = aws_security_group.web_app.id
  cidr_ipv4         = var.vpc_cidr
  from_port         = 53
  to_port           = 53
  ip_protocol       = "udp"
  description       = "DNS resolution"
}

resource "aws_vpc_security_group_egress_rule" "dns_tcp" {
  security_group_id = aws_security_group.web_app.id
  cidr_ipv4         = var.vpc_cidr
  from_port         = 53
  to_port           = 53
  ip_protocol       = "tcp"
  description       = "DNS resolution (TCP)"
}

resource "aws_vpc_security_group_egress_rule" "icmp" {
  security_group_id = aws_security_group.web_app.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = -1
  to_port           = -1
  ip_protocol       = "icmp"
  description       = "ICMP ping for diagnostics"
}

# ============================================================
# EC2 Instances
# ============================================================

resource "aws_instance" "web" {
  for_each = var.instances

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.web_app.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2.name

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh.tpl", {
    tailscale_secret_arn  = var.tailscale_auth_key_secret_arn
    hostname              = "${each.key}-${var.environment}"
    aws_region            = "ca-central-1"
    cw_agent_config_param = var.cloudwatch_agent_config_ssm_param
  }))

  tags = {
    Name        = "${local.name_prefix}-${each.key}"
    Application = each.value
  }

  lifecycle {
    ignore_changes = [ami, user_data]
  }
}
