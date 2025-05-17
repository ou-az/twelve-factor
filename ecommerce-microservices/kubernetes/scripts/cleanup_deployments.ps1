# Script to clean up unused product service deployments
Write-Host "Cleaning up unused/failing product service deployments..." -ForegroundColor Cyan

# List all current deployments before cleanup
Write-Host "`nCurrent deployments before cleanup:" -ForegroundColor Yellow
kubectl get deployments -n ecommerce | findstr product-service

# Delete the failing product-service-final deployment
Write-Host "`nDeleting failing product-service-final deployment..." -ForegroundColor Cyan
kubectl delete deployment product-service-final -n ecommerce

# Verify the working deployment remains
Write-Host "`nVerifying working deployment remains intact:" -ForegroundColor Green
kubectl get deployments -n ecommerce | findstr product-service

# Check all pods after cleanup
Write-Host "`nPods after cleanup:" -ForegroundColor Green
kubectl get pods -n ecommerce | findstr product-service

Write-Host "`nCleanup completed. The working product-service-fixed deployment has been preserved." -ForegroundColor Green
Write-Host "You can access the service via: product-service-fixed:8081 within the cluster" -ForegroundColor Cyan
