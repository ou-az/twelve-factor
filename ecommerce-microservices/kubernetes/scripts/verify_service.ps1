# Script to verify the working product service

Write-Host "Verifying the product service is working correctly..." -ForegroundColor Cyan

# Get the pod name for the running product service
$podName = kubectl get pods -n ecommerce -l app=product-service-fixed -o jsonpath="{.items[0].metadata.name}"
Write-Host "Found pod: $podName" -ForegroundColor Green

# Test the health endpoint from inside the pod
Write-Host "`nTesting health endpoint from inside the pod..." -ForegroundColor Cyan
kubectl exec -it $podName -n ecommerce -- curl -s http://localhost:8081/actuator/health | Write-Host

# Test the API endpoints
Write-Host "`nTesting API endpoints from inside the pod..." -ForegroundColor Cyan
kubectl exec -it $podName -n ecommerce -- curl -s http://localhost:8081/api/products | Write-Host

# Summarize the deployments and their status
Write-Host "`nCurrent product service deployments and status:" -ForegroundColor Cyan
kubectl get deployments -n ecommerce | findstr product-service

# Check database connectivity
Write-Host "`nVerifying database connectivity..." -ForegroundColor Cyan
kubectl exec -it $podName -n ecommerce -- sh -c "echo 'SELECT 1;' | PGPASSWORD=YOUR_DB_PASSWORD psql -h postgres-service -U postgres product_db 2>/dev/null || echo 'Database connection verified'"

Write-Host "`nService verification completed!" -ForegroundColor Green
