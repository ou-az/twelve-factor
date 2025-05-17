# Script to fix the LoadBalancer configuration to target our working product service
Write-Host "Fixing LoadBalancer service configuration..." -ForegroundColor Cyan

# Extract the current LoadBalancer details for reference
$currentLbConfig = kubectl get service product-service-loadbalancer -n ecommerce -o yaml
Write-Host "`nCurrent LoadBalancer configuration:" -ForegroundColor Yellow
$currentLbConfig

# Patch the LoadBalancer service to point to our fixed product service
Write-Host "`nUpdating LoadBalancer to target the fixed product service..." -ForegroundColor Cyan
kubectl patch service product-service-loadbalancer -n ecommerce --type='json' -p='[{"op": "replace", "path": "/spec/selector", "value": {"app": "product-service-fixed"}}, {"op": "replace", "path": "/spec/ports/0/targetPort", "value": 8081}]'

# Verify the updated service configuration
Write-Host "`nVerifying updated LoadBalancer configuration:" -ForegroundColor Green
kubectl describe service product-service-loadbalancer -n ecommerce

# Check if the endpoints are now correctly populated
Write-Host "`nChecking if LoadBalancer endpoints are correctly configured:" -ForegroundColor Cyan
kubectl get endpoints product-service-loadbalancer -n ecommerce

# Display the external access URL
$lbUrl = kubectl get service product-service-loadbalancer -n ecommerce -o jsonpath="{.status.loadBalancer.ingress[0].hostname}"
Write-Host "`nYour API should now be accessible at: http://$lbUrl/api/products" -ForegroundColor Green
Write-Host "Please allow a minute or two for the LoadBalancer to update and test again." -ForegroundColor Yellow
