#!/bin/bash
# Script to set up S3 bucket for Terraform state
# Usage: ./setup-terraform-backend.sh [AWS_PROFILE] [AWS_REGION] [BUCKET_NAME]

set -e

# Default values
AWS_PROFILE=${1:-default}
AWS_REGION=${2:-us-east-1}
BUCKET_NAME=${3:-your-terraform-state-bucket}

echo "=== Creating S3 bucket for Terraform state ==="
echo "AWS Profile: $AWS_PROFILE"
echo "AWS Region: $AWS_REGION" 
echo "Bucket Name: $BUCKET_NAME"

# Export AWS credentials
export AWS_PROFILE=$AWS_PROFILE
export AWS_REGION=$AWS_REGION

# Check if bucket exists
echo "Checking if bucket already exists..."
if aws s3api head-bucket --bucket $BUCKET_NAME 2>/dev/null; then
  echo "Bucket $BUCKET_NAME already exists."
else
  # Create S3 bucket
  echo "Creating S3 bucket..."
  # Special handling for us-east-1 which doesn't use LocationConstraint
  if [ "$AWS_REGION" = "us-east-1" ]; then
    aws s3api create-bucket \
      --bucket $BUCKET_NAME \
      --region $AWS_REGION
  else
    aws s3api create-bucket \
      --bucket $BUCKET_NAME \
      --region $AWS_REGION \
      --create-bucket-configuration LocationConstraint=$AWS_REGION
  fi

  # Enable versioning
  echo "Enabling bucket versioning..."
  aws s3api put-bucket-versioning \
    --bucket $BUCKET_NAME \
    --versioning-configuration Status=Enabled

  # Enable encryption
  echo "Enabling default encryption..."
  aws s3api put-bucket-encryption \
    --bucket $BUCKET_NAME \
    --server-side-encryption-configuration '{
      "Rules": [
        {
          "ApplyServerSideEncryptionByDefault": {
            "SSEAlgorithm": "AES256"
          }
        }
      ]
    }'

  # Block public access
  echo "Blocking public access..."
  aws s3api put-public-access-block \
    --bucket $BUCKET_NAME \
    --public-access-block-configuration '{
      "BlockPublicAcls": true,
      "IgnorePublicAcls": true,
      "BlockPublicPolicy": true,
      "RestrictPublicBuckets": true
    }'
    
  echo "S3 bucket created successfully!"
fi

echo "=== Terraform backend setup complete ==="
echo "You can now use the following commands for deployment:"
echo "./deploy.sh $AWS_PROFILE $AWS_REGION <environment> $BUCKET_NAME"
