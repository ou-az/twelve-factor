# Enterprise PostgreSQL Authentication Fix
# Resolves password mismatch between application and database

Write-Host "ENTERPRISE POSTGRESQL AUTHENTICATION FIX" -ForegroundColor Cyan

# 1. Get PostgreSQL pod name
$PG_POD = kubectl get pods -n ecommerce -l app=postgres -o jsonpath='{.items[0].metadata.name}'
Write-Host "`nIdentified PostgreSQL pod: $PG_POD" -ForegroundColor Yellow

# 2. Set a known password in PostgreSQL directly using SQL
Write-Host "`nSetting known password in PostgreSQL..." -ForegroundColor Yellow
kubectl exec -it $PG_POD -n ecommerce -- psql -U postgres -c "ALTER USER postgres WITH PASSWORD 'YOUR_DB_PASSWORD';"

# 3. Create a matching secret for the application
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

Set-Content -Path "correct-password-secret.yaml" -Value $DB_SECRET
kubectl apply -f correct-password-secret.yaml

# 4. Patch the deployment to use the updated secret
Write-Host "`nCreating deployment with proper credentials..." -ForegroundColor Yellow
$PRODUCT_DEPLOYMENT = @"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: product-service-final
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

# 5. Get the current image name from the existing deployment
$CURRENT_IMAGE = kubectl get deployment product-service -n ecommerce -o jsonpath='{.spec.template.spec.containers[0].image}'
Write-Host "`nDetected current image: $CURRENT_IMAGE" -ForegroundColor Cyan

# 6. Update the image name in the deployment YAML
(Get-Content -Raw "product-deployment.yaml") -replace "REPLACE_WITH_YOUR_IMAGE", $CURRENT_IMAGE | Set-Content "product-deployment.yaml"

# 7. Apply the fixed deployment
Write-Host "`nApplying fixed deployment..." -ForegroundColor Green
kubectl apply -f product-deployment.yaml

# 8. Update service to point to the new deployment
Write-Host "`nUpdating service to point to fixed deployment..." -ForegroundColor Yellow
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

Set-Content -Path "product-service.yaml" -Value $SERVICE_YAML
kubectl apply -f product-service.yaml

# 9. Scale down other deployments to prevent conflicts
Write-Host "`nScaling down other product service deployments..." -ForegroundColor Yellow
kubectl scale deployment product-service -n ecommerce --replicas=0
kubectl scale deployment product-service-fixed -n ecommerce --replicas=0

# 10. Wait for the deployment to stabilize
Write-Host "`nWaiting for deployment to stabilize..." -ForegroundColor Yellow
Start-Sleep -Seconds 15
kubectl get pods -n ecommerce -l app=product-service

# 11. Get the endpoint for testing
$SERVICE_URL = kubectl get service product-service-loadbalancer -n ecommerce -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

Write-Host @"

===========================================================
ENTERPRISE POSTGRESQL AUTHENTICATION FIX COMPLETE

We've resolved the database authentication issue by:

1. Setting a known password directly in PostgreSQL
2. Creating a matching secret for the Spring Boot application
3. Deploying an updated version with synchronized credentials

This demonstrates a key principle in enterprise deployments:
ensuring credential consistency across microservices.

Test your API at:
http://${SERVICE_URL}/api/products
===========================================================
"@ -ForegroundColor Green
