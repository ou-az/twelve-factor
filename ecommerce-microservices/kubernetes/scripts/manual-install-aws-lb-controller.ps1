# PowerShell script to install AWS Load Balancer Controller using YAML directly (no Helm required)

# Get cluster name from Terraform output
Set-Location <SOURCE_DIR>\twelve-factor\ecommerce-microservices\terraform\environments\prod
$CLUSTER_NAME = terraform output -raw eks_cluster_name
$AWS_REGION = terraform output -raw aws_region
$VPC_ID = terraform output -raw vpc_id

Write-Host "Installing AWS Load Balancer Controller for cluster: $CLUSTER_NAME in region: $AWS_REGION" -ForegroundColor Cyan

# First apply the CRDs
Write-Host "Downloading and applying AWS Load Balancer Controller CRDs..." -ForegroundColor Cyan
Invoke-WebRequest -Uri "https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/v2.5.4/v2_5_4_full.yaml" -OutFile "aws-lb-controller.yaml"

# Modify the cluster name in the YAML file
(Get-Content -Path "aws-lb-controller.yaml") -replace "your-cluster-name", $CLUSTER_NAME | Set-Content -Path "aws-lb-controller.yaml"

# Apply the modified YAML file
kubectl apply -f aws-lb-controller.yaml

Write-Host "AWS Load Balancer Controller installation complete!" -ForegroundColor Green
Write-Host "This enhances your EKS cluster with AWS-native load balancing capabilities necessary for exposing services." -ForegroundColor Green
