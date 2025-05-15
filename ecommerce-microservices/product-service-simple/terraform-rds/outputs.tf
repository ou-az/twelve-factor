output "rds_endpoint" {
  description = "The endpoint of the PostgreSQL database"
  value       = aws_db_instance.postgres.endpoint
}

output "rds_address" {
  description = "The hostname of the PostgreSQL database"
  value       = aws_db_instance.postgres.address
}

output "rds_port" {
  description = "The port of the PostgreSQL database"
  value       = aws_db_instance.postgres.port
}

output "database_name" {
  description = "The name of the PostgreSQL database"
  value       = aws_db_instance.postgres.db_name
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.db_vpc.id
}

output "subnet_ids" {
  description = "The IDs of the subnets"
  value       = [aws_subnet.db_subnet_1.id, aws_subnet.db_subnet_2.id]
}
