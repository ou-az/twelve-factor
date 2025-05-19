# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.environment}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# CloudWatch Log Group for ECS services
resource "aws_cloudwatch_log_group" "ecs_logs" {
  for_each = toset(var.services)
  
  name              = "/ecs/${var.project_name}-${var.environment}/${each.key}"
  retention_in_days = 30
}

# Task execution role for ECS tasks
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-${var.environment}-task-execution-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Attach policies to task execution role
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Task role for ECS tasks
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-${var.environment}-task-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Policy for ECS task role
resource "aws_iam_policy" "ecs_task_role_policy" {
  name        = "${var.project_name}-${var.environment}-task-role-policy"
  description = "Policy for ECS task role"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach policy to task role
resource "aws_iam_role_policy_attachment" "ecs_task_role_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_role_policy.arn
}

# ALB for services
resource "aws_lb" "main" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnets
  
  enable_deletion_protection = false
  
  tags = {
    Name = "${var.project_name}-${var.environment}-alb"
  }
}

# ALB security group
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 443
    to_port     = 443
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
    Name = "${var.project_name}-${var.environment}-alb-sg"
  }
}

# ECS service security group
resource "aws_security_group" "ecs_service_sg" {
  name        = "${var.project_name}-${var.environment}-ecs-service-sg"
  description = "Security group for ECS services"
  vpc_id      = var.vpc_id
  
  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.alb_sg.id]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "${var.project_name}-${var.environment}-ecs-service-sg"
  }
}

# ALB target groups, services, and task definitions for each service
locals {
  # Database environment variables for patient-service
  patient_service_db_env = [
    { name = "SPRING_DATASOURCE_URL", value = "jdbc:postgresql://${aws_db_instance.postgres.endpoint}/healthcare_patient" },
    { name = "SPRING_DATASOURCE_USERNAME", value = "healthcare_user" }
  ]
  
  # Database environment variables for appointment-service
  appointment_service_db_env = [
    { name = "SPRING_DATASOURCE_URL", value = "jdbc:postgresql://${aws_db_instance.postgres.endpoint}/healthcare_appointment" },
    { name = "SPRING_DATASOURCE_USERNAME", value = "healthcare_user" },
    { name = "SPRING_DATA_MONGODB_URI", value = "mongodb://${aws_instance.mongodb.private_ip}:27017/healthcare_appointment" },
    { name = "SPRING_REDIS_HOST", value = aws_elasticache_cluster.redis.cache_nodes.0.address }
  ]
}

# Default target group for ALB
resource "aws_lb_target_group" "default" {
  name     = "${var.project_name}-${var.environment}-default"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  
  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    matcher             = "200"
  }
}

# ALB listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.default.arn
  }
}

# Create target groups, task definitions, and services for each service
resource "aws_lb_target_group" "service" {
  for_each = toset(var.services)
  
  name     = "hc-${var.environment}-${substr(each.key, 0, 16)}-ip-tg"
  port     = lookup(var.container_configs[each.key], "container_port", 80)
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "ip"
  
  health_check {
    enabled             = true
    interval            = 30
    path                = lookup(var.container_configs[each.key], "health_check_path", "/")
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    matcher             = "200"
  }
  
  # Give time for targets to drain before destroying the target group
  lifecycle {
    create_before_destroy = true
  }
}

# ALB listener rules for each service
resource "aws_lb_listener_rule" "service" {
  for_each = toset(var.services)
  
  listener_arn = aws_lb_listener.http.arn
  priority     = 100 + index(var.services, each.key)
  
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service[each.key].arn
  }
  
  condition {
    path_pattern {
      values = ["/${each.key}/*"]
    }
  }
}

# PostgreSQL RDS instance for shared database
resource "aws_db_instance" "postgres" {
  allocated_storage       = 20
  storage_type            = "gp2"
  engine                  = "postgres"
  engine_version          = "13"
  instance_class          = "db.t3.micro"
  identifier              = "${var.project_name}-${var.environment}-postgres"
  username                = "postgres"
  password                = "postgres"  # In production, use AWS Secrets Manager
  parameter_group_name    = "default.postgres13"
  publicly_accessible     = false
  skip_final_snapshot     = true
  backup_retention_period = 7
  vpc_security_group_ids  = [aws_security_group.postgres_sg.id]
  db_subnet_group_name    = aws_db_subnet_group.postgres.name
  
  tags = {
    Name = "${var.project_name}-${var.environment}-postgres"
  }
}

