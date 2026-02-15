# ============================================
# DMS Replication Instance
# ============================================

# Security Group for DMS Replication Instance
resource "aws_security_group" "dms" {
  name        = "${lower(var.project_name)}-dms-sg"
  description = "Security group for DMS Replication Instance"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  tags = {
    Name    = "${lower(var.project_name)}-dms-sg"
    Project = var.project_name
  }
}

# DMS outbound - needs to reach both EC2 and RDS on PostgreSQL port
resource "aws_vpc_security_group_egress_rule" "dms_all_outbound" {
  security_group_id = aws_security_group.dms.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name = "dms-allow-all-outbound"
  }
}

# DMS Replication Subnet Group
resource "aws_dms_replication_subnet_group" "main" {
  replication_subnet_group_id          = "${lower(var.project_name)}-dms-subnet-group"
  replication_subnet_group_description = "DMS replication subnet group"
  subnet_ids                           = data.terraform_remote_state.vpc.outputs.private_subnets

  depends_on = [aws_iam_role_policy_attachment.dms_vpc_policy]

  tags = {
    Name    = "${lower(var.project_name)}-dms-subnet-group"
    Project = var.project_name
  }
}

# DMS Replication Instance
resource "aws_dms_replication_instance" "main" {
  replication_instance_id    = "${lower(var.project_name)}-dms-instance"
  replication_instance_class = "dms.t3.small"
  allocated_storage          = 20
  multi_az                   = false
  publicly_accessible        = false

  replication_subnet_group_id = aws_dms_replication_subnet_group.main.id
  vpc_security_group_ids      = [aws_security_group.dms.id]

  tags = {
    Name    = "${lower(var.project_name)}-dms-instance"
    Project = var.project_name
  }
}

# ============================================
# DMS Endpoints
# ============================================

# Source Endpoint - PostgreSQL on EC2
resource "aws_dms_endpoint" "source" {
  endpoint_id   = "${lower(var.project_name)}-source-ec2"
  endpoint_type = "source"
  engine_name   = "postgres"

  server_name   = aws_instance.app.private_ip
  port          = 5432
  database_name = "mvp"
  username      = var.db_username
  password      = var.db_password
  ssl_mode      = "none"

  tags = {
    Name    = "${lower(var.project_name)}-source-ec2"
    Project = var.project_name
  }
}

# Target Endpoint - RDS PostgreSQL
resource "aws_dms_endpoint" "target" {
  endpoint_id   = "${lower(var.project_name)}-target-rds"
  endpoint_type = "target"
  engine_name   = "postgres"

  server_name   = aws_db_instance.postgres.address
  port          = aws_db_instance.postgres.port
  database_name = "mvp"
  username      = var.db_username
  password      = var.db_password
  ssl_mode      = "none"

  tags = {
    Name    = "${lower(var.project_name)}-target-rds"
    Project = var.project_name
  }
}

# ============================================
# DMS Replication Task
# ============================================

resource "aws_dms_replication_task" "migration" {
  replication_task_id      = "${lower(var.project_name)}-full-load"
  replication_instance_arn = aws_dms_replication_instance.main.replication_instance_arn
  source_endpoint_arn      = aws_dms_endpoint.source.endpoint_arn
  target_endpoint_arn      = aws_dms_endpoint.target.endpoint_arn
  migration_type           = "full-load"

  # Don't start automatically
  start_replication_task = false

  table_mappings = jsonencode({
    rules = [
      {
        rule-type = "selection"
        rule-id   = "1"
        rule-name = "select-all"
        object-locator = {
          schema-name = "public"
          table-name  = "%"
        }
        rule-action = "include"
      }
    ]
  })

  tags = {
    Name    = "${lower(var.project_name)}-full-load"
    Project = var.project_name
  }
}

# IAM Role required by DMS to manage VPC resources
resource "aws_iam_role" "dms_vpc_role" {
  name = "dms-vpc-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "dms.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name    = "dms-vpc-role"
    Project = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "dms_vpc_policy" {
  role       = aws_iam_role.dms_vpc_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSVPCManagementRole"
}