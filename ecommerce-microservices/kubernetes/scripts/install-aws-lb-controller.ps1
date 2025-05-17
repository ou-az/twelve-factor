# PowerShell script to install AWS Load Balancer Controller on EKS

# Get cluster name from Terraform output
cd C:\workspaces\interview\twelve-factor\ecommerce-microservices\terraform\environments\prod
$CLUSTER_NAME = terraform output -raw eks_cluster_name
$AWS_REGION = terraform output -raw aws_region
$VPC_ID = terraform output -raw vpc_id

Write-Host "Installing AWS Load Balancer Controller for cluster: $CLUSTER_NAME in region: $AWS_REGION"

# Add the EKS chart repo to Helm
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# Apply CRDS
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"

# Install the Controller
helm install aws-load-balancer-controller eks/aws-load-balancer-controller `
  -n kube-system `
  --set clusterName=$CLUSTER_NAME `
  --set serviceAccount.create=true `
  --set region=$AWS_REGION `
  --set vpcId=$VPC_ID

Write-Host "AWS Load Balancer Controller installation complete!" -ForegroundColor Green
Write-Host "This enhances your EKS cluster with AWS-native load balancing capabilities."
