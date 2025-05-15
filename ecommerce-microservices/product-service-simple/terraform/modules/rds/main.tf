resource "aws_db_subnet_group" "rds" {
  name        = "${var.name_prefix}-db-subnet-group"
  description = "DB subnet group for ${var.name_prefix}"
  subnet_ids  = var.subnet_ids
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-db-subnet-group"
    }
  )
}

resource "aws_db_parameter_group" "rds" {
  name        = "${var.name_prefix}-db-parameter-group"
  family      = "postgres${split(".", var.engine_version)[0]}"
  description = "Parameter group for ${var.name_prefix} RDS instance"
  
  parameter {
    name  = "log_statement"
    value = "none"  # Options: none, ddl, mod, all
  }
  
  parameter {
    name  = "log_min_duration_statement"
    value = "1000"  # Log statements taking more than 1 second
  }
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-db-parameter-group"
    }
  )
}

resource "aws_db_instance" "rds" {
  identifier             = "${var.name_prefix}-db"
  engine                 = "postgres"
  engine_version         = var.engine_version
  instance_class         = var.instance_class
  allocated_storage      = var.allocated_storage
  storage_type           = "gp2"
  db_name                = var.database_name
  username               = var.database_username
  password               = var.database_password
  port                   = 5432
  db_subnet_group_name   = aws_db_subnet_group.rds.name
  parameter_group_name   = aws_db_parameter_group.rds.name
  vpc_security_group_ids = var.security_group_ids
  
  # Backup settings
  backup_retention_period = var.environment == "prod" ? 7 : 1
  backup_window           = "03:00-04:00"  # UTC
  maintenance_window      = "mon:04:00-mon:05:00"  # UTC
  
  # Disable options that are expensive for dev/test
  skip_final_snapshot     = var.environment == "prod" ? false : true
  final_snapshot_identifier = var.environment == "prod" ? "${var.name_prefix}-db-final-snapshot" : null
  deletion_protection     = var.environment == "prod" ? true : false
  
  # Enhanced monitoring
  monitoring_interval = var.environment == "prod" ? 60 : 0
  monitoring_role_arn = var.environment == "prod" ? aws_iam_role.rds_monitoring[0].arn : null
  
  # Encryption
  storage_encrypted = true
  
  # Performance Insights for better monitoring
  performance_insights_enabled          = var.environment == "prod" ? true : false
  performance_insights_retention_period = var.environment == "prod" ? 7 : null
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-db"
    }
  )
}

# IAM role for enhanced monitoring (only created for prod)
resource "aws_iam_role" "rds_monitoring" {
  count = var.environment == "prod" ? 1 : 0
  
  name = "${var.name_prefix}-rds-monitoring-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-rds-monitoring-role"
    }
  )
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  count = var.environment == "prod" ? 1 : 0
  
  role       = aws_iam_role.rds_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
