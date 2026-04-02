locals {
  name_prefix = "${var.project}-${var.environment}"
}

# ============================================================
# VPC
# ============================================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}

# ============================================================
# Internet Gateway
# ============================================================

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-igw"
  }
}

# ============================================================
# Public Subnet (NAT only)
# ============================================================

resource "aws_subnet" "public_nat" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_nat_cidr
  availability_zone       = var.availability_zones[0]
  map_public_ip_on_launch = false

  tags = {
    Name = "${local.name_prefix}-public-nat-a"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-rt-public"
  }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public_nat" {
  subnet_id      = aws_subnet.public_nat.id
  route_table_id = aws_route_table.public.id
}

# ============================================================
# NAT Gateway (prod) or NAT Instance (dev)
# ============================================================

resource "aws_eip" "nat" {
  count  = var.use_nat_gateway ? 1 : 0
  domain = "vpc"

  tags = {
    Name = "${local.name_prefix}-nat-eip"
  }
}

resource "aws_nat_gateway" "main" {
  count         = var.use_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public_nat.id

  tags = {
    Name = "${local.name_prefix}-nat-gw"
  }

  depends_on = [aws_internet_gateway.main]
}

data "aws_ami" "nat_instance" {
  count       = var.use_nat_gateway ? 0 : 1
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-arm64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "nat_instance" {
  count  = var.use_nat_gateway ? 0 : 1
  name   = "${local.name_prefix}-sg-nat-instance"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "All traffic from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-sg-nat-instance"
  }
}

resource "aws_instance" "nat" {
  count                       = var.use_nat_gateway ? 0 : 1
  ami                         = data.aws_ami.nat_instance[0].id
  instance_type               = var.nat_instance_type
  subnet_id                   = aws_subnet.public_nat.id
  vpc_security_group_ids      = [aws_security_group.nat_instance[0].id]
  source_dest_check           = false
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    # Enable IP forwarding
    echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.d/custom-ip-forward.conf
    sysctl -p /etc/sysctl.d/custom-ip-forward.conf

    # Detect primary network interface
    IFACE=$(ip -o -4 route show to default | awk '{print $5}')

    # Install and configure iptables
    yum install -y iptables-services
    systemctl enable iptables
    systemctl start iptables
    /sbin/iptables -t nat -A POSTROUTING -o $IFACE -j MASQUERADE
    /sbin/iptables -F FORWARD
    service iptables save
  EOF

  tags = {
    Name        = "${local.name_prefix}-nat-instance"
    Application = "shared"
  }
}

# ============================================================
# Private App Subnets
# ============================================================

resource "aws_subnet" "private_app" {
  count             = length(var.private_app_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_app_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${local.name_prefix}-private-app-${count.index == 0 ? "a" : "b"}"
  }
}

# ============================================================
# Private Data Subnets
# ============================================================

resource "aws_subnet" "private_data" {
  count             = length(var.private_data_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_data_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${local.name_prefix}-private-data-${count.index == 0 ? "a" : "b"}"
  }
}

# ============================================================
# Private Route Table
# ============================================================

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-rt-private"
  }
}

resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.use_nat_gateway ? aws_nat_gateway.main[0].id : null
  network_interface_id   = var.use_nat_gateway ? null : aws_instance.nat[0].primary_network_interface_id
}

resource "aws_route_table_association" "private_app" {
  count          = length(var.private_app_cidrs)
  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_data" {
  count          = length(var.private_data_cidrs)
  subnet_id      = aws_subnet.private_data[count.index].id
  route_table_id = aws_route_table.private.id
}

# ============================================================
# VPC Flow Logs
# ============================================================

resource "aws_flow_log" "vpc" {
  vpc_id                   = aws_vpc.main.id
  traffic_type             = "ALL"
  log_destination          = var.logs_bucket_arn
  log_destination_type     = "s3"
  max_aggregation_interval = 600

  tags = {
    Name = "${local.name_prefix}-flow-logs"
  }
}

# ============================================================
# S3 Gateway Endpoint (free)
# ============================================================

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.ca-central-1.s3"

  route_table_ids = [
    aws_route_table.private.id,
    aws_route_table.public.id,
  ]

  tags = {
    Name = "${local.name_prefix}-vpce-s3"
  }
}
