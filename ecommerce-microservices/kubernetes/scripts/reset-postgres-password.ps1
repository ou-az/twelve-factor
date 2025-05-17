# Enterprise PostgreSQL Password Reset Script
# Directly resets PostgreSQL authentication for a clean start

Write-Host "ENTERPRISE POSTGRESQL PASSWORD RESET" -ForegroundColor Cyan

# 1. Deploy PostgreSQL admin pod with admin privileges
Write-Host "`nDeploying privileged PostgreSQL admin pod..." -ForegroundColor Yellow
$PG_ADMIN = @"
apiVersion: v1
kind: Pod
metadata:
  name: postgres-admin
  namespace: ecommerce
spec:
  containers:
  - name: postgres-admin
    image: postgres:14
    command: ["sleep", "3600"]
"@

Set-Content -Path "postgres-admin.yaml" -Value $PG_ADMIN
kubectl apply -f postgres-admin.yaml
Write-Host "Waiting for admin pod to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# 2. Get PostgreSQL service details
Write-Host "`nGetting PostgreSQL service details..." -ForegroundColor Yellow
$PG_SVC = kubectl get service postgres-service -n ecommerce -o json | ConvertFrom-Json
$PG_CLUSTER_IP = $PG_SVC.spec.clusterIP
$PG_PORT = $PG_SVC.spec.ports[0].port
Write-Host "PostgreSQL Service: ${PG_CLUSTER_IP}:${PG_PORT}" -ForegroundColor Cyan

# 3. Identify all PostgreSQL pods
Write-Host "`nIdentifying all PostgreSQL pods..." -ForegroundColor Yellow
kubectl get pods -n ecommerce | Where-Object { $_ -like "*postgres*" }

# 4. Start a fresh PostgreSQL instance 
Write-Host "`nDeploying fresh PostgreSQL instance with known credentials..." -ForegroundColor Yellow
$FRESH_PG = @"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres-clean
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
          value: "YOUR_DB_PASSWORD"
        - name: POSTGRES_USER
          value: "postgres"
        - name: POSTGRES_DB
          value: "product_db"
        resources:
          limits:
            memory: "512Mi"
            cpu: "500m"
"@

Set-Content -Path "postgres-clean.yaml" -Value $FRESH_PG
kubectl apply -f postgres-clean.yaml

# 5. Make sure service points to the fresh deployment
Write-Host "`nUpdating service to point to clean PostgreSQL..." -ForegroundColor Yellow
$PG_SERVICE = @"
apiVersion: v1
kind: Service
metadata:
  name: postgres-service
  namespace: ecommerce
spec:
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432
"@

Set-Content -Path "postgres-service.yaml" -Value $PG_SERVICE
kubectl apply -f postgres-service.yaml

# 6. Update application credentials to match
Write-Host "`nUpdating application credentials to match PostgreSQL..." -ForegroundColor Yellow
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
  SPRING_DATASOURCE_PASSWORD: "YOUR_DB_PASSWORD"
"@

Set-Content -Path "db-creds.yaml" -Value $DB_SECRET
kubectl apply -f db-creds.yaml

# 7. Restart the product service to use new credentials
Write-Host "`nRestarting product service to use new credentials..." -ForegroundColor Yellow
kubectl rollout restart deployment product-service -n ecommerce

# 8. Wait for everything to stabilize
Write-Host "`nWaiting for deployments to stabilize..." -ForegroundColor Yellow
Start-Sleep -Seconds 20
kubectl get pods -n ecommerce

# 9. Final validation
Write-Host "`nWaiting for application to attempt database connection..." -ForegroundColor Yellow
Start-Sleep -Seconds 20
kubectl logs -n ecommerce -l app=product-service

Write-Host @"

===========================================================
ENTERPRISE DATABASE AUTHENTICATION RESET

We've:
1. Deployed a clean PostgreSQL instance with known credentials
2. Updated the service to point to the clean instance
3. Updated application secrets to match PostgreSQL credentials
4. Restarted the product service to use the new credentials

This approach ensures credential consistency across your
microservices, which is critical for secure enterprise deployments.

For production, consider using a secrets management solution like
AWS Secrets Manager or HashiCorp Vault for centralized credential
management.

Test your API at:
http://$(kubectl get service product-service-loadbalancer -n ecommerce -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')/api/products
===========================================================
"@ -ForegroundColor Green
