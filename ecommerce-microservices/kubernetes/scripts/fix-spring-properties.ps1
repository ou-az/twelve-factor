# Enterprise Spring Boot Property Resolution Fix
# Resolves placeholder resolution issues in Spring configuration

Write-Host "ENTERPRISE SPRING CONFIGURATION FIX" -ForegroundColor Cyan

# 1. Check the current application environment variables
Write-Host "`nChecking current environment variables..." -ForegroundColor Yellow
$POD_NAME = kubectl get pods -n ecommerce -l app=product-service -o jsonpath='{.items[0].metadata.name}'
Write-Host "Target pod: $POD_NAME" -ForegroundColor Cyan
kubectl describe pod $POD_NAME -n ecommerce | Select-String -Pattern "Environment:"

# 2. Create a comprehensive Spring Boot configuration
Write-Host "`nCreating comprehensive Spring Boot configuration..." -ForegroundColor Yellow
$SPRING_COMPLETE_CONFIG = @"
apiVersion: v1
kind: ConfigMap
metadata:
  name: product-service-complete-config
  namespace: ecommerce
data:
  # Spring core settings
  SPRING_MAIN_ALLOW-BEAN-DEFINITION-OVERRIDING: "true"
  SPRING_MAIN_ALLOW-CIRCULAR-REFERENCES: "true"
  
  # JPA Configuration
  SPRING_JPA_HIBERNATE_DDL-AUTO: "update"
  SPRING_JPA_GENERATE-DDL: "true"
  SPRING_JPA_DATABASE-PLATFORM: "org.hibernate.dialect.PostgreSQLDialect"
  SPRING_JPA_SHOW-SQL: "true"
  
  # Disable Flyway
  SPRING_FLYWAY_ENABLED: "false"
  
  # Datasource configuration
  SPRING_DATASOURCE_DRIVER-CLASS-NAME: "org.postgresql.Driver"
  SPRING_DATASOURCE_TYPE: "com.zaxxer.hikari.HikariDataSource"
  
  # HikariCP configuration
  SPRING_DATASOURCE_HIKARI_MINIMUM-IDLE: "2"
  SPRING_DATASOURCE_HIKARI_MAXIMUM-POOL-SIZE: "10"
  SPRING_DATASOURCE_HIKARI_IDLE-TIMEOUT: "30000"
  SPRING_DATASOURCE_HIKARI_POOL-NAME: "SpringBootHikariCP"
  SPRING_DATASOURCE_HIKARI_MAX-LIFETIME: "2000000"
  SPRING_DATASOURCE_HIKARI_CONNECTION-TIMEOUT: "30000"
  
  # Kafka configuration
  SPRING_KAFKA_BOOTSTRAP-SERVERS: "kafka-service:9092"
  SPRING_KAFKA_CONSUMER_AUTO-OFFSET-RESET: "earliest"
  SPRING_KAFKA_CONSUMER_GROUP-ID: "product-service-group"
  SPRING_KAFKA_CONSUMER_KEY-DESERIALIZER: "org.apache.kafka.common.serialization.StringDeserializer"
  SPRING_KAFKA_CONSUMER_VALUE-DESERIALIZER: "org.apache.kafka.common.serialization.StringDeserializer"
  SPRING_KAFKA_PRODUCER_KEY-SERIALIZER: "org.apache.kafka.common.serialization.StringSerializer"
  SPRING_KAFKA_PRODUCER_VALUE-SERIALIZER: "org.apache.kafka.common.serialization.StringSerializer"

  # Explicit Kafka topic configuration
  KAFKA_TOPIC_PRODUCT_CREATED: "product-created"
  KAFKA_TOPIC_PRODUCT_UPDATED: "product-updated"
  KAFKA_TOPIC_PRODUCT_DELETED: "product-deleted"
  
  # Actuator configuration
  MANAGEMENT_ENDPOINTS_WEB_EXPOSURE_INCLUDE: "health,info,metrics"
  MANAGEMENT_ENDPOINT_HEALTH_SHOW-DETAILS: "always"
"@

Set-Content -Path "spring-complete-config.yaml" -Value $SPRING_COMPLETE_CONFIG
kubectl apply -f spring-complete-config.yaml

# 3. Update the database credentials
Write-Host "`nUpdating database credentials..." -ForegroundColor Yellow
$DB_SECRET = @"
apiVersion: v1
kind: Secret
metadata:
  name: product-service-db-secret
  namespace: ecommerce
type: Opaque
stringData:
  SPRING_DATASOURCE_URL: "jdbc:postgresql://postgres-service:5432/product_db"
  SPRING_DATASOURCE_USERNAME: "postgres"
  SPRING_DATASOURCE_PASSWORD: "YOUR_DB_PASSWORD"
"@

Set-Content -Path "db-secret.yaml" -Value $DB_SECRET
kubectl apply -f db-secret.yaml

# 4. Create final product service deployment with explicit property resolution
Write-Host "`nCreating final deployment with explicit property configuration..." -ForegroundColor Yellow
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
        image: YOUR_AWS_ACCOUNT_ID.dkr.ecr.us-west-2.amazonaws.com/ecommerce-product-service:latest
        ports:
        - containerPort: 8080
        envFrom:
        - configMapRef:
            name: product-service-complete-config
        - secretRef:
            name: product-service-db-secret
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        # Extended startup probes for application initialization
        startupProbe:
          httpGet:
            path: /actuator/health
            port: 8080
          failureThreshold: 30
          periodSeconds: 10
"@

Set-Content -Path "product-final-fixed.yaml" -Value $PRODUCT_DEPLOYMENT
kubectl apply -f product-final-fixed.yaml

# 5. Update service
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

Set-Content -Path "product-service.yaml" -Value $SERVICE_YAML
kubectl apply -f product-service.yaml

# 6. Wait for deployment
Write-Host "`nWaiting for deployment to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 20

# 7. Check pod status and logs
Write-Host "`nChecking pod status..." -ForegroundColor Cyan
kubectl get pods -n ecommerce -l app=product-service
Write-Host "`nChecking application logs..." -ForegroundColor Yellow
kubectl logs -n ecommerce -l app=product-service

# 8. Get service URL
$LB_URL = kubectl get service product-service-loadbalancer -n ecommerce -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

Write-Host @"

===========================================================
ENTERPRISE SPRING CONFIGURATION FIX APPLIED

This comprehensive fix addresses Spring property resolution by:

1. Providing explicit property values for all required configurations
2. Using proper naming conventions for Spring Boot properties
3. Separating concerns between ConfigMap and Secret resources
4. Adding explicit Kafka topic configuration to prevent property resolution issues

Your API should be available at:
http://${LB_URL}/api/products
===========================================================
"@ -ForegroundColor Green
