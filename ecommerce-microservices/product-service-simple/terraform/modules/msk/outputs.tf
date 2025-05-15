output "cluster_arn" {
  description = "ARN of the MSK cluster"
  value       = aws_msk_cluster.kafka.arn
}

output "bootstrap_brokers" {
  description = "Connection host:port pairs of Kafka brokers (PLAINTEXT)"
  value       = aws_msk_cluster.kafka.bootstrap_brokers
}

output "bootstrap_brokers_tls" {
  description = "Connection host:port pairs of Kafka brokers (TLS)"
  value       = aws_msk_cluster.kafka.bootstrap_brokers_tls
}

output "zookeeper_connect_string" {
  description = "Connection string for ZooKeeper"
  value       = aws_msk_cluster.kafka.zookeeper_connect_string
}
