#!/bin/bash
# Script to tear down AWS resources deployed by Terraform
# Usage: ./teardown.sh [AWS_PROFILE] [AWS_REGION] [ENVIRONMENT] [TF_STATE_BUCKET]

set -e

# Default values
AWS_PROFILE=${1:-default}
AWS_REGION=${2:-us-east-1}
ENVIRONMENT=${3:-dev}
TF_STATE_BUCKET=${4:-your-terraform-state-bucket}

echo "=== Tearing down AWS resources ==="
echo "AWS Profile: $AWS_PROFILE"
echo "AWS Region: $AWS_REGION"
echo "Environment: $ENVIRONMENT"
echo "Terraform State Bucket: $TF_STATE_BUCKET"

# Export AWS credentials for Terraform
export AWS_PROFILE=$AWS_PROFILE
export AWS_REGION=$AWS_REGION

# Initialize Terraform with S3 backend
echo "=== Initializing Terraform ==="
(cd ../terraform && \
 terraform init \
  -backend-config="bucket=$TF_STATE_BUCKET" \
  -backend-config="key=product-service/$ENVIRONMENT/terraform.tfstate" \
  -backend-config="region=$AWS_REGION")

# Run Terraform destroy
echo "=== Destroying infrastructure ==="
echo "WARNING: This will delete all resources created by Terraform!"
echo "You have 10 seconds to cancel (Ctrl+C)..."
sleep 10

(cd ../terraform && \
 terraform destroy -auto-approve)

echo "=== Teardown completed successfully ==="
echo "All AWS resources have been destroyed."
