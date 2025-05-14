resource "aws_msk_cluster" "ecommerce_kafka" {
  cluster_name           = "${var.environment}-ecommerce-kafka"
  kafka_version          = var.kafka_version
  number_of_broker_nodes = var.broker_count

  broker_node_group_info {
    instance_type   = var.broker_instance_type
    client_subnets  = var.subnet_ids
    security_groups = [aws_security_group.kafka_sg.id]
    storage_info {
      ebs_storage_info {
        volume_size = var.broker_volume_size
      }
    }
  }

  configuration_info {
    arn      = aws_msk_configuration.kafka_config.arn
    revision = aws_msk_configuration.kafka_config.latest_revision
  }

  encryption_info {
    encryption_in_transit {
      client_broker = "TLS"
      in_cluster    = true
    }
  }

  open_monitoring {
    prometheus {
      jmx_exporter {
        enabled_in_broker = true
      }
      node_exporter {
        enabled_in_broker = true
      }
    }
  }

  logging_info {
    broker_logs {
      cloudwatch_logs {
        enabled   = true
        log_group = aws_cloudwatch_log_group.kafka_logs.name
      }
      s3 {
        enabled = true
        bucket  = var.logs_bucket
        prefix  = "kafka-logs/${var.environment}"
      }
    }
  }

  tags = {
    Environment = var.environment
    Project     = "twelve-factor-ecommerce"
  }
}

resource "aws_msk_configuration" "kafka_config" {
  name              = "${var.environment}-kafka-config"
  kafka_versions    = [var.kafka_version]
  server_properties = <<PROPERTIES
auto.create.topics.enable=true
delete.topic.enable=true
default.replication.factor=${min(3, var.broker_count)}
min.insync.replicas=${min(2, var.broker_count)}
num.io.threads=8
num.network.threads=5
num.partitions=3
num.replica.fetchers=2
replica.lag.time.max.ms=30000
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600
socket.send.buffer.bytes=102400
unclean.leader.election.enable=false
zookeeper.session.timeout.ms=18000
PROPERTIES
}

resource "aws_security_group" "kafka_sg" {
  name        = "${var.environment}-kafka-sg"
  description = "Security group for MSK cluster"
  vpc_id      = var.vpc_id

  # Allow inbound traffic on Kafka broker ports
  ingress {
    from_port       = 9092
    to_port         = 9092
    protocol        = "tcp"
    security_groups = var.client_security_groups
    description     = "Allow PLAINTEXT Kafka traffic from client security groups"
  }

  ingress {
    from_port       = 9094
    to_port         = 9094
    protocol        = "tcp"
    security_groups = var.client_security_groups
    description     = "Allow TLS Kafka traffic from client security groups"
  }

  ingress {
    from_port       = 9096
    to_port         = 9096
    protocol        = "tcp"
    security_groups = var.client_security_groups
    description     = "Allow SASL/TLS Kafka traffic from client security groups"
  }

  ingress {
    from_port       = 2181
    to_port         = 2181
    protocol        = "tcp"
    security_groups = var.client_security_groups
    description     = "Allow ZooKeeper traffic from client security groups"
  }

  # Inter-broker communication
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name        = "${var.environment}-kafka-sg"
    Environment = var.environment
    Project     = "twelve-factor-ecommerce"
  }
}

resource "aws_cloudwatch_log_group" "kafka_logs" {
  name              = "/msk/${var.environment}-kafka-logs"
  retention_in_days = var.environment == "prod" ? 30 : 14

  tags = {
    Environment = var.environment
    Project     = "twelve-factor-ecommerce"
  }
}
