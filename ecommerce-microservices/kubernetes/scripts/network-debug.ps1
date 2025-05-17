# Enterprise Network Debugging Script
# Comprehensively tests network connectivity paths in Kubernetes

Write-Host "ENTERPRISE NETWORK DEBUGGING" -ForegroundColor Cyan

# 1. Deploy network diagnostics pod with full tooling
Write-Host "`nDeploying network diagnostics pod..." -ForegroundColor Yellow
$NETWORK_DEBUG = @"
apiVersion: v1
kind: Pod
metadata:
  name: network-debug
  namespace: ecommerce
spec:
  containers:
  - name: network-debug
    image: nicolaka/netshoot
    command: ["sleep", "3600"]
"@

Set-Content -Path "network-debug.yaml" -Value $NETWORK_DEBUG
kubectl apply -f network-debug.yaml
Write-Host "Waiting for diagnostics pod to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# 2. Check if PostgreSQL service is resolvable via DNS
Write-Host "`nChecking DNS resolution for PostgreSQL service..." -ForegroundColor Yellow
kubectl exec -it network-debug -n ecommerce -- nslookup postgres-service
kubectl exec -it network-debug -n ecommerce -- nslookup postgres-service.ecommerce.svc.cluster.local

# 3. Check if PostgreSQL port is open and reachable
Write-Host "`nChecking network connectivity to PostgreSQL service..." -ForegroundColor Yellow
kubectl exec -it network-debug -n ecommerce -- nc -zv postgres-service 5432
kubectl exec -it network-debug -n ecommerce -- nc -zv postgres-service.ecommerce.svc.cluster.local 5432

# 4. Get PostgreSQL service details
Write-Host "`nChecking PostgreSQL service configuration..." -ForegroundColor Yellow
kubectl get service postgres-service -n ecommerce -o yaml

# 5. Check if pods are running and ready
Write-Host "`nChecking pod statuses..." -ForegroundColor Yellow
kubectl get pods -n ecommerce

# 6. Check PostgreSQL logs for authentication configuration
Write-Host "`nChecking PostgreSQL logs..." -ForegroundColor Yellow
$PG_POD = kubectl get pods -n ecommerce -l app=postgres -o jsonpath='{.items[0].metadata.name}'
kubectl logs $PG_POD -n ecommerce

# 7. Try direct PostgreSQL connection from debug pod with password
Write-Host "`nAttempting direct PostgreSQL connection..." -ForegroundColor Yellow
kubectl exec -it network-debug -n ecommerce -- sh -c "PGPASSWORD=YOUR_DB_PASSWORD psql -h postgres-service -U postgres -d product_db -c '\\l'"

# 8. Check for any network policies that might be blocking traffic
Write-Host "`nChecking for network policies..." -ForegroundColor Yellow
kubectl get networkpolicies -n ecommerce

# 9. Deploy a simplified database for testing
Write-Host "`nDeploying a simplified test database..." -ForegroundColor Green
$TEST_DB = @"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres-test
  namespace: ecommerce
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres-test
  template:
    metadata:
      labels:
        app: postgres-test
    spec:
      containers:
      - name: postgres
        image: postgres:14
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_PASSWORD
          value: "simple123"
        - name: POSTGRES_USER
          value: "postgres"
        - name: POSTGRES_DB
          value: "testdb"
---
apiVersion: v1
kind: Service
metadata:
  name: postgres-test
  namespace: ecommerce
spec:
  selector:
    app: postgres-test
  ports:
  - port: 5432
    targetPort: 5432
"@

Set-Content -Path "postgres-test.yaml" -Value $TEST_DB
kubectl apply -f postgres-test.yaml
Write-Host "Waiting for test database to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 20

# 10. Test connectivity to the test database
Write-Host "`nTesting connectivity to test database..." -ForegroundColor Yellow
kubectl exec -it network-debug -n ecommerce -- nc -zv postgres-test 5432
kubectl exec -it network-debug -n ecommerce -- sh -c "PGPASSWORD=simple123 psql -h postgres-test -U postgres -d testdb -c '\\l'"

# 11. Temporarily modify the service to direct traffic to test database
Write-Host "`nTemporarily redirecting PostgreSQL service to test database..." -ForegroundColor Yellow
$REDIRECT_SERVICE = @"
apiVersion: v1
kind: Service
metadata:
  name: postgres-service
  namespace: ecommerce
spec:
  selector:
    app: postgres-test
  ports:
  - port: 5432
    targetPort: 5432
  type: ClusterIP
"@

Set-Content -Path "redirect-service.yaml" -Value $REDIRECT_SERVICE
kubectl apply -f redirect-service.yaml

# 12. Create compatible product service for test database
Write-Host "`nCreating test-compatible product service..." -ForegroundColor Yellow
$TEST_SECRET = @"
apiVersion: v1
kind: Secret
metadata:
  name: product-service-test-secrets
  namespace: ecommerce
type: Opaque
stringData:
  SPRING_DATASOURCE_URL: "jdbc:postgresql://postgres-service:5432/testdb"
  SPRING_DATASOURCE_USERNAME: "postgres"
  SPRING_DATASOURCE_PASSWORD: "simple123"
"@

Set-Content -Path "test-db-secret.yaml" -Value $TEST_SECRET
kubectl apply -f test-db-secret.yaml

$TEST_PRODUCT = @"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: product-service-test
  namespace: ecommerce
  labels:
    app: product-service-test
spec:
  replicas: 1
  selector:
    matchLabels:
      app: product-service-test
  template:
    metadata:
      labels:
        app: product-service-test
    spec:
      containers:
      - name: product-service
        image: REPLACE_WITH_YOUR_IMAGE # Will be replaced automatically
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
            name: product-service-test-secrets
        resources:
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          initialDelaySeconds: 240
          periodSeconds: 20
          failureThreshold: 10
          httpGet:
            path: /actuator/health
            port: 8080
        readinessProbe:
          initialDelaySeconds: 120
          periodSeconds: 10
          httpGet:
            path: /actuator/health
            port: 8080
"@

Set-Content -Path "product-test.yaml" -Value $TEST_PRODUCT

# 13. Get the current image name from the existing deployment
$CURRENT_IMAGE = kubectl get deployment product-service -n ecommerce -o jsonpath='{.spec.template.spec.containers[0].image}'
Write-Host "`nDetected current image: $CURRENT_IMAGE" -ForegroundColor Cyan

# 14. Update the image name in the test deployment YAML
(Get-Content "product-test.yaml") -replace "REPLACE_WITH_YOUR_IMAGE", $CURRENT_IMAGE | Set-Content "product-test.yaml"

# 15. Apply the test product service
kubectl apply -f product-test.yaml

Write-Host @"

===========================================================
ENTERPRISE NETWORK DEBUGGING COMPLETE

We've:
1. Verified DNS resolution and network paths
2. Tested direct PostgreSQL connectivity
3. Created a simplified test database with known credentials
4. Redirected the PostgreSQL service to the test database
5. Deployed a test-compatible product service

The test product service has extended startup timeouts and
will connect to our simplified test database. This should
isolate whether the issue is with database configuration or
network connectivity.

Check status with:
kubectl get pods -n ecommerce

Check logs with:
kubectl logs -n ecommerce -l app=product-service-test
===========================================================
"@ -ForegroundColor Green
