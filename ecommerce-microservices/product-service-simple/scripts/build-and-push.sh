#!/bin/bash
# Script to build and push Docker image to ECR
# Usage: ./build-and-push.sh [AWS_PROFILE] [AWS_REGION]

set -e

# Default values
AWS_PROFILE=${1:-default}
AWS_REGION=${2:-us-east-1}
ECR_REPO_NAME=$(terraform -chdir=../terraform output -raw ecr_repository_name)
ECR_REPO_URL=$(terraform -chdir=../terraform output -raw ecr_repository_url)
IMAGE_TAG=$(git rev-parse --short HEAD 2>/dev/null || echo "latest")

echo "=== Building and pushing Docker image ==="
echo "AWS Profile: $AWS_PROFILE"
echo "AWS Region: $AWS_REGION"
echo "ECR Repository: $ECR_REPO_NAME"
echo "Image tag: $IMAGE_TAG"

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --profile $AWS_PROFILE --query "Account" --output text)

# Authenticate Docker to ECR
echo "=== Authenticating Docker to ECR ==="
aws ecr get-login-password --region $AWS_REGION --profile $AWS_PROFILE | \
  docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Build Docker image
echo "=== Building Docker image ==="
docker build -t $ECR_REPO_NAME:$IMAGE_TAG ..

# Tag Docker image for ECR
echo "=== Tagging Docker image ==="
docker tag $ECR_REPO_NAME:$IMAGE_TAG $ECR_REPO_URL:$IMAGE_TAG

# Push to ECR
echo "=== Pushing Docker image to ECR ==="
docker push $ECR_REPO_URL:$IMAGE_TAG

echo "=== Image successfully built and pushed ==="
echo "Image: $ECR_REPO_URL:$IMAGE_TAG"
echo ""
echo "To use this image, run:"
echo "terraform apply -var='image_tag=$IMAGE_TAG' -chdir=../terraform"
