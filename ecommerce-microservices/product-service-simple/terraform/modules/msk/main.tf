resource "aws_msk_cluster" "kafka" {
  cluster_name           = "${var.name_prefix}-kafka-cluster"
  kafka_version          = var.kafka_version
  number_of_broker_nodes = var.number_of_broker_nodes
  
  broker_node_group_info {
    instance_type   = var.broker_instance_type
    client_subnets  = var.subnet_ids
    security_groups = var.security_group_ids != null ? var.security_group_ids : []
    
    storage_info {
      ebs_storage_info {
        volume_size = var.broker_volume_size
      }
    }
  }
  
  encryption_info {
    encryption_in_transit {
      client_broker = "TLS_PLAINTEXT"
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
        log_group = aws_cloudwatch_log_group.msk_logs.name
      }
    }
  }
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-kafka-cluster"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_log_group" "msk_logs" {
  name              = "/msk/${var.name_prefix}-kafka-cluster"
  retention_in_days = 7
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-kafka-logs"
    }
  )
}

# Create a configuration for the MSK cluster
resource "aws_msk_configuration" "kafka_config" {
  name              = "${var.name_prefix}-kafka-config"
  kafka_versions    = [var.kafka_version]
  description       = "Configuration for ${var.name_prefix} MSK cluster"
  
  server_properties = <<PROPERTIES
auto.create.topics.enable=true
delete.topic.enable=true
log.retention.hours=24
log.segment.bytes=1073741824
num.io.threads=8
num.network.threads=5
num.partitions=2
num.replica.fetchers=2
replica.lag.time.max.ms=30000
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600
socket.send.buffer.bytes=102400
unclean.leader.election.enable=true
zookeeper.session.timeout.ms=18000
PROPERTIES
}
