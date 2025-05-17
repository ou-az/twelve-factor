# Enterprise Kubernetes Deployment Troubleshooting Script
# Diagnoses stuck rollout issues with comprehensive logging

Write-Host "Diagnosing Kubernetes Deployment Rollout Issues..." -ForegroundColor Cyan

# 1. Get deployment details
Write-Host "`nExamining deployment configuration..." -ForegroundColor Yellow
kubectl describe deployment product-service -n ecommerce

# 2. Check for pod events and status
Write-Host "`nExamining pod events..." -ForegroundColor Yellow
$PODS = kubectl get pods -n ecommerce -l app=product-service -o jsonpath='{.items[*].metadata.name}'
foreach ($pod in $PODS.Split()) {
    Write-Host "`nPod: $pod" -ForegroundColor Cyan
    kubectl describe pod $pod -n ecommerce
}

# 3. Check for pod logs
Write-Host "`nChecking pod logs for errors..." -ForegroundColor Yellow
foreach ($pod in $PODS.Split()) {
    Write-Host "`nLogs for pod: $pod" -ForegroundColor Cyan
    kubectl logs $pod -n ecommerce
}

# 4. Check resource constraints
Write-Host "`nChecking for resource constraints..." -ForegroundColor Yellow
kubectl get pods -n ecommerce -l app=product-service -o jsonpath='{.items[*].status.conditions[?(@.type=="Ready")].message}'

# 5. Check replica set details
Write-Host "`nExamining ReplicaSets for historical deployment issues..." -ForegroundColor Yellow
kubectl get rs -n ecommerce -l app=product-service
$RS_NAME = kubectl get rs -n ecommerce -l app=product-service -o jsonpath='{.items[0].metadata.name}'
kubectl describe rs $RS_NAME -n ecommerce

# 6. Check for initialization issues
Write-Host "`nChecking for initialization issues..." -ForegroundColor Yellow
kubectl get pods -n ecommerce -l app=product-service -o jsonpath='{.items[*].status.initContainerStatuses[*].state.waiting.reason}'

# 7. Check for readiness probe failures
Write-Host "`nChecking readiness probe status..." -ForegroundColor Yellow
kubectl get pods -n ecommerce -l app=product-service -o json | ConvertFrom-Json | ForEach-Object { 
    $_.items | ForEach-Object {
        $podName = $_.metadata.name
        $containerStatuses = $_.status.containerStatuses
        
        if ($containerStatuses) {
            foreach ($status in $containerStatuses) {
                $ready = $status.ready
                Write-Host "Pod: $podName, Container: $($status.name), Ready: $ready"
                
                if (-not $ready -and $status.state.waiting) {
                    Write-Host "  Waiting Reason: $($status.state.waiting.reason)" -ForegroundColor Red
                    Write-Host "  Message: $($status.state.waiting.message)" -ForegroundColor Red
                }
            }
        }
    }
}

# 8. Emergency recovery - Restart failed deployment
Write-Host "`nPerforming emergency recovery..." -ForegroundColor Yellow
Write-Host "1. Setting deployment replicas to 1 to simplify troubleshooting" -ForegroundColor Cyan
kubectl scale deployment product-service -n ecommerce --replicas=1

Write-Host "2. Patching deployment strategy" -ForegroundColor Cyan
$PATCH_STRATEGY = @"
{
  "spec": {
    "strategy": {
      "type": "Recreate"
    }
  }
}
"@
Set-Content -Path "patch-strategy.json" -Value $PATCH_STRATEGY
kubectl patch deployment product-service -n ecommerce --patch-file patch-strategy.json

Write-Host "3. Forcing rollout" -ForegroundColor Cyan
kubectl rollout restart deployment product-service -n ecommerce

Write-Host "`nWaiting for new pod to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

# 9. Final status check
Write-Host "`nChecking final deployment status..." -ForegroundColor Green
kubectl get pods -n ecommerce -l app=product-service
kubectl rollout status deployment/product-service -n ecommerce --timeout=30s

# 10. Test service connectivity
Write-Host "`nTesting service connectivity..." -ForegroundColor Yellow
$SERVICE_IP = kubectl get service product-service-loadbalancer -n ecommerce -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
Write-Host "Service endpoint: http://$SERVICE_IP/api/products" -ForegroundColor Cyan

Write-Host @"

===========================================================
ENTERPRISE DEPLOYMENT RECOVERY COMPLETED

If the deployment is still stuck, consider:
1. Checking resource limits in the namespace
2. Validating network policies
3. Inspecting cluster events (kubectl get events -n ecommerce)
4. Reviewing application logs for startup errors
5. Checking for PostgreSQL connectivity issues

Try accessing your API at:
http://aee62280f41e04181bf13ba432fd2092-001b4178947505be.elb.us-west-2.amazonaws.com/api/products
===========================================================
"@ -ForegroundColor Green
