provider "aws" {
  region = var.aws_region
}

# Create a VPC for the database if needed
resource "aws_vpc" "db_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = {
    Name = "${var.name_prefix}-vpc"
  }
}

# Create private subnets for the database
resource "aws_subnet" "db_subnet_1" {
  vpc_id            = aws_vpc.db_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"
  
  tags = {
    Name = "${var.name_prefix}-db-subnet-1"
  }
}

resource "aws_subnet" "db_subnet_2" {
  vpc_id            = aws_vpc.db_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}b"
  
  tags = {
    Name = "${var.name_prefix}-db-subnet-2"
  }
}

# Create a DB subnet group
resource "aws_db_subnet_group" "db_subnet_group" {
  name        = "${var.name_prefix}-db-subnet-group"
  description = "RDS subnet group for ${var.name_prefix}"
  subnet_ids  = [aws_subnet.db_subnet_1.id, aws_subnet.db_subnet_2.id]
  
  tags = {
    Name = "${var.name_prefix}-db-subnet-group"
  }
}

# Create security group for the database
resource "aws_security_group" "db_sg" {
  name        = "${var.name_prefix}-db-sg"
  description = "Security group for ${var.name_prefix} RDS instance"
  vpc_id      = aws_vpc.db_vpc.id
  
  # Allow PostgreSQL traffic from anywhere (you should restrict this in production)
  ingress {
    description = "PostgreSQL"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "${var.name_prefix}-db-sg"
  }
}

# Create an internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.db_vpc.id
  
  tags = {
    Name = "${var.name_prefix}-igw"
  }
}

# Create a route table for public access
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.db_vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  
  tags = {
    Name = "${var.name_prefix}-public-route-table"
  }
}

# Associate route table with subnets
resource "aws_route_table_association" "subnet1_association" {
  subnet_id      = aws_subnet.db_subnet_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "subnet2_association" {
  subnet_id      = aws_subnet.db_subnet_2.id
  route_table_id = aws_route_table.public.id
}

# Create DB parameter group
resource "aws_db_parameter_group" "db_param_group" {
  name        = "${var.name_prefix}-db-param-group"
  family      = "postgres17"  # Using postgres17 for latest features and performance
  description = "Parameter group for ${var.name_prefix} RDS instance"
  
  parameter {
    name  = "log_statement"
    value = "none"
  }
  
  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }
  
  tags = {
    Name = "${var.name_prefix}-db-param-group"
  }
}

# Create the RDS instance
resource "aws_db_instance" "postgres" {
  identifier             = "${var.name_prefix}-db"
  engine                 = "postgres"
  engine_version         = "17.5"  # Using latest PostgreSQL version for best features and performance
  instance_class         = var.instance_class
  allocated_storage      = var.allocated_storage
  db_name                = var.database_name
  username               = var.database_username
  password               = var.database_password
  port                   = 5432
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  parameter_group_name   = aws_db_parameter_group.db_param_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  publicly_accessible    = true  # Set to true for testing only
  
  # Disable backups and snapshots for test environment
  backup_retention_period = 0
  skip_final_snapshot     = true
  deletion_protection     = false
  
  # Disable encryption for test environment (enable in production)
  storage_encrypted = false
  
  tags = {
    Name = "${var.name_prefix}-db"
  }
}
