# PowerShell script to set up AWS Load Balancer Controller IAM roles using AWS CLI directly
# Without requiring eksctl

# Get cluster info
Set-Location C:\workspaces\interview\twelve-factor\ecommerce-microservices\terraform\environments\prod
$CLUSTER_NAME = terraform output -raw eks_cluster_name
$AWS_REGION = terraform output -raw aws_region
$ACCOUNT_ID = aws sts get-caller-identity --query "Account" --output text

Write-Host "Setting up IAM for AWS Load Balancer Controller on cluster: $CLUSTER_NAME" -ForegroundColor Cyan
Write-Host "AWS Account ID: $ACCOUNT_ID" -ForegroundColor Cyan

# Create load balancer controller policy file
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json" -OutFile "iam-policy.json"

# Create IAM policy
Write-Host "Creating IAM policy..." -ForegroundColor Yellow
$POLICY_ARN = aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam-policy.json --query 'Policy.Arn' --output text

Write-Host "Policy created with ARN: $POLICY_ARN" -ForegroundColor Green

# Create trust relationship policy document
$TRUST_POLICY = @"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${ACCOUNT_ID}:oidc-provider/oidc.eks.${AWS_REGION}.amazonaws.com/id/$(aws eks describe-cluster --name $CLUSTER_NAME --query "cluster.identity.oidc.issuer" --output text | Cut-d'/' -f5)"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.${AWS_REGION}.amazonaws.com/id/$(aws eks describe-cluster --name $CLUSTER_NAME --query "cluster.identity.oidc.issuer" --output text | Cut-d'/' -f5):sub": "system:serviceaccount:kube-system:aws-load-balancer-controller"
        }
      }
    }
  ]
}
"@

Set-Content -Path "trust-policy.json" -Value $TRUST_POLICY

# Create IAM role
Write-Host "Creating IAM role..." -ForegroundColor Yellow
$ROLE_NAME = "AmazonEKSLoadBalancerControllerRole"
aws iam create-role --role-name $ROLE_NAME --assume-role-policy-document file://trust-policy.json

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

# Restart AWS Load Balancer Controller
Write-Host "Restarting AWS Load Balancer Controller..." -ForegroundColor Yellow
kubectl delete pod -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

Write-Host "`nIAM setup complete! The Load Balancer Controller should now have proper permissions." -ForegroundColor Green
Write-Host "Give it a few minutes to initialize and check status with:" -ForegroundColor Cyan
Write-Host "kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller" -ForegroundColor White
