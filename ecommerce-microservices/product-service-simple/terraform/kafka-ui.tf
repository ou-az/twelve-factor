# Deploy Kafka UI for monitoring and management
module "kafka_ui" {
  source = "./modules/kafka-ui"
  
  name_prefix           = local.name_prefix
  ecs_cluster_id        = module.ecs.cluster_id
  execution_role_arn    = module.ecs.execution_role_arn
  task_role_arn         = module.ecs.task_role_arn
  vpc_id                = module.vpc.vpc_id
  subnet_ids            = module.vpc.private_subnet_ids
  alb_subnet_ids        = module.vpc.public_subnet_ids
  security_group_id     = module.security_groups.ecs_security_group_id
  alb_security_group_id = module.security_groups.alb_security_group_id
  # Use the MSK security group from the security_groups module
  msk_security_group_id = module.security_groups.kafka_security_group_id
  kafka_bootstrap_servers = module.msk.bootstrap_brokers
  
  cpu          = 512
  memory       = 1024
  desired_count = 1
  
  tags = local.common_tags
}

# Output the Kafka UI URL
output "kafka_ui_url" {
  description = "URL to access the Kafka UI"
  value       = module.kafka_ui.kafka_ui_url
}
