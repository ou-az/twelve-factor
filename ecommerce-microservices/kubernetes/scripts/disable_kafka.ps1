# Script to disable Kafka or set a proper profile for the product service
Write-Host "Fixing Kafka configuration issues by setting proper profile..."

# Check if the deployment exists
kubectl get deployment product-service-final -n ecommerce -o yaml > $null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Could not find product-service-final deployment. Make sure it exists in your Kubernetes cluster."
    exit 1
}

# APPROACH 1: Set the application to use the "dev" profile to disable KafkaProducerConfig
Write-Host "Setting application to use 'dev' profile to disable Kafka configuration..."
kubectl set env deployment/product-service-final -n ecommerce SPRING_PROFILES_ACTIVE=dev

# APPROACH 2: Alternatively, disable Kafka directly
Write-Host "Also disabling Kafka explicitly..."
kubectl set env deployment/product-service-final -n ecommerce SPRING_KAFKA_ENABLED=false

# Restart the deployment to apply changes
Write-Host "Restarting the deployment to apply changes..."
kubectl rollout restart deployment/product-service-final -n ecommerce

# Wait for the deployment to be ready
Write-Host "Waiting for the deployment to be ready..."
kubectl rollout status deployment/product-service-final -n ecommerce

# Check the pod status
Write-Host "Checking pod status..."
kubectl get pods -n ecommerce | findstr product-service-final

# Check the logs of the new pod
Write-Host "Checking logs of the new pod..."
$podName = kubectl get pods -n ecommerce | findstr product-service-final | Select-String -Pattern "product-service-final-[a-zA-Z0-9]+-[a-zA-Z0-9]+" | ForEach-Object { $_.Matches.Value } | Select-Object -First 1
if ($podName) {
    Write-Host "Getting logs from pod $podName..."
    kubectl logs $podName -n ecommerce --tail=50
} else {
    Write-Host "Could not find product-service pod. Please check the deployment status."
}

Write-Host "Configuration update completed."
