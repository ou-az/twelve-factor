# Script to fix the product service deployment issues

# First, clean up the previous failed deployment
Write-Host "Cleaning up previous failed deployment..." -ForegroundColor Cyan
kubectl delete deployment product-service-fixed -n ecommerce --ignore-not-found
kubectl delete service product-service-fixed -n ecommerce --ignore-not-found
kubectl delete configmap product-service-minimal-config -n ecommerce --ignore-not-found

# 1. Create a more focused config with only what's needed
Write-Host "Creating minimal configuration for product-service..." -ForegroundColor Cyan

# Create a ConfigMap with the essential configuration, disabling Kafka
$configYaml = @"
apiVersion: v1
kind: ConfigMap
metadata:
  name: product-service-minimal-config
  namespace: ecommerce
data:
  application.yml: |
    spring:
      application:
        name: product-service
      profiles:
        active: postgres
      datasource:
        url: jdbc:postgresql://postgres-fixed:5432/productdb
        username: postgres
        password: YOUR_DB_PASSWORD
        driver-class-name: org.postgresql.Driver
        hikari:
          maximum-pool-size: 5
      jpa:
        hibernate:
          ddl-auto: update
        properties:
          hibernate:
            dialect: org.hibernate.dialect.PostgreSQLDialect
        show-sql: true
      kafka:
        enabled: false
    
    server:
      port: 8081
      
    logging:
      level:
        com.ecommerce.product: DEBUG
        org.springframework: INFO
"@

# Write the ConfigMap to a file
$configYaml | Out-File -FilePath "product-service-minimal-config.yaml" -Encoding utf8

# Apply the ConfigMap
Write-Host "Applying minimal configuration ConfigMap..." -ForegroundColor Cyan
kubectl apply -f product-service-minimal-config.yaml

# 2. Create a new deployment that uses the minimal config and disables Kafka
$deploymentYaml = @"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: product-service-fixed
  namespace: ecommerce
spec:
  replicas: 1
  selector:
    matchLabels:
      app: product-service-fixed
  template:
    metadata:
      labels:
        app: product-service-fixed
    spec:
      containers:
      - name: product-service
        image: YOUR_AWS_ACCOUNT_ID.dkr.ecr.us-west-2.amazonaws.com/ecommerce-product-service:latest
        ports:
        - containerPort: 8081
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "postgres"
        - name: SPRING_CONFIG_LOCATION
          value: "classpath:/,/config/"
        - name: SPRING_KAFKA_ENABLED
          value: "false"
        - name: SPRING_DATASOURCE_URL
          value: "jdbc:postgresql://postgres-fixed:5432/productdb"
        - name: SPRING_DATASOURCE_USERNAME
          value: "postgres"
        - name: SPRING_DATASOURCE_PASSWORD
          value: "YOUR_DB_PASSWORD"
        volumeMounts:
        - name: config-volume
          mountPath: /config
        readinessProbe:
          httpGet:
            path: /actuator/health
            port: 8081
          initialDelaySeconds: 60
          periodSeconds: 15
        livenessProbe:
          httpGet:
            path: /actuator/health
            port: 8081
          initialDelaySeconds: 120
          periodSeconds: 30
      volumes:
      - name: config-volume
        configMap:
          name: product-service-minimal-config
"@

# Write the deployment to a file
$deploymentYaml | Out-File -FilePath "product-service-fixed-deployment.yaml" -Encoding utf8

# Apply the deployment
Write-Host "Applying fixed product service deployment..." -ForegroundColor Cyan
kubectl apply -f product-service-fixed-deployment.yaml

# 3. Create a service for the fixed deployment
$serviceYaml = @"
apiVersion: v1
kind: Service
metadata:
  name: product-service-fixed
  namespace: ecommerce
spec:
  selector:
    app: product-service-fixed
  ports:
  - port: 8081
    targetPort: 8081
  type: ClusterIP
"@

# Write the service to a file
$serviceYaml | Out-File -FilePath "product-service-fixed-service.yaml" -Encoding utf8

# Apply the service
Write-Host "Applying service for fixed product service..." -ForegroundColor Cyan
kubectl apply -f product-service-fixed-service.yaml

# 4. Wait for the deployment to be ready
Write-Host "Waiting for the fixed deployment to be ready..." -ForegroundColor Cyan
kubectl rollout status deployment/product-service-fixed -n ecommerce

# 5. Check pod status
Write-Host "Checking pod status..." -ForegroundColor Cyan
kubectl get pods -n ecommerce | findstr product-service-fixed

# 6. Test service via port-forward
Write-Host "Setting up port forwarding to test the service..." -ForegroundColor Cyan
$pod = kubectl get pods -n ecommerce -l app=product-service-fixed -o jsonpath="{.items[0].metadata.name}"
if ($pod) {
    Start-Process powershell -ArgumentList "-Command","kubectl port-forward $pod 8082:8081 -n ecommerce"
    Write-Host "Port forwarding set up. You can access the service at http://localhost:8082"
    Write-Host "Try accessing http://localhost:8082/actuator/health in your browser to verify the service is healthy"
} else {
    Write-Host "No product-service-fixed pod found" -ForegroundColor Red
}

Write-Host "Deployment fix completed!" -ForegroundColor Green
Write-Host "The service should now be accessible without Kafka dependencies" -ForegroundColor Green
