#!/bin/bash
# Script to clean up partially deployed resources
# Usage: ./cleanup-partial-deployment.sh [AWS_PROFILE] [AWS_REGION] [ENVIRONMENT]

set -e

# Default values
AWS_PROFILE=${1:-default}
AWS_REGION=${2:-us-east-1}
ENVIRONMENT=${3:-dev}

echo "=== Cleaning up partially deployed resources ==="
echo "AWS Profile: $AWS_PROFILE"
echo "AWS Region: $AWS_REGION"
echo "Environment: $ENVIRONMENT"

# Export AWS credentials
export AWS_PROFILE=$AWS_PROFILE
export AWS_REGION=$AWS_REGION

# Define resource names based on environment
MSK_CLUSTER_NAME="product-service-${ENVIRONMENT}-kafka-cluster"
RDS_INSTANCE_ID="product-service-${ENVIRONMENT}-db"

# Check and delete MSK cluster if exists
echo "Checking for MSK cluster: $MSK_CLUSTER_NAME"
if aws kafka list-clusters --region $AWS_REGION | grep -q "$MSK_CLUSTER_NAME"; then
  echo "Found MSK cluster $MSK_CLUSTER_NAME. Deleting..."
  CLUSTER_ARN=$(aws kafka list-clusters --region $AWS_REGION --query "ClusterInfoList[?ClusterName=='$MSK_CLUSTER_NAME'].ClusterArn" --output text)
  aws kafka delete-cluster --cluster-arn $CLUSTER_ARN --region $AWS_REGION
  echo "Waiting for MSK cluster deletion to complete..."
  aws kafka wait cluster-deleted --cluster-arn $CLUSTER_ARN --region $AWS_REGION || echo "Wait command failed, but deletion may still be in progress."
  echo "MSK cluster deletion initiated."
else
  echo "MSK cluster not found. Skipping."
fi

# Check and delete RDS instance if exists
echo "Checking for RDS instance: $RDS_INSTANCE_ID"
if aws rds describe-db-instances --region $AWS_REGION | grep -q "$RDS_INSTANCE_ID"; then
  echo "Found RDS instance $RDS_INSTANCE_ID. Deleting..."
  aws rds delete-db-instance \
    --db-instance-identifier $RDS_INSTANCE_ID \
    --skip-final-snapshot \
    --region $AWS_REGION
  echo "RDS instance deletion initiated. This may take several minutes."
else
  echo "RDS instance not found. Skipping."
fi

echo "=== Cleanup initiated ==="
echo "Some resources may still be in the process of being deleted."
echo "You can check their status in the AWS Console."
echo "Wait for deletion to complete before redeploying."
