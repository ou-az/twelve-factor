# AWS ECS Deployment with Terraform

This document outlines the AWS deployment architecture and procedures for the Spring Boot Product Service with Kafka integration.

## Architecture Overview

This Terraform implementation deploys the following AWS resources:

![AWS Architecture Diagram](https://d2908q01vomqb2.cloudfront.net/1b6453892473a467d07372d45eb05abc2031647a/2018/01/26/Slide5.png)

### Core Infrastructure Components:

1. **VPC with Public/Private Subnets**:
   - Private subnets for application and data tier
   - Public subnets for load balancer
   - NAT Gateways for outbound connectivity

2. **ECS Fargate Cluster**:
   - Containerized Spring Boot application
   - Auto-scaling based on CPU and memory usage
   - Task definitions with health checks

3. **Amazon MSK (Managed Streaming for Kafka)**:
   - Fully managed Kafka service
   - Multi-AZ deployment for high availability
   - Custom configuration for topic auto-creation

4. **RDS PostgreSQL**:
   - Managed PostgreSQL database
   - Multi-AZ option for production
   - Automated backups and retention policies

5. **Load Balancing**:
   - Application Load Balancer
   - Health checks via Spring Boot Actuator
   - HTTP endpoint exposure

6. **Container Registry**:
   - Amazon ECR for Docker images
   - Image scanning and lifecycle policies
   - Secure image storage and distribution

## Prerequisites

Before deploying to AWS, ensure you have:

1. **AWS CLI** installed and configured
2. **Terraform** (v1.0.0+) installed
3. **Docker** installed for container builds
4. An **S3 bucket** for Terraform state storage
5. Appropriate **IAM permissions** to create resources

## Deployment Process

### 1. Initial Infrastructure Setup

```bash
# Navigate to the scripts directory
cd scripts

# Create base infrastructure (one-time setup)
./deploy.sh <aws-profile> <aws-region> <environment> <tf-state-bucket>

# Example:
./deploy.sh myprofile us-east-1 dev my-terraform-state-bucket
```

This creates all necessary AWS resources except the application container.

### 2. Building and Pushing Docker Image

```bash
# Build and push the Docker image to ECR
./build-and-push.sh <aws-profile> <aws-region>
```

This script:
- Builds the Docker image locally
- Tags it with the current git commit hash
- Pushes it to the ECR repository

### 3. Deploying the Application

```bash
# Deploy with the newly built image
./deploy.sh <aws-profile> <aws-region> <environment> <tf-state-bucket>
```

When run after a new image is pushed, this updates the ECS service to use the latest image.

### 4. Tearing Down Resources

When you're done with the environment, you can tear it down completely:

```bash
# Remove all AWS resources
./teardown.sh <aws-profile> <aws-region> <environment> <tf-state-bucket>
```

## Environment-Specific Configurations

The deployment supports multiple environments (dev, staging, prod) with different settings:

| Setting | Dev | Staging | Prod |
|---------|-----|---------|------|
| Instance sizes | t3.small | t3.medium | t3.large |
| RDS Multi-AZ | No | Yes | Yes |
| MSK Brokers | 2 | 2 | 3 |
| Auto-scaling | 1-4 tasks | 2-6 tasks | 4-10 tasks |
| Monitoring | Basic | Enhanced | Enhanced + Alarms |

## Customization

### Modifying Infrastructure

To modify infrastructure settings, update the variables in `terraform/variables.tf` or provide environment-specific variables:

```bash
# Create a custom tfvars file
cat > custom.tfvars << EOL
container_cpu = 1024
container_memory = 2048
desired_count = 4
EOL

# Apply with custom variables
terraform apply -var-file="custom.tfvars" -chdir=terraform
```

### Application Configuration

The Spring Boot application uses the `application-aws.yml` profile when deployed to AWS. Environment-specific settings are injected as environment variables:

- Database connection details
- Kafka broker addresses
- AWS region and configuration

## Monitoring and Logs

- **Application Logs**: Available in CloudWatch Logs under `/ecs/product-service-{env}`
- **Kafka Logs**: Available in CloudWatch Logs under `/msk/product-service-{env}-kafka-cluster`
- **Container Insights**: Provides performance metrics for the ECS tasks
- **RDS Metrics**: Database performance monitoring

## Security Considerations

1. **Network Security**:
   - Services run in private subnets
   - Security groups limit access between components
   - VPC endpoints reduce traffic over public internet

2. **Data Security**:
   - RDS encryption at rest
   - Kafka encryption in transit
   - Secrets managed via environment variables

3. **IAM Security**:
   - Minimal permission principles for task roles
   - Separate roles for execution and task functions
   - No hardcoded credentials in code or configuration

## CI/CD Integration

This deployment can be integrated into CI/CD pipelines by calling the scripts from your CI system:

```yaml
deploy_job:
  script:
    - ./scripts/build-and-push.sh $AWS_PROFILE $AWS_REGION
    - ./scripts/deploy.sh $AWS_PROFILE $AWS_REGION $ENVIRONMENT $TF_STATE_BUCKET
```

## Troubleshooting

### Common Issues

1. **ECS Task Failures**:
   - Check task logs in CloudWatch
   - Verify security group allows access to RDS and MSK
   - Ensure task role has proper permissions

2. **Database Connection Issues**:
   - Verify environment variables in task definition
   - Check security group rules allow traffic from ECS security group
   - Test connection with a bastion host

3. **Kafka Connection Issues**:
   - Verify MSK bootstrap servers configuration
   - Ensure proper CIDR range is allowed in security groups
   - Check Kafka authentication settings match application config

## Cost Optimization

This deployment uses several cost-saving measures for non-production environments:

1. Fargate Spot instances option for ECS tasks
2. RDS instances with smaller instance sizes and no Multi-AZ
3. Auto-scaling to reduce resources during off-hours
4. MSK with minimal broker count

For production, resources are appropriately sized for reliability and performance.

## Support

For issues with this deployment:

1. Check CloudWatch Logs for application errors
2. Review ECS service events in the AWS console
3. Verify Terraform state matches actual infrastructure
4. Consult AWS documentation for service-specific troubleshooting
