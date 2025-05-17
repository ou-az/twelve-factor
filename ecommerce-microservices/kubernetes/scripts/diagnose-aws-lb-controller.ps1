# PowerShell script to diagnose and fix AWS Load Balancer Controller issues

Write-Host "Diagnosing AWS Load Balancer Controller issues..." -ForegroundColor Cyan

# Check the pod in detail
Write-Host "Checking controller pod details..." -ForegroundColor Yellow
kubectl describe pod -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

# Check if the IAM service account is properly created
Write-Host "`nChecking service account..." -ForegroundColor Yellow
kubectl get serviceaccount -n kube-system aws-load-balancer-controller -o yaml

# Set up IAM permissions using eksctl for the AWS Load Balancer Controller
Write-Host "`nLet's create the proper IAM roles for the controller..." -ForegroundColor Cyan

# First, get the cluster name
Set-Location C:\workspaces\interview\twelve-factor\ecommerce-microservices\terraform\environments\prod
$CLUSTER_NAME = terraform output -raw eks_cluster_name
$AWS_REGION = terraform output -raw aws_region

Write-Host "Creating IAM policy for AWS Load Balancer Controller..." -ForegroundColor Yellow
# Download the IAM policy document
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json" -OutFile "iam-policy.json"

# Create the IAM policy
Write-Host "Creating IAM policy AWSLoadBalancerControllerIAMPolicy..." -ForegroundColor Yellow
aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam-policy.json

Write-Host "Creating IAM service account for the controller..." -ForegroundColor Yellow
# Create IAM role and service account
eksctl create iamserviceaccount `
  --cluster=$CLUSTER_NAME `
  --namespace=kube-system `
  --name=aws-load-balancer-controller `
  --attach-policy-arn=arn:aws:iam::$(aws sts get-caller-identity --query "Account" --output text):policy/AWSLoadBalancerControllerIAMPolicy `
  --override-existing-serviceaccounts `
  --region $AWS_REGION `
  --approve

Write-Host "`nRestarting the AWS Load Balancer Controller..." -ForegroundColor Yellow
kubectl delete pod -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

Write-Host "`nWaiting for the controller to restart..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

Write-Host "`nChecking controller status again..." -ForegroundColor Yellow
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

Write-Host "`nDiagnostics complete!" -ForegroundColor Green
Write-Host "If the controller is still not running, check logs with:" -ForegroundColor Cyan
Write-Host "kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller" -ForegroundColor White
