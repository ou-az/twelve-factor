#!/bin/bash
# Script to wait for MSK cluster deletion to complete
# Usage: ./wait-for-msk-deletion.sh [AWS_PROFILE] [AWS_REGION] [ENVIRONMENT]

AWS_PROFILE=${1:-default}
AWS_REGION=${2:-us-east-1}
ENVIRONMENT=${3:-dev}

MSK_CLUSTER_NAME="product-service-${ENVIRONMENT}-kafka-cluster"

echo "Checking for MSK cluster: $MSK_CLUSTER_NAME"
echo "This may take several minutes. MSK cluster deletion typically takes 10-15 minutes."

while true; do
  # Check if the cluster exists
  CLUSTERS=$(aws kafka list-clusters --region $AWS_REGION --profile $AWS_PROFILE)
  FOUND=$(echo $CLUSTERS | grep -c "$MSK_CLUSTER_NAME" || true)
  
  if [ $FOUND -eq 0 ]; then
    echo "MSK cluster $MSK_CLUSTER_NAME has been successfully deleted."
    break
  else
    echo "MSK cluster $MSK_CLUSTER_NAME is still being deleted. Waiting 60 seconds..."
    sleep 60
  fi
done

echo "You can now proceed with deployment."
