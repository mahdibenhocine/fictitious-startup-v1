resource "aws_security_group" "app" {
  name        = "app-instance-sg"
  description = "Security group for application instance"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id
  
  tags = {
    Name        = "app-instance-sg"
    Environment = "development"
    ManagedBy   = "terraform"
  }
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.app.id
  
  description = "Allow HTTP inbound traffic"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
  cidr_ipv4   = "0.0.0.0/0"
  
  tags = {
    Name = "allow-http"
  }
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.app.id
  
  description = "Allow all outbound traffic"
  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
  
  tags = {
    Name = "allow-all-outbound"
  }
}

# Allow PostgreSQL from DMS Replication Instance
resource "aws_vpc_security_group_ingress_rule" "ec2_postgres_from_dms" {
  security_group_id            = aws_security_group.app.id
  description                  = "Allow PostgreSQL from DMS"
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.dms.id

  tags = {
    Name = "allow-postgres-from-dms"
  }
}