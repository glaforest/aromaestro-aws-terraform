locals {
  name_prefix = "${var.project}-${var.environment}"
}

# ============================================================
# Security Group
# ============================================================

resource "aws_security_group" "rds" {
  name   = "${local.name_prefix}-sg-rds"
  vpc_id = var.vpc_id

  tags = {
    Name = "${local.name_prefix}-sg-rds"
  }
}

resource "aws_vpc_security_group_ingress_rule" "mysql" {
  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = var.allowed_security_group_id
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
  description                  = "MySQL from web app instances"
}

# ============================================================
# DB Subnet Group
# ============================================================

resource "aws_db_subnet_group" "main" {
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${local.name_prefix}-db-subnet-group"
  }
}

# ============================================================
# Parameter Group (require TLS)
# ============================================================

resource "aws_db_parameter_group" "main" {
  name   = "${local.name_prefix}-mysql-params"
  family = "mysql8.0"

  parameter {
    name  = "require_secure_transport"
    value = "1"
  }

  tags = {
    Name = "${local.name_prefix}-mysql-params"
  }
}

# ============================================================
# RDS Instance
# ============================================================

resource "aws_db_instance" "main" {
  identifier = "${local.name_prefix}-mysql"

  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.main.name

  multi_az            = var.multi_az
  publicly_accessible = false

  backup_retention_period = var.backup_retention_period
  backup_window           = "06:00-07:00"
  maintenance_window      = "sun:07:00-sun:08:00"

  skip_final_snapshot       = var.environment == "development"
  final_snapshot_identifier = var.environment == "development" ? null : "${local.name_prefix}-final-snapshot"

  username                    = "admin"
  manage_master_user_password = true

  tags = {
    Name        = "${local.name_prefix}-mysql"
    Application = "shared"
  }
}
