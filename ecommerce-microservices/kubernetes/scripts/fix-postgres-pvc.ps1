# PowerShell script to diagnose and fix PostgreSQL PVC issues

Write-Host "Investigating PostgreSQL pod pending state..." -ForegroundColor Cyan

# Check pod details to find the specific issues
Write-Host "`nGetting detailed pod information..." -ForegroundColor Yellow
$POD_NAME = kubectl get pods -n ecommerce -l app=postgres -o jsonpath='{.items[0].metadata.name}'
kubectl describe pod $POD_NAME -n ecommerce

# Check PVC status
Write-Host "`nChecking Persistent Volume Claim status..." -ForegroundColor Yellow
kubectl get pvc -n ecommerce
kubectl describe pvc postgres-data -n ecommerce

# Check storage class
Write-Host "`nChecking StorageClass configuration..." -ForegroundColor Yellow
kubectl get storageclass
kubectl describe storageclass ebs-sc

# Create a non-persistent deployment as a workaround
Write-Host "`nCreating a non-persistent PostgreSQL deployment for immediate use..." -ForegroundColor Yellow
$NON_PERSISTENT_POSTGRES = @"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres-nopvc
  namespace: ecommerce
  labels:
    app: postgres
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:14
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: product-service-secrets
              key: SPRING_DATASOURCE_PASSWORD
        - name: POSTGRES_USER
          valueFrom:
            secretKeyRef:
              name: product-service-secrets
              key: SPRING_DATASOURCE_USERNAME
        - name: POSTGRES_DB
          value: product_db
        resources:
          limits:
            memory: "512Mi"
            cpu: "500m"
          requests:
            memory: "256Mi"
            cpu: "250m"
"@

Set-Content -Path "postgres-nopvc.yaml" -Value $NON_PERSISTENT_POSTGRES

# Apply the non-persistent PostgreSQL deployment
Write-Host "`nApplying non-persistent PostgreSQL deployment..." -ForegroundColor Green
kubectl apply -f postgres-nopvc.yaml

# Wait for the pod to start
Write-Host "`nWaiting for PostgreSQL pod to start (this may take a minute)..." -ForegroundColor Yellow
Start-Sleep -Seconds 20

# Check if pod is running
Write-Host "`nVerifying PostgreSQL pod status..." -ForegroundColor Cyan
kubectl get pods -n ecommerce -l app=postgres

# Restart the product service to reconnect to database
Write-Host "`nRestarting product service to reconnect to database..." -ForegroundColor Yellow
kubectl rollout restart deployment product-service -n ecommerce

Write-Host "`nWaiting for product service to restart..." -ForegroundColor Yellow
Start-Sleep -Seconds 20

Write-Host "`nChecking product service status..." -ForegroundColor Cyan
kubectl get pods -n ecommerce -l app=product-service

Write-Host @"

===========================================================
ENTERPRISE PRODUCTION NOTES:

1. This is an EMERGENCY FIX to unblock testing (using emptyDir storage)
2. Data will NOT persist if the PostgreSQL pod restarts
3. For production, debug the PVC issue by examining:
   - AWS EBS CSI Driver status
   - StorageClass configuration
   - IAM roles for EBS access
   - VPC and subnet configuration

Next step: Test your product service API again with:
http://aee62280f41e04181bf13ba432fd2092-001b4178947505be.elb.us-west-2.amazonaws.com/api/products
===========================================================
"@ -ForegroundColor Green
