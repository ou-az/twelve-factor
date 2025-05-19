#!/usr/bin/env pwsh
# Healthcare SOA AWS Deployment Script
# This script automates the deployment of the healthcare SOA project to AWS
# using a fully containerized approach with ECS

# Stop on any errors
$ErrorActionPreference = "Stop"

# Parameters
param(
    [Parameter(Mandatory=$false)]
    [string]$Environment = "dev",
    
    [Parameter(Mandatory=$false)]
    [string]$Region = "us-east-1",
    
    [Parameter(Mandatory=$false)]
    [switch]$BuildOnly,
    
    [Parameter(Mandatory=$false)]
    [switch]$DeployOnly,
    
    [Parameter(Mandatory=$false)]
    [switch]$Destroy
)

# Configuration
$PROJECT_ROOT = "<PROJECT-DIR>\twelve-factor\healthcare-soa"
$TERRAFORM_DIR = "$PROJECT_ROOT\terraform\fully-containerized"

# Function to check prerequisites
function Check-Prerequisites {
    Write-Host "Checking prerequisites..." -ForegroundColor Cyan
    
    # Check for AWS CLI
    try {
        $awsVersion = aws --version
        Write-Host "AWS CLI is installed: $awsVersion" -ForegroundColor Green
    } catch {
        Write-Host "AWS CLI is not installed or not in PATH. Please install it first." -ForegroundColor Red
        exit 1
    }
    
    # Check for Docker
    try {
        $dockerVersion = docker --version
        Write-Host "Docker is installed: $dockerVersion" -ForegroundColor Green
    } catch {
        Write-Host "Docker is not installed or not in PATH. Please install it first." -ForegroundColor Red
        exit 1
    }
    
    # Check for Terraform
    try {
        $terraformVersion = terraform --version
        Write-Host "Terraform is installed: $terraformVersion" -ForegroundColor Green
    } catch {
        Write-Host "Terraform is not installed or not in PATH. Please install it first." -ForegroundColor Red
        exit 1
    }
    
    # Check AWS credentials
    try {
        $awsIdentity = aws sts get-caller-identity
        Write-Host "AWS credentials are valid." -ForegroundColor Green
    } catch {
        Write-Host "AWS credentials are not configured or invalid. Please run 'aws configure'." -ForegroundColor Red
        exit 1
    }
}

# Function to build Docker images
function Build-DockerImages {
    Write-Host "Building Docker images..." -ForegroundColor Cyan
    
    # Build images using docker-compose
    Set-Location $PROJECT_ROOT
    
    # Build the application services
    docker-compose build
    
    # Return to the script directory
    Set-Location $PSScriptRoot
}

# Function to deploy Terraform infrastructure
function Deploy-Infrastructure {
    Write-Host "Deploying Terraform infrastructure..." -ForegroundColor Cyan
    
    # Initialize Terraform
    Set-Location $TERRAFORM_DIR
    terraform init
    
    # Plan Terraform changes
    terraform plan -out=tfplan
    
    # Apply Terraform changes
    terraform apply tfplan
    
    # Return to the script directory
    Set-Location $PSScriptRoot
}

# Function to destroy Terraform infrastructure
function Destroy-Infrastructure {
    Write-Host "WARNING: This will destroy all infrastructure in $Environment environment!" -ForegroundColor Red
    $confirmation = Read-Host "Are you sure you want to proceed? (y/n)"
    
    if ($confirmation -eq 'y') {
        Write-Host "Destroying Terraform infrastructure..." -ForegroundColor Cyan
        
        Set-Location $TERRAFORM_DIR
        terraform destroy -auto-approve
        
        Write-Host "Infrastructure destroyed successfully." -ForegroundColor Green
        
        # Return to the script directory
        Set-Location $PSScriptRoot
    } else {
        Write-Host "Destruction cancelled." -ForegroundColor Yellow
    }
}

