resource "aws_db_subnet_group" "ecommerce" {
  name       = "${var.environment}-ecommerce-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name        = "${var.environment}-ecommerce-db-subnet-group"
    Environment = var.environment
    Project     = "twelve-factor-ecommerce"
  }
}

resource "aws_security_group" "db_sg" {
  name        = "${var.environment}-ecommerce-db-sg"
  description = "Security group for RDS database"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = var.client_security_groups
    description     = "Allow PostgreSQL traffic from client security groups"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name        = "${var.environment}-ecommerce-db-sg"
    Environment = var.environment
    Project     = "twelve-factor-ecommerce"
  }
}

resource "aws_db_parameter_group" "ecommerce" {
  name   = "${var.environment}-ecommerce-db-params"
  family = "postgres13"

  parameter {
    name  = "log_statement"
    value = var.environment == "prod" ? "none" : "ddl"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = var.environment == "prod" ? "1000" : "100"
  }

  tags = {
    Name        = "${var.environment}-ecommerce-db-params"
    Environment = var.environment
    Project     = "twelve-factor-ecommerce"
  }
}

resource "aws_db_instance" "ecommerce" {
  identifier             = "${var.environment}-ecommerce-db"
  engine                 = "postgres"
  engine_version         = "13.7"
  instance_class         = var.instance_class
  allocated_storage      = var.allocated_storage
  max_allocated_storage  = var.max_allocated_storage
  storage_type           = "gp3"
  storage_encrypted      = true
  db_name                = "ecommerce"
  username               = var.username
  password               = var.password
  parameter_group_name   = aws_db_parameter_group.ecommerce.name
  db_subnet_group_name   = aws_db_subnet_group.ecommerce.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot    = var.environment != "prod"
  deletion_protection    = var.environment == "prod"
  backup_retention_period = var.environment == "prod" ? 7 : 1
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:30-sun:05:30"
  multi_az               = var.environment == "prod"
  publicly_accessible    = false
  apply_immediately      = var.environment != "prod"

  performance_insights_enabled          = true
  performance_insights_retention_period = var.environment == "prod" ? 7 : 7

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  tags = {
    Name        = "${var.environment}-ecommerce-db"
    Environment = var.environment
    Project     = "twelve-factor-ecommerce"
  }

  lifecycle {
    prevent_destroy = var.environment == "prod"
  }
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "${var.environment}/ecommerce/db-credentials"
  description = "Database credentials for the ecommerce application"
  
  recovery_window_in_days = var.environment == "prod" ? 30 : 0
  
  tags = {
    Name        = "${var.environment}-ecommerce-db-credentials"
    Environment = var.environment
    Project     = "twelve-factor-ecommerce"
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  
  secret_string = jsonencode({
    database_username = aws_db_instance.ecommerce.username
    database_password = var.password
    database_url      = "jdbc:postgresql://${aws_db_instance.ecommerce.endpoint}/${aws_db_instance.ecommerce.db_name}"
  })
}
