# Spring Boot Microservice with Kafka Deployment Guide for AWS

This guide provides step-by-step instructions for deploying a Spring Boot microservice with Kafka integration to AWS using Terraform. This implementation showcases production-grade cloud infrastructure deployment skills for DevOps and architectural positions.

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform installed
- Docker installed
- Java 17+ and Maven installed
- Git to clone the repository

## Step 1: Deploy PostgreSQL 17.5 Database to AWS RDS

First, we'll set up a PostgreSQL 17.5 database in AWS RDS, which will serve as the persistent data store for our microservice.

```bash
# Navigate to the RDS Terraform directory
cd terraform-rds

# Initialize Terraform
terraform init

# Deploy the RDS PostgreSQL 17.5 database
terraform apply -var="postgres_password=YourSecurePassword123" -auto-approve

# Save the database endpoint for later use
RDS_ENDPOINT=$(terraform output -raw rds_address)
echo "RDS Endpoint: $RDS_ENDPOINT"
```

The RDS deployment creates:
- A PostgreSQL 17.5 database instance
- Appropriate subnet groups and parameter groups
- Security groups with proper inbound/outbound rules

## Step 2: Build and Package the Spring Boot Application

Next, build the Spring Boot application and prepare it for containerization.

```bash
# Navigate to the application root directory
cd ..

# Build the application with Maven
mvn clean package -DskipTests

# Verify the JAR file was created
ls -la target/*.jar
```

## Step 3: Build and Push Docker Image to ECR

Now, build a Docker image for the Spring Boot application and push it to Amazon ECR.

```bash
# Log in to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com

# Build the Docker image
docker build -t product-service-dev .

# Tag the image for ECR
docker tag product-service-dev:latest $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com/product-service-dev:latest

# Push the image to ECR
docker push $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com/product-service-dev:latest
```

This creates a multi-stage Docker build that:
1. Uses Maven to compile and package the application
2. Creates a minimal JRE-based runtime image
3. Configures proper security practices (non-root user)
4. Sets up health checks and port exposures

## Step 4: Deploy the Complete Infrastructure with Terraform

With the database running and Docker image pushed to ECR, deploy the full infrastructure including VPC, ECS, and MSK (Kafka).

```bash
# Navigate to the main Terraform directory
cd terraform

# Initialize Terraform with S3 backend
terraform init -backend-config="bucket=ussp-terraform-state" -backend-config="key=product-service/terraform.tfstate" -backend-config="region=us-east-1" -backend-config="encrypt=true"

# Deploy the infrastructure
terraform apply -var="postgres_password=YourSecurePassword123" -auto-approve
```

This deployment creates:
- VPC with public and private subnets across multiple AZs
- Security groups for network segmentation
- Amazon MSK (Managed Streaming for Kafka)
- ECS Fargate for containerized application deployment
- Application Load Balancer for request distribution

## Step 5: Deploy Kafka-UI Monitoring Tool

To monitor the Kafka streaming platform, deploy the Kafka-UI tool.

```bash
# Deploy Kafka-UI with Terraform
terraform apply -var="postgres_password=YourSecurePassword123" -target="module.kafka_ui" -auto-approve

# Get the Kafka-UI URL
KAFKA_UI_URL=$(terraform output -raw kafka_ui_url)
echo "Kafka UI available at: $KAFKA_UI_URL"
```

This deploys a containerized Kafka-UI monitoring interface that:
- Connects to your MSK cluster
- Provides topic management and browsing
- Shows consumer group lag metrics
- Allows message inspection and broker monitoring

## Step 6: Test the Deployed Application

Verify your deployment by testing the application endpoints.

```bash
# Get the application endpoint
APP_URL=$(terraform output -raw alb_dns_name)

# Check application health
curl http://$APP_URL/actuator/health

# Create a test product (this will also produce a Kafka event)
curl -X POST http://$APP_URL/api/products \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Cloud Deployment Test Product",
    "price": 199.99,
    "description": "Product created during AWS deployment",
    "stockQuantity": 100,
    "categoryId": 1
  }'

# List all products
curl http://$APP_URL/api/products
```

## Step 7: Clean Up Resources When Done

To avoid unnecessary AWS charges, clean up all resources when finished.

```bash
# Delete the main infrastructure
cd terraform
terraform destroy -var="postgres_password=YourSecurePassword123" -auto-approve

# Delete the RDS database
cd ../terraform-rds
terraform destroy -auto-approve
```

## Architecture Overview

This deployment implements:

- **Event-Driven Architecture**: Using Kafka for real-time message streaming
- **Containerized Microservices**: Spring Boot in Docker containers on ECS Fargate
- **Database Persistence**: PostgreSQL 17.5 on RDS
- **Infrastructure as Code**: Complete AWS deployment with Terraform
- **Monitoring and Observability**: Kafka-UI for stream monitoring
- **Security Best Practices**: Proper network segmentation and least privilege

## Deployment Diagram

```
                                  ┌───────────────┐
                                  │   Internet    │
                                  └───────┬───────┘
                                          │
                                          ▼
┌───────────────────────────────────────────────────────────────┐
│                      AWS Cloud (us-east-1)                    │
│                                                               │
│   ┌─────────────┐          ┌─────────────┐                    │
│   │  Application │         │   Kafka-UI   │                   │
│   │ Load Balancer│◄────────┤Load Balancer │                   │
│   └──────┬──────┘          └──────┬──────┘                    │
│          │                         │                          │
│          ▼                         ▼                          │
│   ┌─────────────┐          ┌─────────────┐                    │
│   │  ECS Fargate │         │  ECS Fargate │                   │
│   │  Service    │         │  Kafka-UI   │                   │
│   └──────┬──────┘          └──────┬──────┘                    │
│          │                         │                          │
│          │                         │                          │
│   ┌──────▼──────┐          ┌──────▼──────┐    ┌────────────┐ │
│   │     MSK     │◄─────────┤    RDS      │    │    ECR      │ │
│   │   (Kafka)   │          │ PostgreSQL  │    │ Repository  │ │
│   └─────────────┘          └─────────────┘    └────────────┘ │
│                                                               │
└───────────────────────────────────────────────────────────────┘
```

## Security Considerations

- All components run within a private VPC subnet
- Public access limited to load balancers only
- Proper security group rules for service-to-service communication
- TLS for Kafka connections (enabled by default in MSK)
- Database credentials passed securely via environment variables

## Additional Considerations for Production

For a production deployment, consider:

1. Setting up CI/CD pipelines for automated deployments
2. Implementing proper database backup strategies
3. Configuring CloudWatch alarms for monitoring
4. Enabling enhanced metrics and logging
5. Implementing auto-scaling policies for the ECS service

This deployment showcases advanced cloud engineering skills including container orchestration, message streaming architecture, and infrastructure as code - all valuable for DevOps and Senior Engineering positions.
