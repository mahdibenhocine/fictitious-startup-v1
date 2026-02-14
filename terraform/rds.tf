# RDS Parameter Group - disable forced SSL for DMS compatibility
resource "aws_db_parameter_group" "postgres" {
  name   = "${lower(var.project_name)}-postgres-params"
  family = "postgres16"

  parameter {
    name  = "rds.force_ssl"
    value = "0"
  }

  tags = {
    Name    = "${var.project_name}-postgres-params"
    Project = var.project_name
  }
}

# Security Group for RDS
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Security group for RDS PostgreSQL instance"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  tags = {
    Name    = "${var.project_name}-rds-sg"
    Project = var.project_name
  }
}

# Allow ingress from EC2 app security group on PostgreSQL port
resource "aws_vpc_security_group_ingress_rule" "rds_from_ec2" {
  security_group_id            = aws_security_group.rds.id
  description                  = "Allow PostgreSQL from app EC2 instances"
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.app.id

  tags = {
    Name = "allow-postgres-from-app"
  }
}

# Allow all outbound from RDS
resource "aws_vpc_security_group_egress_rule" "rds_all_outbound" {
  security_group_id = aws_security_group.rds.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name = "allow-all-outbound"
  }
}

# RDS Subnet Group - place RDS in private subnets
resource "aws_db_subnet_group" "main" {
  name       = "${lower(var.project_name)}-db-subnet-group"
  subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnets

  tags = {
    Name    = "${var.project_name}-db-subnet-group"
    Project = var.project_name
  }
}

# RDS PostgreSQL Instance
resource "aws_db_instance" "postgres" {
  identifier     = "${lower(var.project_name)}-postgres"
  engine         = "postgres"
  engine_version = "16.3"
  instance_class = "db.t3.micro"

  db_name  = "mvp"
  username = var.db_username
  password = var.db_password

  # Free Tier settings
  allocated_storage = 20
  storage_type      = "gp2"
  multi_az          = false

  # Networking
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  # Parameter group with SSL disabled for DMS
  parameter_group_name = aws_db_parameter_group.postgres.name

  # Skip final snapshot for development
  skip_final_snapshot = true

  tags = {
    Name    = "${var.project_name}-postgres"
    Project = var.project_name
  }
}