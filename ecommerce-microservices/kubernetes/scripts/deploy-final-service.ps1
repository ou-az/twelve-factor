# Enterprise Final Deployment Script
# Creates a fresh deployment with proper labeling and configuration

Write-Host "ENTERPRISE FINAL DEPLOYMENT" -ForegroundColor Cyan

# 1. Check all running pods to see their labels
Write-Host "`nChecking all pods in namespace..." -ForegroundColor Yellow
kubectl get pods -n ecommerce --show-labels

# 2. Get PostgreSQL pod name
$PG_POD = kubectl get pods -n ecommerce -l app=postgres -o jsonpath='{.items[0].metadata.name}'
Write-Host "`nIdentified PostgreSQL pod: $PG_POD" -ForegroundColor Yellow

# 3. Set a known password in PostgreSQL directly using SQL
Write-Host "`nSetting known password in PostgreSQL..." -ForegroundColor Yellow
kubectl exec -it $PG_POD -n ecommerce -- psql -U postgres -c "ALTER USER postgres WITH PASSWORD 'YOUR_DB_PASSWORD';"

# 4. Create a matching secret for the application
Write-Host "`nCreating matching secret for Spring Boot application..." -ForegroundColor Yellow
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

Set-Content -Path "final-secret.yaml" -Value $DB_SECRET
kubectl apply -f final-secret.yaml

# 5. Create final deployment for product service
Write-Host "`nCreating final product service deployment..." -ForegroundColor Yellow
$FINAL_DEPLOYMENT = @"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: product-service
  namespace: ecommerce
  labels:
    app: product-service
spec:
  replicas: 1
  selector:
    matchLabels:
      app: product-service
  template:
    metadata:
      labels:
        app: product-service
    spec:
      containers:
      - name: product-service
        image: REPLACE_WITH_YOUR_IMAGE
        ports:
        - containerPort: 8080
        env:
        - name: SPRING_MAIN_ALLOW_BEAN_DEFINITION_OVERRIDING
          value: "true"
        - name: SPRING_JPA_HIBERNATE_DDL_AUTO
          value: "update"
        - name: SPRING_JPA_GENERATE_DDL
          value: "true"
        - name: SPRING_JPA_DATABASE_PLATFORM
          value: "org.hibernate.dialect.PostgreSQLDialect"
        - name: SPRING_JPA_SHOW_SQL
          value: "true"
        - name: SPRING_FLYWAY_ENABLED
          value: "false"
        envFrom:
        - secretRef:
            name: product-service-secrets
        resources:
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          initialDelaySeconds: 120
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 6
          httpGet:
            path: /actuator/health
            port: 8080
        readinessProbe:
          initialDelaySeconds: 60
          periodSeconds: 10
          timeoutSeconds: 5
          httpGet:
            path: /actuator/health
            port: 8080
"@

# 6. Get the current image name
Write-Host "`nGetting application image..." -ForegroundColor Yellow
kubectl get all -n ecommerce | Select-String -Pattern "product-service"
$DEPLOYMENTS = kubectl get deployment -n ecommerce
Write-Host "Current deployments: $DEPLOYMENTS" -ForegroundColor Cyan

# For simplicity, let's hardcode a common ECR repository pattern, you would replace this
$ECR_REPO = "ACCOUNT_ID.dkr.ecr.REGION.amazonaws.com/product-service:latest"
$CURRENT_IMAGE = $ECR_REPO

Write-Host "`nUsing image: $CURRENT_IMAGE" -ForegroundColor Cyan
(Get-Content -Raw "final-deployment.yaml") -replace "REPLACE_WITH_YOUR_IMAGE", $CURRENT_IMAGE | Set-Content "final-deployment.yaml"

# 7. Apply the deployment
Write-Host "`nApplying deployment..." -ForegroundColor Green
kubectl apply -f final-deployment.yaml

# 8. Update service
Write-Host "`nUpdating service..." -ForegroundColor Yellow
$SERVICE_YAML = @"
apiVersion: v1
kind: Service
metadata:
  name: product-service-loadbalancer
  namespace: ecommerce
spec:
  selector:
    app: product-service
  ports:
  - port: 80
    targetPort: 8080
  type: LoadBalancer
"@

Set-Content -Path "final-service.yaml" -Value $SERVICE_YAML
kubectl apply -f final-service.yaml

# 9. Wait for deployment
Write-Host "`nWaiting for deployment..." -ForegroundColor Yellow
Start-Sleep -Seconds 15
kubectl get pods -n ecommerce -l app=product-service

Write-Host @"

===========================================================
ENTERPRISE FINAL DEPLOYMENT COMPLETE

This final deployment ensures all components are correctly labeled
and configured. After deployment completes, check your application
status with:

kubectl get pods -n ecommerce -l app=product-service
kubectl logs -n ecommerce -l app=product-service

Then test your API at:
http://YOUR_ELB_URL/api/products
===========================================================
"@ -ForegroundColor Green