# Function to push Docker images to ECR
function Push-Images-To-ECR {
    Write-Host "Pushing Docker images to ECR..." -ForegroundColor Cyan
    
    # Get ECR repository info from Terraform output
    Set-Location $TERRAFORM_DIR
    $repoUrls = terraform output -json ecr_repository_urls | ConvertFrom-Json
    
    # Get AWS account ID
    $AWS_ACCOUNT_ID = aws sts get-caller-identity --query Account --output text
    
    # Log in to ECR
    aws ecr get-login-password --region $Region | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$Region.amazonaws.com"
    
    # Push all service images
    foreach ($service in @("patient-service", "appointment-service")) {
        $localImageName = "healthcare-soa-$service"
        $ecrUri = $repoUrls.$service
        
        Write-Host "Tagging and pushing $service..." -ForegroundColor Cyan
        
        # Tag the image
        docker tag "$localImageName`:latest" "$ecrUri`:latest"
        
        # Push the image
        docker push "$ecrUri`:latest"
    }
    
    # Database images
    foreach ($dbService in @("postgres", "mongodb", "redis")) {
        $baseImageName = $dbService
        $ecrUri = $repoUrls.$dbService
        
        if ($dbService -eq "postgres") {
            $baseImageName = "postgres:13"
        } elseif ($dbService -eq "mongodb") {
            $baseImageName = "mongo:5.0"
        } elseif ($dbService -eq "redis") {
            $baseImageName = "redis:6.2"
        }
        
        Write-Host "Pulling, tagging and pushing $dbService..." -ForegroundColor Cyan
        
        # Pull the base image if needed
        docker pull $baseImageName
        
        # Tag the image
        docker tag "$baseImageName" "$ecrUri`:latest"
        
        # Push the image
        docker push "$ecrUri`:latest"
    }
    
    # ESB (Mule) image
    $esbImage = "vromero/mule:3.8.0"
    $esbUri = $repoUrls.esb
    
    Write-Host "Pulling, tagging and pushing ESB image..." -ForegroundColor Cyan
    
    # Pull the Mule ESB image
    docker pull $esbImage
    
    # Tag the image
    docker tag $esbImage "$esbUri`:latest"
    
    # Push the image
    docker push "$esbUri`:latest"
    
    Write-Host "All images have been pushed to ECR successfully!" -ForegroundColor Green
    
    # Return to the script directory
    Set-Location $PSScriptRoot
}

# Function to test deployed services
function Test-Deployment {
    Write-Host "Testing deployment..." -ForegroundColor Cyan
    
    # Get the ALB DNS name from Terraform output
    Set-Location $TERRAFORM_DIR
    $albDns = terraform output -raw module.ecs.alb_dns_name
    
    if ([string]::IsNullOrEmpty($albDns)) {
        Write-Host "ALB DNS name is empty or not available. Deployment may not be complete." -ForegroundColor Red
        return
    }
    
    # Test health endpoints of each service
    foreach ($service in @("patient-service", "appointment-service")) {
        $url = "http://$albDns/$service/actuator/health"
        Write-Host "Testing $service health endpoint: $url" -ForegroundColor Cyan
        
        try {
            $response = Invoke-WebRequest -Uri $url
            if ($response.StatusCode -eq 200) {
                Write-Host "$service is healthy: $($response.Content)" -ForegroundColor Green
            } else {
                Write-Host "$service returned status code $($response.StatusCode)" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "$service health check failed: $_" -ForegroundColor Red
        }
    }
    
    # Return to the script directory
    Set-Location $PSScriptRoot
}

# Main execution

# Display banner
Write-Host "===============================================" -ForegroundColor Magenta
Write-Host "Healthcare SOA - AWS Deployment Script" -ForegroundColor Magenta
Write-Host "Environment: $Environment" -ForegroundColor Magenta
Write-Host "Region: $Region" -ForegroundColor Magenta
Write-Host "===============================================" -ForegroundColor Magenta

# Check prerequisites
Check-Prerequisites

# Handle script execution based on parameters
if ($Destroy) {
    Destroy-Infrastructure
    exit 0
}

if (!$DeployOnly) {
    Build-DockerImages
}

if (!$BuildOnly) {
    Deploy-Infrastructure
    Push-Images-To-ECR
    Test-Deployment
}

# Final message
Write-Host "===============================================" -ForegroundColor Green
Write-Host "Deployment completed successfully!" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green
