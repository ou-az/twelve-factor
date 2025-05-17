# PowerShell script to properly handle deployment replacement with immutable fields

# Step 1: Get the current deployment selector to match it exactly
Write-Host "Checking current deployment selector..." -ForegroundColor Yellow
$CURRENT_SELECTOR = kubectl get deployment aws-load-balancer-controller -n kube-system -o jsonpath='{.spec.selector.matchLabels}'
Write-Host "Current selector: $CURRENT_SELECTOR" -ForegroundColor Cyan

# Step 2: Delete the existing deployment before applying the new one 
Write-Host "Deleting existing deployment..." -ForegroundColor Yellow
kubectl delete deployment aws-load-balancer-controller -n kube-system

# Step 3: Wait for deletion to complete
Write-Host "Waiting for deployment deletion to complete..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Step 4: Create the fixed deployment that disables the webhook
$FIXED_CONTROLLER = @"
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
      containers:
      - name: controller
        image: amazon/aws-alb-ingress-controller:v2.4.4
        args:
        - --cluster-name=ecommerce-eks-cluster
        - --ingress-class=alb
        - --aws-region=us-west-2
        - --disable-webhook=true
        resources:
          limits:
            cpu: 200m
            memory: 500Mi
          requests:
            cpu: 100m
            memory: 200Mi
      serviceAccountName: aws-load-balancer-controller
"@

Set-Content -Path "fixed-controller-deployment.yaml" -Value $FIXED_CONTROLLER

# Step 5: Apply the new deployment
Write-Host "Applying fixed controller deployment..." -ForegroundColor Yellow
kubectl apply -f fixed-controller-deployment.yaml

# Step 6: Delete the webhook if it exists
Write-Host "Removing webhook configuration..." -ForegroundColor Yellow
kubectl delete validatingwebhookconfiguration aws-load-balancer-webhook --ignore-not-found

# Step 7: Wait for the controller to start
Write-Host "Waiting for controller to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Step 8: Check controller status
Write-Host "Checking controller status:" -ForegroundColor Cyan
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

# Step 9: Instructions for applying the ingress
Write-Host "`nApply your ALB ingress with:" -ForegroundColor Green
Write-Host "kubectl apply -f updated-alb-ingress.yaml" -ForegroundColor White
