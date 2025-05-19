# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = var.ecs_cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# CloudWatch Log Group for ECS services
resource "aws_cloudwatch_log_group" "ecs_logs" {
  for_each = toset(var.all_services)
  
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
          "ecr:BatchGetImage",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "servicediscovery:RegisterInstance",
          "servicediscovery:DeregisterInstance",
          "servicediscovery:DiscoverInstances",
          "servicediscovery:GetInstancesHealthStatus",
          "route53:GetHealthCheck"
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

# ECS capacity providers - mix of Fargate and EC2
resource "aws_ecs_cluster_capacity_providers" "cluster_capacity" {
  cluster_name = aws_ecs_cluster.main.name
  
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]
  
  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 1
  }
}

# EFS for persistent storage (for database containers)
resource "aws_efs_file_system" "ecs_storage" {
  count = var.efs_creation ? 1 : 0
  
  creation_token = "${var.project_name}-${var.environment}-efs"
  encrypted      = true
  
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
  
  tags = {
    Name = "${var.project_name}-${var.environment}-efs"
  }
}

resource "aws_efs_mount_target" "ecs_storage_mount" {
  count = var.efs_creation ? length(var.private_subnets) : 0
  
  file_system_id  = aws_efs_file_system.ecs_storage[0].id
  subnet_id       = var.private_subnets[count.index]
  security_groups = [aws_security_group.efs_sg[0].id]
}

resource "aws_security_group" "efs_sg" {
  count = var.efs_creation ? 1 : 0
  
  name        = "${var.project_name}-${var.environment}-efs-sg"
  description = "Security group for EFS"
  vpc_id      = var.vpc_id
  
  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Application Load Balancer for app services
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
}

# ECS service security group
resource "aws_security_group" "ecs_service_sg" {
  name        = "${var.project_name}-${var.environment}-ecs-service-sg"
  description = "Security group for ECS services"
  vpc_id      = var.vpc_id
  
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ALB Target groups and listener rules for app services
resource "aws_lb_target_group" "app_service" {
  for_each = toset(var.app_services)
  
  name     = "hc-${var.environment}-${substr(each.key, 0, 16)}-tg"
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
}

# Default target group for ALB
resource "aws_lb_target_group" "default" {
  name     = "${var.project_name}-${var.environment}-default"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "ip"
  
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

# ALB listener rules for app services
resource "aws_lb_listener_rule" "app_service" {
  for_each = toset(var.app_services)
  
  listener_arn = aws_lb_listener.http.arn
  priority     = 100 + index(var.app_services, each.key)
  
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_service[each.key].arn
  }
  
  condition {
    path_pattern {
      values = ["/${each.key}/*"]
    }
  }
}

# ECS Task Definitions for all services
resource "aws_ecs_task_definition" "service" {
  for_each = toset(var.all_services)
  
  family                   = "${var.project_name}-${var.environment}-${each.key}"
  network_mode             = lookup(var.container_configs[each.key], "network_mode", "awsvpc")
  requires_compatibilities = lookup(var.container_configs[each.key], "use_fargate", true) ? ["FARGATE"] : []
  cpu                      = lookup(var.container_configs[each.key], "cpu", 256)
  memory                   = lookup(var.container_configs[each.key], "memory", 512)
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  
  # Add volume for data persistence if required
  dynamic "volume" {
    for_each = lookup(var.container_configs[each.key], "requires_volume", false) ? [1] : []
    
    content {
      name = lookup(var.container_configs[each.key], "volume_name", "")
      
      efs_volume_configuration {
        file_system_id     = var.efs_creation ? aws_efs_file_system.ecs_storage[0].id : ""
        root_directory     = "/"
        transit_encryption = "ENABLED"
        
        authorization_config {
          access_point_id = aws_efs_access_point.ecs_ap[each.key].id
          iam             = "ENABLED"
        }
      }
    }
  }
  
  container_definitions = jsonencode([
    {
      name         = each.key
      image        = "${lookup(var.ecr_repositories, each.key, "")}:latest"
      essential    = lookup(var.container_configs[each.key], "essential", true)
      
      portMappings = [
        {
          containerPort = lookup(var.container_configs[each.key], "container_port", 80)
          hostPort      = lookup(var.container_configs[each.key], "container_port", 80)
          protocol      = "tcp"
        }
      ]
      
      environment = lookup(var.container_configs[each.key], "environment_variables", [])
      secrets     = lookup(var.container_configs[each.key], "secrets", [])
      
      mountPoints = lookup(var.container_configs[each.key], "requires_volume", false) ? [
        {
          sourceVolume  = lookup(var.container_configs[each.key], "volume_name", "")
          containerPath = lookup(var.container_configs[each.key], "volume_mount_path", "")
          readOnly      = false
        }
      ] : []
      
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

# EFS access points for each container that needs persistent storage
resource "aws_efs_access_point" "ecs_ap" {
  for_each = { for s in var.all_services : s => s if lookup(var.container_configs[s], "requires_volume", false) }
  
  file_system_id = var.efs_creation ? aws_efs_file_system.ecs_storage[0].id : ""
  
  posix_user {
    gid = 1000
    uid = 1000
  }
  
  root_directory {
    path = "/${each.key}"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "755"
    }
  }
  
  tags = {
    Name = "${var.project_name}-${var.environment}-${each.key}-ap"
  }
}

# ECS services for application containers
resource "aws_ecs_service" "app_service" {
  for_each = toset(var.app_services)
  
  name            = "${var.project_name}-${var.environment}-${each.key}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.service[each.key].arn
  launch_type     = lookup(var.container_configs[each.key], "use_fargate", true) ? "FARGATE" : "EC2"
  desired_count   = lookup(var.container_configs[each.key], "desired_count", 1)
  
  network_configuration {
    subnets          = var.private_subnets
    security_groups  = [aws_security_group.ecs_service_sg.id]
    assign_public_ip = false
  }
  
  load_balancer {
    target_group_arn = aws_lb_target_group.app_service[each.key].arn
    container_name   = each.key
    container_port   = lookup(var.container_configs[each.key], "container_port", 80)
  }
  
  # Service discovery registration
  dynamic "service_registries" {
    for_each = lookup(var.container_configs[each.key], "service_registry_enabled", true) ? [1] : []
    
    content {
      registry_arn = var.service_discovery_map[each.key]
    }
  }
  
  # Use deployment circuit breaker to roll back failed deployments
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
  
  depends_on = [
    aws_lb_listener.http
  ]
}

# ECS services for database containers
resource "aws_ecs_service" "db_service" {
  for_each = toset(var.db_services)
  
  name            = "${var.project_name}-${var.environment}-${each.key}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.service[each.key].arn
  launch_type     = lookup(var.container_configs[each.key], "use_fargate", true) ? "FARGATE" : "EC2"
  desired_count   = lookup(var.container_configs[each.key], "desired_count", 1)
  
  network_configuration {
    subnets          = var.private_subnets
    security_groups  = [aws_security_group.ecs_service_sg.id]
    assign_public_ip = false
  }
  
  # Service discovery registration
  dynamic "service_registries" {
    for_each = lookup(var.container_configs[each.key], "service_registry_enabled", true) ? [1] : []
    
    content {
      registry_arn = var.service_discovery_map[each.key]
    }
  }
  
  # For databases, we want to be more careful with updates
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
}
