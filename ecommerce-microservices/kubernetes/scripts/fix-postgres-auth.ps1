# Enterprise PostgreSQL Authentication Configuration
# Synchronizes database credentials between PostgreSQL and Spring Boot service

Write-Host "Fixing PostgreSQL Authentication Configuration..." -ForegroundColor Cyan

# 1. Check PostgreSQL service and pod details
Write-Host "`nExamining PostgreSQL deployment..." -ForegroundColor Yellow
$PG_POD = kubectl get pods -n ecommerce -l app=postgres -o jsonpath='{.items[0].metadata.name}'
kubectl describe pod $PG_POD -n ecommerce

# 2. Check PostgreSQL environment variables to find configured password
Write-Host "`nChecking PostgreSQL environment variables..." -ForegroundColor Yellow
$PG_ENV = kubectl exec $PG_POD -n ecommerce -- env
Write-Host $PG_ENV

# 3. Create new PostgreSQL configuration with explicit password
Write-Host "`nCreating PostgreSQL configuration with fixed password..." -ForegroundColor Yellow
$PG_CONFIG = @"
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-config
  namespace: ecommerce
data:
  POSTGRES_DB: "product_db"
  POSTGRES_USER: "postgres"
  POSTGRES_PASSWORD: "postgres"
"@

Set-Content -Path "postgres-config.yaml" -Value $PG_CONFIG
kubectl apply -f postgres-config.yaml

# 4. Recreate PostgreSQL deployment with consistent password
Write-Host "`nRecreating PostgreSQL deployment with consistent password..." -ForegroundColor Yellow
$POSTGRES_DEPLOYMENT = @"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
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
        envFrom:
        - configMapRef:
            name: postgres-config
        resources:
          limits:
            memory: "512Mi"
            cpu: "500m"
          requests:
            memory: "256Mi"
            cpu: "250m"
"@

Set-Content -Path "postgres-deployment.yaml" -Value $POSTGRES_DEPLOYMENT
kubectl apply -f postgres-deployment.yaml

# 5. Update product service secret with matching PostgreSQL password
Write-Host "`nUpdating product service secrets with matching database password..." -ForegroundColor Yellow
$DB_SECRET = @"
apiVersion: v1
kind: Secret
metadata:
  name: product-service-secrets
  namespace: ecommerce
type: Opaque
stringData:
  SPRING_DATASOURCE_URL: "jdbc:postgresql://postgres-service:5432/product_db"
  SPRING_DATASOURCE_USERNAME: "postgres"
  SPRING_DATASOURCE_PASSWORD: "postgres"
"@

Set-Content -Path "db-secret.yaml" -Value $DB_SECRET
kubectl apply -f db-secret.yaml

# 6. Wait for PostgreSQL pod to be ready
Write-Host "`nWaiting for PostgreSQL pod to be ready..." -ForegroundColor Yellow
kubectl rollout status deployment/postgres -n ecommerce

# 7. Restart product service to reconnect to database
Write-Host "`nRestarting product service to reconnect to database..." -ForegroundColor Yellow
kubectl rollout restart deployment/product-service -n ecommerce
kubectl rollout status deployment/product-service -n ecommerce

# 8. Check pod status after restart
Write-Host "`nChecking pod status after restart..." -ForegroundColor Cyan
kubectl get pods -n ecommerce

# 9. Check logs for successful database connection
Write-Host "`nWaiting for application startup..." -ForegroundColor Yellow
Start-Sleep -Seconds 15
$PRODUCT_POD = kubectl get pods -n ecommerce -l app=product-service -o jsonpath='{.items[0].metadata.name}'
kubectl logs $PRODUCT_POD -n ecommerce | Select-String -Pattern "HikariPool|Started ProductServiceApplication"

Write-Host @"

===========================================================
ENTERPRISE DATABASE AUTHENTICATION FIX APPLIED

PostgreSQL credentials have been synchronized across:
1. PostgreSQL container environment variables
2. Spring Boot application database configuration

This ensures consistent authentication across your microservices.

Try accessing your API at:
http://aee62280f41e04181bf13ba432fd2092-001b4178947505be.elb.us-west-2.amazonaws.com/api/products
===========================================================
"@ -ForegroundColor Green
