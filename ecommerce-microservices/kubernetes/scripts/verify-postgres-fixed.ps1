# Enterprise PostgreSQL Verification Script - Fixed
# Directly validates database connectivity and authentication

Write-Host "ENTERPRISE POSTGRESQL CONNECTIVITY VERIFICATION" -ForegroundColor Cyan

# 1. Deploy direct testing pod
Write-Host "`nDeploying PostgreSQL client for direct testing..." -ForegroundColor Yellow
$PG_TEST = @"
apiVersion: v1
kind: Pod
metadata:
  name: pg-test
  namespace: ecommerce
spec:
  containers:
  - name: postgres
    image: postgres:14
    command: ["sleep", "3600"]
    env:
    - name: PGPASSWORD
      value: "YOUR_DB_PASSWORD"
"@

Set-Content -Path "pg-test.yaml" -Value $PG_TEST
kubectl apply -f pg-test.yaml
Write-Host "Waiting for test pod to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# 2. Check PostgreSQL service DNS
Write-Host "`nVerifying PostgreSQL service DNS resolution..." -ForegroundColor Yellow
kubectl exec -it pg-test -n ecommerce -- nslookup postgres-service
kubectl exec -it pg-test -n ecommerce -- nslookup postgres-service.ecommerce.svc.cluster.local

# 3. Get PostgreSQL service endpoint details
Write-Host "`nVerifying PostgreSQL service endpoint..." -ForegroundColor Yellow
$PG_SVC = kubectl get service postgres-service -n ecommerce -o json | ConvertFrom-Json
$PG_CLUSTER_IP = $PG_SVC.spec.clusterIP
$PG_PORT = $PG_SVC.spec.ports[0].port
Write-Host "PostgreSQL Service: ${PG_CLUSTER_IP}:${PG_PORT}" -ForegroundColor Cyan

# 4. Test connection to PostgreSQL
Write-Host "`nTesting direct connection to PostgreSQL..." -ForegroundColor Yellow
kubectl exec -it pg-test -n ecommerce -- psql -h postgres-service -U postgres -c "\conninfo"
kubectl exec -it pg-test -n ecommerce -- psql -h postgres-service -U postgres -c "\l"

# 5. Check PostgreSQL pod logs for authentication attempts
Write-Host "`nChecking PostgreSQL logs for authentication issues..." -ForegroundColor Yellow
$PG_PODS = kubectl get pods -n ecommerce -l app=postgres --no-headers | ForEach-Object { $_.Split()[0] }
if ($PG_PODS) {
    $PG_POD = $PG_PODS[0]
    kubectl logs $PG_POD -n ecommerce | Select-String -Pattern "authentication|FATAL|ERROR"
}

# 6. Create the full JDBC URL for testing
$JDBC_URL = "jdbc:postgresql://${PG_CLUSTER_IP}:${PG_PORT}/product_db"
Write-Host "`nFull JDBC URL for testing: $JDBC_URL" -ForegroundColor Cyan

# 7. Check the product service logs one more time
Write-Host "`nChecking for database details in application logs..." -ForegroundColor Yellow
kubectl logs -n ecommerce -l app=product-service

Write-Host @"

===========================================================
ENTERPRISE DATABASE VERIFICATION COMPLETE

Use these findings to update your application configuration.
If direct PostgreSQL connection works but the application
cannot connect, the issue may be with:

1. JDBC URL format in Spring configuration
2. Database name mismatch
3. Authentication credentials in Spring boot app
4. Database schema initialization issues

For production readiness, consider:
- Implementing database backups
- Setting up monitoring for PostgreSQL
- Adding connection pool metrics to your dashboard
===========================================================
"@ -ForegroundColor Green
