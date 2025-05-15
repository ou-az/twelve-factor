#!/bin/bash
# Script to deploy the application to AWS ECS using Terraform
# Usage: ./deploy.sh [AWS_PROFILE] [AWS_REGION] [ENVIRONMENT] [TF_STATE_BUCKET]

set -e

# Default values
AWS_PROFILE=${1:-default}
AWS_REGION=${2:-us-east-1}
ENVIRONMENT=${3:-dev}
TF_STATE_BUCKET=${4:-your-terraform-state-bucket}
IMAGE_TAG=$(git rev-parse --short HEAD 2>/dev/null || echo "latest")

# Random string to avoid naming conflicts
RANDOM_SUFFIX=$(date +%s | shasum | base64 | head -c 8)

echo "=== Deploying application to AWS ECS ==="
echo "AWS Profile: $AWS_PROFILE"
echo "AWS Region: $AWS_REGION"
echo "Environment: $ENVIRONMENT"
echo "Terraform State Bucket: $TF_STATE_BUCKET"
echo "Image tag: $IMAGE_TAG"

# Export AWS credentials for Terraform
export AWS_PROFILE=$AWS_PROFILE
export AWS_REGION=$AWS_REGION

# Create database password if not provided
DB_PASSWORD=${DB_PASSWORD:-$(openssl rand -base64 16)}

# Initialize Terraform with S3 backend
echo "=== Initializing Terraform ==="
(cd ../terraform && \
 terraform init \
  -backend-config="bucket=$TF_STATE_BUCKET" \
  -backend-config="key=product-service/$ENVIRONMENT/terraform.tfstate" \
  -backend-config="region=$AWS_REGION")

# Create a temporary tfvars file with secrets
TFVARS_FILE="../terraform/terraform.tfvars"
cat > $TFVARS_FILE << EOL
aws_region           = "$AWS_REGION"
environment          = "$ENVIRONMENT"
image_tag            = "$IMAGE_TAG"
postgres_password    = "$DB_PASSWORD"
EOL

# Run Terraform apply
echo "=== Applying Terraform configuration ==="
(cd ../terraform && \
 terraform apply -auto-approve \
  -var-file="terraform.tfvars")

# Get outputs
echo "=== Deployment completed successfully ==="
echo "ALB DNS Name: $(terraform -chdir=../terraform output -raw alb_dns_name)"
echo "ECR Repository URL: $(terraform -chdir=../terraform output -raw ecr_repository_url)"

# Clean up the tfvars file
rm $TFVARS_FILE

echo "=== Deployment information ==="
echo "To tear down this deployment, run: ./teardown.sh $AWS_PROFILE $AWS_REGION $ENVIRONMENT $TF_STATE_BUCKET"
