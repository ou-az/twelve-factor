# PowerShell script to install AWS Load Balancer Controller from scratch

# Extract cluster name from current context
$CONTEXT = kubectl config current-context
if ($CONTEXT -match "cluster/(.*?)($|\s)") {
    $CLUSTER_NAME = $Matches[1]
} else {
    $CLUSTER_NAME = "ecommerce-eks-cluster"  # Default based on your previous output
}

Write-Host "Installing AWS Load Balancer Controller for cluster: $CLUSTER_NAME" -ForegroundColor Cyan

# Get AWS Account ID
$ACCOUNT_ID = aws sts get-caller-identity --query "Account" --output text
Write-Host "AWS Account ID: $ACCOUNT_ID" -ForegroundColor Green

# We need to ensure we're using the correct region
$AWS_REGION = "us-west-2"  # Force to us-west-2 as that's where your cluster is
Write-Host "Using AWS Region: $AWS_REGION" -ForegroundColor Green

# Create basic controller deployment YAML directly
$CONTROLLER_YAML = @"
apiVersion: v1
kind: ServiceAccount
metadata:
  name: aws-load-balancer-controller
  namespace: kube-system
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: aws-load-balancer-controller
  namespace: kube-system
  labels:
    app.kubernetes.io/name: aws-load-balancer-controller
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: aws-load-balancer-controller
  template:
    metadata:
      labels:
        app.kubernetes.io/name: aws-load-balancer-controller
    spec:
      serviceAccountName: aws-load-balancer-controller
      containers:
      - name: controller
        image: amazon/aws-alb-ingress-controller:v2.5.0
        args:
        - --cluster-name=$CLUSTER_NAME
        - --ingress-class=alb
        env:
        - name: AWS_REGION
          value: $AWS_REGION
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: aws-load-balancer-controller
rules:
  - apiGroups:
      - ""
    resources:
      - endpoints
      - nodes
      - pods
      - secrets
      - services
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - ""
    resources:
      - events
    verbs:
      - create
      - patch
  - apiGroups:
      - ""
    resources:
      - configmaps
    verbs:
      - get
      - list
      - watch
      - create
      - update
      - patch
  - apiGroups:
      - ""
    resources:
      - pods/status
    verbs:
      - update
      - patch
  - apiGroups:
      - ""
    resources:
      - pods/eviction
      - pods/finalizers
    verbs:
      - update
  - apiGroups:
      - extensions
      - networking.k8s.io
    resources:
      - ingresses
      - ingressclasses
    verbs:
      - get
      - list
      - watch
      - update
      - create
      - patch
  - apiGroups:
      - extensions
      - networking.k8s.io
    resources:
      - ingresses/status
    verbs:
      - update
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: aws-load-balancer-controller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: aws-load-balancer-controller
subjects:
  - kind: ServiceAccount
    name: aws-load-balancer-controller
    namespace: kube-system
"@

Set-Content -Path "alb-controller-direct.yaml" -Value $CONTROLLER_YAML

Write-Host "Created ALB Controller manifest. Installing..." -ForegroundColor Yellow
kubectl apply -f alb-controller-direct.yaml

Write-Host "`nCompleted basic installation." -ForegroundColor Green
Write-Host "Now waiting for controller pod to start..." -ForegroundColor Yellow

Start-Sleep -Seconds 10

Write-Host "`nChecking controller status:" -ForegroundColor Cyan
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

Write-Host "`nAWS Load Balancer Controller installation complete!" -ForegroundColor Green
Write-Host "You can now apply your ALB Ingress resources:" -ForegroundColor Cyan
Write-Host "kubectl apply -f aws-alb-ingress.yaml" -ForegroundColor White
