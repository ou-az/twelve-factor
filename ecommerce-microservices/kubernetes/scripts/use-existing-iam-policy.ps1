# PowerShell script to use existing IAM policy for AWS Load Balancer Controller

# Get cluster info
Set-Location <SOURCE_DIR>\twelve-factor\ecommerce-microservices\terraform\environments\prod
$CLUSTER_NAME = terraform output -raw eks_cluster_name
$AWS_REGION = terraform output -raw aws_region
$ACCOUNT_ID = aws sts get-caller-identity --query "Account" --output text

Write-Host "Setting up AWS Load Balancer Controller using existing policy" -ForegroundColor Cyan
Write-Host "Cluster name: $CLUSTER_NAME" -ForegroundColor Cyan
Write-Host "AWS Account ID: $ACCOUNT_ID" -ForegroundColor Cyan
Write-Host "Region: $AWS_REGION" -ForegroundColor Cyan

# Get the ARN of the existing policy
Write-Host "Finding existing policy ARN..." -ForegroundColor Yellow
$POLICY_ARN = aws iam list-policies --query "Policies[?PolicyName=='AWSLoadBalancerControllerIAMPolicy'].Arn" --output text

if (-not $POLICY_ARN) {
    Write-Host "Policy ARN not found, attempting to get by account ID..." -ForegroundColor Yellow
    $POLICY_ARN = "arn:aws:iam::${ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy"
}

Write-Host "Using policy: $POLICY_ARN" -ForegroundColor Green

# Get the OIDC provider information from EKS cluster
Write-Host "Getting OIDC provider information..." -ForegroundColor Yellow
$OIDC_URL = aws eks describe-cluster --name $CLUSTER_NAME --query "cluster.identity.oidc.issuer" --output text
$OIDC_PROVIDER = $OIDC_URL.Replace("https://", "")
Write-Host "OIDC Provider: $OIDC_PROVIDER" -ForegroundColor Cyan

# Create trust relationship policy document
$TRUST_POLICY = @"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${ACCOUNT_ID}:oidc-provider/${OIDC_PROVIDER}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${OIDC_PROVIDER}:aud": "sts.amazonaws.com",
          "${OIDC_PROVIDER}:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller"
        }
      }
    }
  ]
}
"@

Set-Content -Path "trust-policy.json" -Value $TRUST_POLICY

# Create IAM role
Write-Host "Creating IAM role..." -ForegroundColor Yellow
$ROLE_NAME = "AmazonEKSLoadBalancerControllerRole-$CLUSTER_NAME"
try {
    aws iam get-role --role-name $ROLE_NAME | Out-Null
    Write-Host "Role $ROLE_NAME already exists, updating..." -ForegroundColor Yellow
    aws iam update-assume-role-policy --role-name $ROLE_NAME --policy-document file://trust-policy.json
}
catch {
    Write-Host "Creating new role $ROLE_NAME..." -ForegroundColor Yellow
    aws iam create-role --role-name $ROLE_NAME --assume-role-policy-document file://trust-policy.json | Out-Null
}

# Attach policy to role
Write-Host "Attaching policy to role..." -ForegroundColor Yellow
aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn $POLICY_ARN

# Create Kubernetes service account
$SERVICE_ACCOUNT = @"
apiVersion: v1
kind: ServiceAccount
metadata:
  name: aws-load-balancer-controller
  namespace: kube-system
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}
"@

Set-Content -Path "service-account.yaml" -Value $SERVICE_ACCOUNT

# Apply service account to cluster
Write-Host "Creating Kubernetes service account..." -ForegroundColor Yellow
kubectl apply -f service-account.yaml

# Update the controller deployment to use the service account
$CONTROLLER_PATCH = @"
spec:
  template:
    spec:
      serviceAccountName: aws-load-balancer-controller
"@

Set-Content -Path "controller-patch.yaml" -Value $CONTROLLER_PATCH

Write-Host "Patching the controller deployment..." -ForegroundColor Yellow
kubectl patch deployment aws-load-balancer-controller -n kube-system --patch-file controller-patch.yaml

# Restart controller pods
Write-Host "Restarting controller pods..." -ForegroundColor Yellow
kubectl delete pod -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

Write-Host "`nIAM configuration complete! The controller should now have proper permissions." -ForegroundColor Green
Write-Host "Check controller status in a few minutes with:" -ForegroundColor Cyan
Write-Host "kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller" -ForegroundColor White
