resource "aws_cloudwatch_log_group" "kafka_ui" {
  name              = "/ecs/kafka-ui-monitor"
  retention_in_days = 7
  tags              = var.tags
}

resource "aws_ecs_task_definition" "kafka_ui" {
  family                   = "kafka-ui-monitor"
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory

  container_definitions = jsonencode([
    {
      name      = "kafka-ui"
      image     = "provectuslabs/kafka-ui:latest"
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
          name  = "KAFKA_CLUSTERS_0_NAME"
          value = "${var.name_prefix}-kafka"
        },
        {
          name  = "KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS"
          value = var.kafka_bootstrap_servers
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.kafka_ui.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = var.tags
}

resource "aws_ecs_service" "kafka_ui" {
  name            = "kafka-ui-monitor"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.kafka_ui.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [var.security_group_id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.kafka_ui.arn
    container_name   = "kafka-ui"
    container_port   = 8080
  }

  tags = var.tags
}

# Application Load Balancer for Kafka UI
resource "aws_lb" "kafka_ui" {
  name               = "${var.name_prefix}-kui-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.alb_subnet_ids

  tags = var.tags
}

resource "aws_lb_target_group" "kafka_ui" {
  name        = "${var.name_prefix}-kui-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  
  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200-399"
  }

  tags = var.tags
}

resource "aws_lb_listener" "kafka_ui" {
  load_balancer_arn = aws_lb.kafka_ui.arn
  port              = 80
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kafka_ui.arn
  }
}

# Security Group Rule to allow Kafka-UI to connect to MSK
resource "aws_security_group_rule" "allow_kafka_ui_to_msk" {
  type                     = "ingress"
  from_port                = 9092
  to_port                  = 9092
  protocol                 = "tcp"
  source_security_group_id = var.security_group_id
  security_group_id        = var.msk_security_group_id
  description              = "Allow Kafka-UI to connect to MSK"
}

data "aws_region" "current" {}
