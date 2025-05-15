#!/bin/bash
# Script to clean up RDS-related resources
# Usage: ./cleanup-rds-resources.sh [AWS_PROFILE] [AWS_REGION]

set -e

# Default values
AWS_PROFILE=${1:-default}
AWS_REGION=${2:-us-east-1}
PREFIX="product-service-dev"

echo "=== Cleaning up RDS resources ==="
echo "AWS Profile: $AWS_PROFILE"
echo "AWS Region: $AWS_REGION"
echo "Resource prefix: $PREFIX"

# Clean up RDS instance first
echo "Checking for RDS instance: ${PREFIX}-db"
if aws rds describe-db-instances --region $AWS_REGION --query "DBInstances[?DBInstanceIdentifier=='${PREFIX}-db']" | grep -q "DBInstanceIdentifier"; then
  echo "Found RDS instance. Deleting..."
  aws rds delete-db-instance \
    --db-instance-identifier ${PREFIX}-db \
    --skip-final-snapshot \
    --region $AWS_REGION
  
  echo "Waiting for RDS instance to be deleted (this may take several minutes)..."
  aws rds wait db-instance-deleted --db-instance-identifier ${PREFIX}-db --region $AWS_REGION
  echo "RDS instance deleted."
else
  echo "No RDS instance found. Skipping."
fi

# Clean up DB parameter group
echo "Checking for DB parameter group: ${PREFIX}-db-param-group"
if aws rds describe-db-parameter-groups --region $AWS_REGION --query "DBParameterGroups[?DBParameterGroupName=='${PREFIX}-db-param-group']" | grep -q "DBParameterGroupName"; then
  echo "Found DB parameter group. Deleting..."
  aws rds delete-db-parameter-group \
    --db-parameter-group-name ${PREFIX}-db-param-group \
    --region $AWS_REGION
  echo "DB parameter group deleted."
else
  echo "No DB parameter group found. Skipping."
fi

# Clean up DB subnet group
echo "Checking for DB subnet group: ${PREFIX}-db-subnet-group"
if aws rds describe-db-subnet-groups --region $AWS_REGION --query "DBSubnetGroups[?DBSubnetGroupName=='${PREFIX}-db-subnet-group']" | grep -q "DBSubnetGroupName"; then
  echo "Found DB subnet group. Deleting..."
  aws rds delete-db-subnet-group \
    --db-subnet-group-name ${PREFIX}-db-subnet-group \
    --region $AWS_REGION
  echo "DB subnet group deleted."
else
  echo "No DB subnet group found. Skipping."
fi

echo "=== RDS resource cleanup complete ==="
echo "You can now run the deploy-rds.sh script."
