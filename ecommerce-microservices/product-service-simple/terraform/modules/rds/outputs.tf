output "endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.rds.endpoint
}

output "address" {
  description = "RDS instance address (hostname)"
  value       = aws_db_instance.rds.address
}

output "port" {
  description = "RDS instance port"
  value       = aws_db_instance.rds.port
}

output "database_name" {
  description = "Name of the database"
  value       = aws_db_instance.rds.db_name
}

output "instance_id" {
  description = "ID of the RDS instance"
  value       = aws_db_instance.rds.id
}
