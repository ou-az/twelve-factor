# Test, check, and monitor script for the Kubernetes deployment

# 1. Check pod details for product service
Write-Host "`n========== CHECKING PRODUCT SERVICE PODS DETAILS ==========`n" -ForegroundColor Cyan
kubectl describe pods -l app=product-service-final -n ecommerce

# 2. Check recent logs for the product service
Write-Host "`n========== CHECKING PRODUCT SERVICE LOGS ==========`n" -ForegroundColor Cyan
$productPod = kubectl get pods -n ecommerce -l app=product-service-final -o jsonpath="{.items[0].metadata.name}"
if ($productPod) {
    kubectl logs $productPod -n ecommerce --tail=50
} else {
    Write-Host "No product service pod found"
}

# 3. Check Kubernetes events for any issues
Write-Host "`n========== CHECKING KUBERNETES EVENTS ==========`n" -ForegroundColor Cyan
kubectl get events -n ecommerce --sort-by='.lastTimestamp' | Select-Object -Last 20

# 4. Check services to ensure they are properly exposed
Write-Host "`n========== CHECKING SERVICES ==========`n" -ForegroundColor Cyan
kubectl get services -n ecommerce

# 5. Setup port forwarding to access the product service (if it's running)
Write-Host "`n========== SETTING UP PORT FORWARDING ==========`n" -ForegroundColor Cyan
if ($productPod) {
    # Setup port forwarding in the background
    Start-Process powershell -ArgumentList "-Command","kubectl port-forward $productPod 8081:8081 -n ecommerce"
    Write-Host "Port forwarding set up. You can access the service at http://localhost:8081"
}

# 6. Test API endpoints (if the service is running)
Write-Host "`n========== TESTING API ENDPOINTS ==========`n" -ForegroundColor Cyan
Write-Host "Waiting 5 seconds for port forwarding to establish..."
Start-Sleep -Seconds 5

# Try to access the API endpoints
try {
    Write-Host "Testing health endpoint..."
    Invoke-RestMethod -Uri "http://localhost:8081/actuator/health" -Method Get -TimeoutSec 5
    
    Write-Host "`nTesting API endpoints..."
    Write-Host "Products endpoint (this might return an empty array if no data):"
    Invoke-RestMethod -Uri "http://localhost:8081/api/products" -Method Get -TimeoutSec 5
} catch {
    Write-Host "Error accessing API: $_" -ForegroundColor Red
    Write-Host "The service might not be fully ready yet. Try again in a few moments." -ForegroundColor Yellow
}

# 7. Resource usage monitoring
Write-Host "`n========== MONITORING RESOURCE USAGE ==========`n" -ForegroundColor Cyan
kubectl top pods -n ecommerce

# 8. Check configuration maps and secrets (without revealing secret values)
Write-Host "`n========== CHECKING CONFIGMAPS AND SECRETS ==========`n" -ForegroundColor Cyan
Write-Host "ConfigMaps:"
kubectl get configmaps -n ecommerce
Write-Host "`nSecrets (names only for security):"
kubectl get secrets -n ecommerce

# 9. Provide options for continuous monitoring
Write-Host "`n========== CONTINUOUS MONITORING OPTIONS ==========`n" -ForegroundColor Cyan
Write-Host "To continuously monitor pods status, run:" -ForegroundColor Green
Write-Host "kubectl get pods -n ecommerce -w" -ForegroundColor Yellow
Write-Host "`nTo continuously monitor logs from the product service, run:" -ForegroundColor Green
if ($productPod) {
    Write-Host "kubectl logs $productPod -n ecommerce -f" -ForegroundColor Yellow
}

Write-Host "`n========== TESTING AND MONITORING COMPLETE ==========`n" -ForegroundColor Cyan
Write-Host "Use these commands to further troubleshoot if needed." -ForegroundColor Green
