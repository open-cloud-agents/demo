resource "aws_db_subnet_group" "api" {
  name       = "dbsubnet-pricing-api-${var.name_suffix}"
  subnet_ids = [for subnet in aws_subnet.private : subnet.id]

  tags = {
    Name = "dbsubnet-pricing-api-${var.name_suffix}"
  }
}

resource "aws_db_instance" "api" {
  identifier        = "pricing-api-prod-${var.name_suffix}"
  engine            = "postgres"
  engine_version    = "18.4"
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage
  db_name           = "pricing_api"
  username          = "pricing_api"
  # The master password is generated and rotated by RDS itself, in its own secret.
  manage_master_user_password = true
  db_subnet_group_name        = aws_db_subnet_group.api.name
  vpc_security_group_ids      = [aws_security_group.database.id]
  multi_az                    = false
  storage_encrypted           = true
  backup_retention_period     = 7
  skip_final_snapshot         = true

  tags = {
    Name = "pricing-api-prod-${var.name_suffix}"
  }
}
