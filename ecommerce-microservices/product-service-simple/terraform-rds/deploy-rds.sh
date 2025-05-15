#!/bin/bash
# Script to deploy just the RDS database
# Usage: ./deploy-rds.sh [AWS_PROFILE] [AWS_REGION] [DB_PASSWORD]

set -e

# Default values
AWS_PROFILE=${1:-default}
AWS_REGION=${2:-us-east-1}
DB_PASSWORD=${3:-postgres123}

echo "=== Deploying standalone RDS PostgreSQL instance ==="
echo "AWS Profile: $AWS_PROFILE"
echo "AWS Region: $AWS_REGION"

# Export AWS credentials for Terraform
export AWS_PROFILE=$AWS_PROFILE
export AWS_REGION=$AWS_REGION

# Create a temporary tfvars file with the password
TFVARS_FILE="terraform.tfvars"
cat > $TFVARS_FILE << EOL
aws_region        = "$AWS_REGION"
database_password = "$DB_PASSWORD"
EOL

# Initialize Terraform
echo "=== Initializing Terraform ==="
terraform init

# Apply the configuration
echo "=== Applying Terraform configuration ==="
terraform apply -auto-approve -var-file="$TFVARS_FILE"

# Get the RDS endpoint
RDS_ENDPOINT=$(terraform output -raw rds_endpoint)
DATABASE_NAME=$(terraform output -raw database_name)

echo "=== RDS PostgreSQL database successfully deployed ==="
echo "Endpoint: $RDS_ENDPOINT"
echo "Database: $DATABASE_NAME"
echo "Username: postgres"
echo "Password: $DB_PASSWORD"
echo ""
echo "Connection string: jdbc:postgresql://$RDS_ENDPOINT/$DATABASE_NAME"
echo ""
echo "To connect to the database:"
echo "psql -h ${RDS_ENDPOINT%:*} -p ${RDS_ENDPOINT#*:} -d $DATABASE_NAME -U postgres"

# Clean up the tfvars file
rm $TFVARS_FILE

echo ""
echo "To destroy this database when done:"
echo "./destroy-rds.sh $AWS_PROFILE $AWS_REGION"
