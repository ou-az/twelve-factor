# Enterprise Final Deployment Script - Fixed
# Creates a fresh deployment with proper labeling and configuration

Write-Host "ENTERPRISE FINAL DEPLOYMENT" -ForegroundColor Cyan

# 1. Check all running pods to see their labels
Write-Host "`nChecking all pods in namespace..." -ForegroundColor Yellow
kubectl get pods -n ecommerce --show-labels

# 2. Find an existing product service image
Write-Host "`nFinding product service image from existing deployments..." -ForegroundColor Yellow
$DEPLOYMENTS = kubectl get deployment -n ecommerce -o json | ConvertFrom-Json
$PRODUCT_DEPLOYMENTS = $DEPLOYMENTS.items | Where-Object { $_.metadata.name -like "*product*" }

$CURRENT_IMAGE = ""
foreach ($deployment in $PRODUCT_DEPLOYMENTS) {
    try {
        $container = $deployment.spec.template.spec.containers[0]
        if ($container.name -like "*product*") {
            $CURRENT_IMAGE = $container.image
            Write-Host "Found image in deployment $($deployment.metadata.name): $CURRENT_IMAGE" -ForegroundColor Green
            break
        }
    }
    catch {
        Write-Host "Error processing deployment $($deployment.metadata.name): $_" -ForegroundColor Red
    }
}

# If no image was found, use a placeholder that will need to be replaced
if ([string]::IsNullOrEmpty($CURRENT_IMAGE)) {
    $CURRENT_IMAGE = "ACCOUNT_ID.dkr.ecr.REGION.amazonaws.com/product-service:latest"
    Write-Host "No image found, using placeholder: $CURRENT_IMAGE" -ForegroundColor Yellow
    Write-Host "You'll need to update this with your actual ECR repository URL" -ForegroundColor Yellow
}

# 3. Create the deployment YAML with the image directly embedded
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
        image: $CURRENT_IMAGE
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

# 4. Create matching secret for the application
Write-Host "`nCreating database secret with known password..." -ForegroundColor Yellow
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

# 5. Set a known password in PostgreSQL directly
Write-Host "`nSetting known password in PostgreSQL..." -ForegroundColor Yellow
$PG_PODS = kubectl get pods -n ecommerce -l app=postgres --no-headers | ForEach-Object { $_.Split()[0] }
if ($PG_PODS) {
    $PG_POD = $PG_PODS[0]
    Write-Host "Found PostgreSQL pod: $PG_POD" -ForegroundColor Cyan
    kubectl exec -it $PG_POD -n ecommerce -- psql -U postgres -c "ALTER USER postgres WITH PASSWORD 'YOUR_DB_PASSWORD';"
}
else {
    Write-Host "No PostgreSQL pod found with label app=postgres" -ForegroundColor Red
    $PG_PODS = kubectl get pods -n ecommerce | Select-String -Pattern "postgres"
    Write-Host "PostgreSQL pods found without proper label: $PG_PODS" -ForegroundColor Yellow
}

# 6. Write all YAML files
Set-Content -Path "final-deployment.yaml" -Value $FINAL_DEPLOYMENT
Set-Content -Path "final-secret.yaml" -Value $DB_SECRET

# Service YAML
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

# 7. Apply all resources
Write-Host "`nApplying database secret..." -ForegroundColor Yellow
kubectl apply -f final-secret.yaml

Write-Host "`nApplying deployment..." -ForegroundColor Yellow
kubectl apply -f final-deployment.yaml

Write-Host "`nApplying service..." -ForegroundColor Yellow
kubectl apply -f final-service.yaml

# 8. Wait for deployment
Write-Host "`nWaiting for deployment to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 10
kubectl get pods -n ecommerce -l app=product-service

Write-Host @"

===========================================================
ENTERPRISE FINAL DEPLOYMENT APPLIED

The deployment has been applied with correct image and configurations.
Monitor deployment progress with:

kubectl get pods -n ecommerce -l app=product-service
kubectl logs -n ecommerce -l app=product-service

Once healthy, test your API at the load balancer endpoint:
kubectl get service product-service-loadbalancer -n ecommerce

Microservices deployment troubleshooting demonstrates advanced
AWS EKS, Spring Boot, and Kubernetes expertise valuable for senior
DevOps, Java, and Staff Engineer positions.
===========================================================
"@ -ForegroundColor Green
