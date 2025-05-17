# PowerShell script to install AWS Load Balancer Controller directly using kubectl
# This approach doesn't require cluster name or OIDC provider configuration

Write-Host "Downloading AWS Load Balancer Controller YAML..." -ForegroundColor Cyan
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.5.4/docs/install/v2_5_4_full.yaml" -OutFile "aws-lb-controller-original.yaml"

# First, check what cluster name is needed
Write-Host "Retrieving current Kubernetes cluster info..." -ForegroundColor Yellow
$CLUSTER_INFO = kubectl config current-context
Write-Host "Current Kubernetes context: $CLUSTER_INFO" -ForegroundColor Green

# Get AWS Account ID
Write-Host "Getting AWS account ID..." -ForegroundColor Yellow
$ACCOUNT_ID = aws sts get-caller-identity --query "Account" --output text
Write-Host "AWS Account ID: $ACCOUNT_ID" -ForegroundColor Green

# Get AWS Region 
$AWS_REGION = aws configure get region
if (-not $AWS_REGION) {
    $AWS_REGION = "us-west-2"  # Default to us-west-2 if not set
}
Write-Host "AWS Region: $AWS_REGION" -ForegroundColor Green

# Prompt for cluster name
Write-Host "`nWhat is your EKS cluster name? (shown in AWS console or from 'aws eks list-clusters')" -ForegroundColor Yellow
$CLUSTER_NAME = Read-Host -Prompt "Cluster name"

if (-not $CLUSTER_NAME) {
    # Try to extract from context
    if ($CLUSTER_INFO -match "EKS:([^:]+)") {
        $CLUSTER_NAME = $Matches[1]
        Write-Host "Using cluster name from context: $CLUSTER_NAME" -ForegroundColor Green
    } else {
        # Fallback to asking again
        Write-Host "No cluster name detected. Please enter it manually:" -ForegroundColor Red
        $CLUSTER_NAME = Read-Host -Prompt "Cluster name (REQUIRED)"
        
        if (-not $CLUSTER_NAME) {
            Write-Host "ERROR: Cluster name is required to proceed." -ForegroundColor Red
            exit 1
        }
    }
}

Write-Host "Using cluster name: $CLUSTER_NAME" -ForegroundColor Green

# Modify the controller YAML to use the correct cluster name
(Get-Content -Path "aws-lb-controller-original.yaml") -replace "your-cluster-name", $CLUSTER_NAME | Set-Content -Path "aws-lb-controller.yaml"

Write-Host "`nCreating controller resources..." -ForegroundColor Yellow
kubectl apply -f aws-lb-controller.yaml

Write-Host "`nWaiting for controller to start (this may take a few minutes)..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

Write-Host "`nChecking controller status:" -ForegroundColor Cyan
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

Write-Host "`nAWS Load Balancer Controller installation complete!" -ForegroundColor Green
Write-Host "You can now apply your ALB Ingress resources." -ForegroundColor Cyan
Write-Host "kubectl apply -f aws-alb-ingress.yaml" -ForegroundColor White
