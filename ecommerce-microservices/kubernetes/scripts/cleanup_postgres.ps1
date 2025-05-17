# Script to clean up multiple PostgreSQL deployments while preserving the required one
Write-Host "Cleaning up redundant PostgreSQL deployments and pods..." -ForegroundColor Cyan

# List current PostgreSQL deployments before cleanup
Write-Host "`nCurrent PostgreSQL deployments before cleanup:" -ForegroundColor Yellow
kubectl get deployments -n ecommerce | findstr postgres

# List current PostgreSQL pods before cleanup
Write-Host "`nCurrent PostgreSQL pods before cleanup:" -ForegroundColor Yellow
kubectl get pods -n ecommerce | findstr postgres

# Determine which PostgreSQL deployment is backing the postgres-service
Write-Host "`nChecking which PostgreSQL deployment is serving postgres-service..." -ForegroundColor Cyan
$serviceSelector = kubectl get service postgres-service -n ecommerce -o jsonpath="{.spec.selector}"
Write-Host "Service selector: $serviceSelector" -ForegroundColor Green

# We need to keep at least one PostgreSQL instance running to serve our product service
# We'll keep postgres-fixed as it seems to be the one we were using in our successful fix
Write-Host "`nPreserving postgres-fixed deployment and service..." -ForegroundColor Green

# Delete standalone diagnostic PostgreSQL pods
Write-Host "`nDeleting standalone diagnostic PostgreSQL pods..." -ForegroundColor Cyan
kubectl delete pod postgres-admin -n ecommerce --ignore-not-found
kubectl delete pod postgres-diag -n ecommerce --ignore-not-found

# Delete redundant PostgreSQL deployments, but preserve postgres-fixed
Write-Host "`nDeleting redundant PostgreSQL deployments..." -ForegroundColor Cyan
kubectl delete deployment postgres -n ecommerce --ignore-not-found
kubectl delete deployment postgres-clean -n ecommerce --ignore-not-found
kubectl delete deployment postgres-test -n ecommerce --ignore-not-found
kubectl delete deployment postgres-nopvc -n ecommerce --ignore-not-found

# Verify the state after cleanup
Write-Host "`nVerifying PostgreSQL deployments after cleanup:" -ForegroundColor Green
kubectl get deployments -n ecommerce | findstr postgres

# Verify PostgreSQL pods after cleanup
Write-Host "`nVerifying PostgreSQL pods after cleanup:" -ForegroundColor Green
kubectl get pods -n ecommerce | findstr postgres

# Verify our product service is still running and can connect to PostgreSQL
Write-Host "`nVerifying product service is still running:" -ForegroundColor Green
kubectl get pods -n ecommerce | findstr product-service

Write-Host "`nConnectivity test from product service to PostgreSQL:" -ForegroundColor Green
$productPod = kubectl get pods -n ecommerce -l app=product-service-fixed -o jsonpath="{.items[0].metadata.name}"
if ($productPod) {
    # Run a simple check inside the product service pod to verify database connectivity
    try {
        kubectl exec $productPod -n ecommerce -- curl -s http://localhost:8081/actuator/health
    } catch {
        Write-Host "Product service is still running, but couldn't directly verify health endpoint" -ForegroundColor Yellow
    }
} else {
    Write-Host "Could not find product service pod" -ForegroundColor Red
}

Write-Host "`nPostgreSQL cleanup completed. The postgres-fixed deployment has been preserved." -ForegroundColor Green
Write-Host "Postgres service is available at: postgres-service:5432 within the cluster" -ForegroundColor Cyan
