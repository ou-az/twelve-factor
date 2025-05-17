# Script to clean up the product-service-minimal deployment
Write-Host "Cleaning up product-service-minimal deployment..." -ForegroundColor Cyan

# List current deployments before cleanup
Write-Host "`nCurrent deployments before cleanup:" -ForegroundColor Yellow
kubectl get deployments -n ecommerce | findstr product-service

# Verify the fixed deployment is healthy before proceeding
$fixedDeploymentStatus = kubectl get deployment product-service-fixed -n ecommerce -o jsonpath="{.status.readyReplicas}"
if ($fixedDeploymentStatus -ne "1") {
    Write-Host "Warning: product-service-fixed deployment is not fully ready. Cleanup aborted." -ForegroundColor Red
    exit 1
}
Write-Host "`nVerified product-service-fixed is healthy. Proceeding with cleanup..." -ForegroundColor Green

# Delete the product-service-minimal deployment
Write-Host "`nDeleting product-service-minimal deployment..." -ForegroundColor Cyan
kubectl delete deployment product-service-minimal -n ecommerce
kubectl delete service product-service-minimal -n ecommerce --ignore-not-found

# Verify the fixed deployment remains
Write-Host "`nVerifying only the fixed deployment remains:" -ForegroundColor Green
kubectl get deployments -n ecommerce | findstr product-service

# Check all pods after cleanup
Write-Host "`nPods after cleanup:" -ForegroundColor Green
kubectl get pods -n ecommerce | findstr product-service

Write-Host "`nCleanup completed. Only the product-service-fixed deployment remains." -ForegroundColor Green
Write-Host "You can access the service via: product-service-fixed:8081 within the cluster" -ForegroundColor Cyan
