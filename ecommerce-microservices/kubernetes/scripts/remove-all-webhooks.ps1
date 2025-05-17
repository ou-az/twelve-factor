# PowerShell script to aggressively remove all webhook configurations

# First, remove all validating webhooks
Write-Host "Removing all validating webhooks..." -ForegroundColor Yellow
kubectl get validatingwebhookconfigurations -o name | ForEach-Object {
    Write-Host "Deleting $_..." -ForegroundColor Cyan
    kubectl delete $_ --ignore-not-found
}

# Remove all mutating webhooks
Write-Host "`nRemoving all mutating webhooks..." -ForegroundColor Yellow
kubectl get mutatingwebhookconfigurations -o name | ForEach-Object {
    Write-Host "Deleting $_..." -ForegroundColor Cyan
    kubectl delete $_ --ignore-not-found
}

# Remove all resources related to AWS Load Balancer Controller
Write-Host "`nCleaning up all AWS Load Balancer Controller resources..." -ForegroundColor Yellow
kubectl delete deployment aws-load-balancer-controller -n kube-system --ignore-not-found
kubectl delete service aws-load-balancer-webhook-service -n kube-system --ignore-not-found

# Remove cert-manager resources if they exist
Write-Host "`nRemoving cert-manager certificates if they exist..." -ForegroundColor Yellow
kubectl delete certificate aws-load-balancer-serving-cert -n kube-system --ignore-not-found
kubectl delete issuer aws-load-balancer-selfsigned-issuer -n kube-system --ignore-not-found

Write-Host "`nWebhook cleanup complete!" -ForegroundColor Green
Write-Host "Now try applying your services again:" -ForegroundColor Cyan
Write-Host "kubectl apply -f direct-service-exposure.yaml" -ForegroundColor White
