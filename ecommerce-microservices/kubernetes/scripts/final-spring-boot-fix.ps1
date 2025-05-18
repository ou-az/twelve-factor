# Enterprise Spring Boot Database Connectivity Fix
# Implements comprehensive fix for Spring Boot to PostgreSQL connection

Write-Host "ENTERPRISE SPRING BOOT DATABASE FIX" -ForegroundColor Cyan

# 1. Clean up existing resources for a fresh start
Write-Host "`nCleaning up existing resources..." -ForegroundColor Yellow
kubectl delete deployment product-service -n ecommerce
kubectl delete deployment product-service-test -n ecommerce
kubectl delete deployment product-service-fixed -n ecommerce
Start-Sleep -Seconds 5

# 2. Get the currently running PostgreSQL instance
Write-Host "`nIdentifying running PostgreSQL..." -ForegroundColor Yellow
$PG_POD = kubectl get pods -n ecommerce -l app=postgres --no-headers | ForEach-Object { $_.Split()[0] }
Write-Host "Using PostgreSQL pod: $PG_POD" -ForegroundColor Cyan

# 3. Check if PostgreSQL is ready to accept connections
Write-Host "`nVerifying PostgreSQL is ready..." -ForegroundColor Yellow
kubectl exec -it $PG_POD -n ecommerce -- pg_isready -h localhost

# 4. Update Spring Boot database credentials
Write-Host "`nCreating Spring Boot database credentials secret..." -ForegroundColor Yellow
$SPRING_DB_SECRET = @"
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

Set-Content -Path "spring-db-secret.yaml" -Value $SPRING_DB_SECRET
kubectl apply -f spring-db-secret.yaml

# 5. Create comprehensive Spring Boot configuration
Write-Host "`nCreating Spring Boot configuration..." -ForegroundColor Yellow
$SPRING_CONFIG_MAP = @"
apiVersion: v1
kind: ConfigMap
metadata:
  name: product-service-config
  namespace: ecommerce
data:
  # Enable bean overriding for Kafka config
  SPRING_MAIN_ALLOW-BEAN-DEFINITION-OVERRIDING: "true"
  
  # JPA Configuration
  SPRING_JPA_HIBERNATE_DDL-AUTO: "update"
  SPRING_JPA_GENERATE-DDL: "true"
  SPRING_JPA_DATABASE-PLATFORM: "org.hibernate.dialect.PostgreSQLDialect"
  SPRING_JPA_SHOW-SQL: "true"
  
  # Disable Flyway to prevent migration conflicts
  SPRING_FLYWAY_ENABLED: "false"
  
  # Hibernate pool configuration
  SPRING_JPA_PROPERTIES_HIBERNATE_CONNECTION_PROVIDER_DISABLES-AUTOCOMMIT: "true"
  
  # HikariCP specific configuration
  SPRING_DATASOURCE_HIKARI_MINIMUMIDE: "2"
  SPRING_DATASOURCE_HIKARI_MAXIMUMPOOLSIZE: "10"
  SPRING_DATASOURCE_HIKARI_IDLETIMEOUT: "30000"
  SPRING_DATASOURCE_HIKARI_POOLNAME: "SpringBootHikariCP"
  SPRING_DATASOURCE_HIKARI_MAXLIFETIME: "2000000"
  SPRING_DATASOURCE_HIKARI_CONNECTIONTIMEOUT: "30000"
  
  # Kafka Configuration
  SPRING_KAFKA_BOOTSTRAP-SERVERS: "kafka-service:9092"
  KAFKA_CREATE_TOPIC_ENABLED: "false"
"@

Set-Content -Path "spring-config.yaml" -Value $SPRING_CONFIG_MAP
kubectl apply -f spring-config.yaml

# 6. Create final product service deployment
Write-Host "`nCreating final product service deployment..." -ForegroundColor Yellow
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
            name: product-service-config
        - secretRef:
            name: product-service-db-secret
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        # Extended startup probes for database initialization
        startupProbe:
          httpGet:
            path: /actuator/health
            port: 8080
          failureThreshold: 30
          periodSeconds: 10
        livenessProbe:
          httpGet:
            path: /actuator/health
            port: 8080
          initialDelaySeconds: 180
          periodSeconds: 20
          timeoutSeconds: 5
          failureThreshold: 6
        readinessProbe:
          httpGet:
            path: /actuator/health
            port: 8080
          initialDelaySeconds: 120
          periodSeconds: 10
          timeoutSeconds: 5
"@

Set-Content -Path "product-final.yaml" -Value $PRODUCT_DEPLOYMENT
kubectl apply -f product-final.yaml

# 7. Update service to point to the final deployment
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

# 8. Wait for deployment to start
Write-Host "`nWaiting for deployment to start (this may take a moment)..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

# 9. Check pod status
Write-Host "`nChecking pod status..." -ForegroundColor Cyan
kubectl get pods -n ecommerce -l app=product-service

# 10. Show application logs
Write-Host "`nShowing application startup logs (should see HikariCP initialization)..." -ForegroundColor Yellow
kubectl logs -n ecommerce -l app=product-service

# 11. Get service URL
$LB_URL = kubectl get service product-service-loadbalancer -n ecommerce -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

Write-Host @"

===========================================================
ENTERPRISE SPRING BOOT DATABASE FIX APPLIED

This comprehensive fix includes:

1. Clean separation of concerns with ConfigMap and Secret
2. Extended startup probes for database initialization time
3. HikariCP connection pool tuning for production
4. Startup probe to handle extended initialization time

Your API should be available at:
http://${LB_URL}/api/products
===========================================================
"@ -ForegroundColor Green
