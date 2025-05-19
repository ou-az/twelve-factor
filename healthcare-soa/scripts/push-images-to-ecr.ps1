# Script to push Healthcare SOA Docker images to ECR
# Author: Your Name
# Date: 2025-05-18

# Check if the Terraform output file exists
$outputFile = ".\terraform\ecr-outputs.json"
if (-not (Test-Path $outputFile)) {
    Write-Host "ECR output file not found. Running terraform output command..." -ForegroundColor Yellow
    
    # Change to terraform directory
    Set-Location -Path .\terraform
    
    # Export the ECR repository URLs to a JSON file
    terraform output -json module.ecr.repository_urls > ecr-outputs.json
    
    # Go back to the main directory
    Set-Location -Path ..
    
    if (-not (Test-Path $outputFile)) {
        Write-Host "Failed to generate ECR repository URLs. Make sure Terraform has been applied successfully." -ForegroundColor Red
        exit 1
    }
}

# Read the ECR repository URLs from the output file
$ecrRepos = Get-Content -Path $outputFile | ConvertFrom-Json

# Get the AWS region
$AWS_REGION = "us-east-1"

# Get AWS account ID
Write-Host "Getting AWS account ID..." -ForegroundColor Cyan
$AWS_ACCOUNT_ID = aws sts get-caller-identity --query Account --output text

Write-Host "Logging in to ECR in region $AWS_REGION..." -ForegroundColor Cyan
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

# Define service names
$SERVICES = @("patient-service", "appointment-service", "esb")

foreach ($SERVICE in $SERVICES) {
    if ($null -ne $ecrRepos.$SERVICE) {
        $ECR_REPO_URL = $ecrRepos.$SERVICE
        
        Write-Host "Processing $SERVICE..." -ForegroundColor Cyan
        Write-Host "ECR Repository URL: $ECR_REPO_URL" -ForegroundColor Cyan
        
        # Tag the image
        Write-Host "Tagging $SERVICE image..." -ForegroundColor Cyan
        docker tag "healthcare-$SERVICE" "$ECR_REPO_URL`:latest"
        
        # Push the image
        Write-Host "Pushing $SERVICE image to ECR..." -ForegroundColor Cyan
        docker push "$ECR_REPO_URL`:latest"
        
        Write-Host "Successfully pushed $SERVICE image to ECR!" -ForegroundColor Green
    } else {
        Write-Host "ECR repository URL not found for $SERVICE" -ForegroundColor Yellow
    }
}

Write-Host "All images have been pushed to ECR successfully!" -ForegroundColor Green
