resource "aws_ecs_cluster" "ecommerce_cluster" {
  name = "${var.environment}-${var.cluster_name}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Environment = var.environment
    Project     = "twelve-factor-ecommerce"
  }
}

resource "aws_ecs_task_definition" "product_service" {
  family                   = "${var.environment}-product-service"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "product-service"
      image     = "${var.ecr_repository_url}:${var.image_tag}"
      essential = true
      
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]
      
      environment = [
        { 
          name  = "SPRING_PROFILES_ACTIVE", 
          value = var.environment 
        },
        { 
          name  = "SERVER_PORT", 
          value = "8080" 
        },
        { 
          name  = "SPRING_KAFKA_BOOTSTRAP_SERVERS", 
          value = var.kafka_bootstrap_servers 
        }
      ]
      
      secrets = [
        {
          name      = "SPRING_DATASOURCE_URL"
          valueFrom = "${var.secrets_arn}:database_url::"
        },
        {
          name      = "SPRING_DATASOURCE_USERNAME"
          valueFrom = "${var.secrets_arn}:database_username::"
        },
        {
          name      = "SPRING_DATASOURCE_PASSWORD"
          valueFrom = "${var.secrets_arn}:database_password::"
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.environment}-product-service"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
      
      healthCheck = {
        command     = ["CMD-SHELL", "wget -q --spider http://localhost:8080/actuator/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Environment = var.environment
    Project     = "twelve-factor-ecommerce"
    Service     = "product-service"
  }
}

resource "aws_ecs_service" "product_service" {
  name                               = "${var.environment}-product-service"
  cluster                            = aws_ecs_cluster.ecommerce_cluster.id
  task_definition                    = aws_ecs_task_definition.product_service.arn
  desired_count                      = var.service_desired_count
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"
  health_check_grace_period_seconds  = 60
  force_new_deployment               = true
  
  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.product_service_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.product_service.arn
    container_name   = "product-service"
    container_port   = 8080
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  deployment_controller {
    type = "ECS"
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = {
    Environment = var.environment
    Project     = "twelve-factor-ecommerce"
    Service     = "product-service"
  }
}

resource "aws_security_group" "product_service_sg" {
  name        = "${var.environment}-product-service-sg"
  description = "Security group for product service"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
    description     = "Allow inbound HTTP traffic from ALB"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name        = "${var.environment}-product-service-sg"
    Environment = var.environment
    Project     = "twelve-factor-ecommerce"
  }
}

resource "aws_lb" "product_service" {
  name               = "${var.environment}-product-service-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = var.environment == "prod" ? true : false

  access_logs {
    bucket  = var.logs_bucket
    prefix  = "${var.environment}-product-service-alb"
    enabled = true
  }

  tags = {
    Name        = "${var.environment}-product-service-alb"
    Environment = var.environment
    Project     = "twelve-factor-ecommerce"
  }
}

resource "aws_lb_target_group" "product_service" {
  name                 = "${var.environment}-product-service-tg"
  port                 = 8080
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "ip"
  deregistration_delay = 30

  health_check {
    enabled             = true
    interval            = 30
    path                = "/actuator/health"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    matcher             = "200"
  }

  tags = {
    Name        = "${var.environment}-product-service-tg"
    Environment = var.environment
    Project     = "twelve-factor-ecommerce"
  }
}

resource "aws_lb_listener" "product_service_http" {
  load_balancer_arn = aws_lb.product_service.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "product_service_https" {
  load_balancer_arn = aws_lb.product_service.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.product_service.arn
  }
}

resource "aws_security_group" "alb_sg" {
  name        = "${var.environment}-product-service-alb-sg"
  description = "Security group for product service ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow inbound HTTP traffic"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow inbound HTTPS traffic"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name        = "${var.environment}-product-service-alb-sg"
    Environment = var.environment
    Project     = "twelve-factor-ecommerce"
  }
}

# IAM Roles for ECS tasks
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.environment}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
    Project     = "twelve-factor-ecommerce"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_task_execution_secrets" {
  name = "${var.environment}-ecs-task-secrets-policy"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue"
        ],
        Effect   = "Allow",
        Resource = var.secrets_arn
      }
    ]
  })
}

resource "aws_iam_role" "ecs_task_role" {
  name = "${var.environment}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
    Project     = "twelve-factor-ecommerce"
  }
}

resource "aws_iam_role_policy" "ecs_task_role_policy" {
  name = "${var.environment}-ecs-task-role-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:CreateLogGroup"
        ],
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Action = [
          "kafka:DescribeCluster",
          "kafka:GetBootstrapBrokers",
          "kafka:ListScramSecrets"
        ],
        Effect   = "Allow",
        Resource = var.msk_arn
      }
    ]
  })
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "product_service" {
  name              = "/ecs/${var.environment}-product-service"
  retention_in_days = var.environment == "prod" ? 30 : 14

  tags = {
    Environment = var.environment
    Project     = "twelve-factor-ecommerce"
    Service     = "product-service"
  }
}

# Auto Scaling for product service
resource "aws_appautoscaling_target" "product_service" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${aws_ecs_cluster.ecommerce_cluster.name}/${aws_ecs_service.product_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "product_service_cpu" {
  name               = "${var.environment}-product-service-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.product_service.resource_id
  scalable_dimension = aws_appautoscaling_target.product_service.scalable_dimension
  service_namespace  = aws_appautoscaling_target.product_service.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}
