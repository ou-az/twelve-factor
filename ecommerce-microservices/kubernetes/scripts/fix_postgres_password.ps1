# Script to fix PostgreSQL password authentication issue

# Clean up previous failed deployment
Write-Host "Cleaning up previous failed deployment..." -ForegroundColor Cyan
kubectl delete deployment product-service-fixed -n ecommerce --ignore-not-found
kubectl delete configmap product-service-fixed-config -n ecommerce --ignore-not-found

# Create a new ConfigMap with the correct PostgreSQL password
Write-Host "Creating configuration with the correct PostgreSQL password..." -ForegroundColor Cyan
$configYaml = @"
apiVersion: v1
kind: ConfigMap
metadata:
  name: product-service-fixed-config
  namespace: ecommerce
data:
  application.yml: |
    spring:
      application:
        name: product-service
      profiles:
        active: postgres
      datasource:
        url: jdbc:postgresql://postgres-service:5432/product_db
        username: postgres
        password: YOUR_DB_PASSWORD
        driver-class-name: org.postgresql.Driver
        hikari:
          maximum-pool-size: 5
          connection-timeout: 30000
          idle-timeout: 600000
          max-lifetime: 1800000
      jpa:
        hibernate:
          ddl-auto: update
        properties:
          hibernate:
            dialect: org.hibernate.dialect.PostgreSQLDialect
        show-sql: true
      flyway:
        enabled: true
        baseline-on-migrate: true
        locations: classpath:db/migration
      kafka:
        enabled: false
    
    server:
      port: 8081
      
    logging:
      level:
        com.ecommerce.product: DEBUG
        org.springframework: INFO
        org.springframework.jdbc: DEBUG
        org.hibernate: INFO
        com.zaxxer.hikari: DEBUG
"@

# Write the ConfigMap to a file
$configYaml | Out-File -FilePath "product-service-fixed-config.yaml" -Encoding utf8

# Apply the ConfigMap
kubectl apply -f product-service-fixed-config.yaml

# Create a new deployment with the correct configuration
Write-Host "Creating deployment with the correct configuration..." -ForegroundColor Cyan
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
          value: "jdbc:postgresql://postgres-service:5432/product_db"
        - name: SPRING_DATASOURCE_USERNAME
          value: "postgres"
        - name: SPRING_DATASOURCE_PASSWORD
          value: "YOUR_DB_PASSWORD"
        - name: SPRING_FLYWAY_ENABLED
          value: "true"
        - name: SPRING_FLYWAY_BASELINE_ON_MIGRATE
          value: "true"
        volumeMounts:
        - name: config-volume
          mountPath: /config
        readinessProbe:
          httpGet:
            path: /actuator/health
            port: 8081
          initialDelaySeconds: 90
          periodSeconds: 15
          timeoutSeconds: 5
          failureThreshold: 5
        livenessProbe:
          httpGet:
            path: /actuator/health
            port: 8081
          initialDelaySeconds: 120
          periodSeconds: 30
          timeoutSeconds: 5
          failureThreshold: 3
      volumes:
      - name: config-volume
        configMap:
          name: product-service-fixed-config
"@

# Write the deployment to a file
$deploymentYaml | Out-File -FilePath "product-service-fixed-deployment.yaml" -Encoding utf8

# Apply the deployment
kubectl apply -f product-service-fixed-deployment.yaml

# Create or update service for the new deployment
Write-Host "Creating service for the new deployment..." -ForegroundColor Cyan
try {
    kubectl expose deployment product-service-fixed -n ecommerce --port=8081 --target-port=8081 --name=product-service-fixed --type=ClusterIP
} catch {
    # If service already exists, delete and recreate it
    kubectl delete service product-service-fixed -n ecommerce --ignore-not-found
    kubectl expose deployment product-service-fixed -n ecommerce --port=8081 --target-port=8081 --name=product-service-fixed --type=ClusterIP
}

# Wait for the deployment to be ready
Write-Host "Waiting for the deployment to be ready..." -ForegroundColor Cyan
kubectl rollout status deployment/product-service-fixed -n ecommerce --timeout=120s

# Check pod status
Write-Host "Checking pod status..." -ForegroundColor Cyan
kubectl get pods -n ecommerce | findstr product-service-fixed

Write-Host "Fix completed! Monitoring deployment logs..."
# Get the pod name and display logs
$podName = kubectl get pods -n ecommerce -l app=product-service-fixed -o jsonpath="{.items[0].metadata.name}" 2>$null
if ($podName) {
    Write-Host "Getting logs from pod $podName..."
    kubectl logs $podName -n ecommerce --tail=50
}