# DB subnet group for PostgreSQL
resource "aws_db_subnet_group" "postgres" {
  name       = "${var.project_name}-${var.environment}-postgres-subnet-group"
  subnet_ids = var.private_subnets
  
  tags = {
    Name = "${var.project_name}-${var.environment}-postgres-subnet-group"
  }
}

# Security group for PostgreSQL
resource "aws_security_group" "postgres_sg" {
  name        = "${var.project_name}-${var.environment}-postgres-sg"
  description = "Security group for PostgreSQL"
  vpc_id      = var.vpc_id
  
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_service_sg.id]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "${var.project_name}-${var.environment}-postgres-sg"
  }
}

# Redis ElastiCache cluster
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "${var.project_name}-${var.environment}-redis"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis6.x"
  engine_version       = "6.x"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.redis.name
  security_group_ids   = [aws_security_group.redis_sg.id]
  
  tags = {
    Name = "${var.project_name}-${var.environment}-redis"
  }
}

# ElastiCache subnet group for Redis
resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.project_name}-${var.environment}-redis-subnet-group"
  subnet_ids = var.private_subnets
}

# Security group for Redis
resource "aws_security_group" "redis_sg" {
  name        = "${var.project_name}-${var.environment}-redis-sg"
  description = "Security group for Redis"
  vpc_id      = var.vpc_id
  
  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_service_sg.id]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "${var.project_name}-${var.environment}-redis-sg"
  }
}

# EC2 instance for MongoDB (simplified, in production would use DocumentDB or MongoDB Atlas)
resource "aws_instance" "mongodb" {
  ami                    = "ami-0230bd60aa48260c6"  # Amazon Linux 2023 AMI for us-east-1
  instance_type          = "t3.micro"
  subnet_id              = var.private_subnets[0]
  vpc_security_group_ids = [aws_security_group.mongodb_sg.id]
  associate_public_ip_address = false
  
  user_data = <<-EOT
    #!/bin/bash
    amazon-linux-extras install docker -y
    systemctl start docker
    systemctl enable docker
    docker run -d --name mongodb -p 27017:27017 -v mongodb_data:/data/db mongo:5.0
    EOT
  
  tags = {
    Name = "${var.project_name}-${var.environment}-mongodb"
  }
}

# Security group for MongoDB
resource "aws_security_group" "mongodb_sg" {
  name        = "${var.project_name}-${var.environment}-mongodb-sg"
  description = "Security group for MongoDB"
  vpc_id      = var.vpc_id
  
  ingress {
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_service_sg.id]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "${var.project_name}-${var.environment}-mongodb-sg"
  }
}

# ECS task definitions and services
resource "aws_ecs_task_definition" "service" {
  for_each = toset(var.services)
  
  family                   = "${var.project_name}-${var.environment}-${each.key}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = lookup(var.container_configs[each.key], "cpu", 256)
  memory                   = lookup(var.container_configs[each.key], "memory", 512)
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  
  container_definitions = jsonencode([
    {
      name         = each.key
      image        = "${lookup(var.ecr_repositories, each.key, "")}:latest"
      essential    = true
      portMappings = [
        {
          containerPort = lookup(var.container_configs[each.key], "container_port", 80)
          hostPort      = lookup(var.container_configs[each.key], "host_port", 80)
          protocol      = "tcp"
        }
      ]
      environment = concat(
        lookup(var.container_configs[each.key], "environment_variables", []),
        each.key == "patient-service" ? local.patient_service_db_env : (each.key == "appointment-service" ? local.appointment_service_db_env : [])
      )
      secrets = lookup(var.container_configs[each.key], "secrets", [])
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs[each.key].name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = each.key
        }
      }
    }
  ])
}

resource "aws_ecs_service" "service" {
  for_each = toset(var.services)
  
  name            = "${var.project_name}-${var.environment}-${each.key}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.service[each.key].arn
  launch_type     = "FARGATE"
  desired_count   = lookup(var.container_configs[each.key], "desired_count", 1)
  
  network_configuration {
    subnets          = var.private_subnets
    security_groups  = [aws_security_group.ecs_service_sg.id]
    assign_public_ip = false
  }
  
  load_balancer {
    target_group_arn = aws_lb_target_group.service[each.key].arn
    container_name   = each.key
    container_port   = lookup(var.container_configs[each.key], "container_port", 80)
  }
  
  depends_on = [
    aws_lb_listener.http
  ]
  
  # Use deployment circuit breaker to roll back failed deployments
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
}
