#!/bin/bash
# Script to tear down the RDS database
# Usage: ./destroy-rds.sh [AWS_PROFILE] [AWS_REGION]

set -e

# Default values
AWS_PROFILE=${1:-default}
AWS_REGION=${2:-us-east-1}

echo "=== Destroying RDS PostgreSQL instance ==="
echo "AWS Profile: $AWS_PROFILE"
echo "AWS Region: $AWS_REGION"

# Export AWS credentials for Terraform
export AWS_PROFILE=$AWS_PROFILE
export AWS_REGION=$AWS_REGION

# Destroy the resources
echo "=== Destroying Terraform resources ==="
echo "WARNING: This will delete the database and all its data!"
echo "You have 10 seconds to cancel (Ctrl+C)..."
sleep 10

terraform destroy -auto-approve

echo "=== RDS PostgreSQL database successfully destroyed ==="
