#!/bin/bash
# Script to list available PostgreSQL versions in your AWS region
# Usage: ./check-postgres-versions.sh [AWS_PROFILE] [AWS_REGION]

set -e

# Default values
AWS_PROFILE=${1:-default}
AWS_REGION=${2:-us-east-1}

echo "=== Checking available PostgreSQL versions in $AWS_REGION ==="
echo "AWS Profile: $AWS_PROFILE"
echo "AWS Region: $AWS_REGION"

# Export AWS credentials
export AWS_PROFILE=$AWS_PROFILE
export AWS_REGION=$AWS_REGION

# List all PostgreSQL engine versions
echo "Fetching available PostgreSQL versions..."
aws rds describe-db-engine-versions \
  --engine postgres \
  --region $AWS_REGION \
  --query "DBEngineVersions[].{Engine:Engine,EngineVersion:EngineVersion,ParameterGroupFamily:DBParameterGroupFamily}" \
  --output table

echo ""
echo "=== How to use this information ==="
echo "1. Pick a version from the list above"
echo "2. Update main.tf with the exact version and matching parameter group family"
echo "3. Example:"
echo "   engine_version = \"11.19\""  # Use a version from above
echo "   family = \"postgres11\""  # Match the parameter group family
