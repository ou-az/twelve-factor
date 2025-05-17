# Script to fix Kafka configuration issue in the product service
Write-Host "Fixing Kafka configuration for product-service-final deployment in the ecommerce namespace..."

# Get the current deployment configuration
kubectl get deployment product-service-final -n ecommerce -o yaml > $null

# Check if the deployment exists
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Could not find product-service deployment. Make sure it exists in your Kubernetes cluster."
    exit 1
}

# Add all required Kafka producer properties to the deployment
Write-Host "Adding all required Kafka producer properties..."
kubectl set env deployment/product-service-final -n ecommerce \
  SPRING_KAFKA_PRODUCER_CLIENT_ID=product-service-client \
  SPRING_KAFKA_PRODUCER_BATCH_SIZE=16384 \
  SPRING_KAFKA_PRODUCER_ACKS=all \
  SPRING_KAFKA_PRODUCER_RETRIES=3 \
  SPRING_KAFKA_PRODUCER_BUFFER_MEMORY=33554432 \
  SPRING_KAFKA_PRODUCER_COMPRESSION_TYPE=snappy

# Verify the environment variable was added
Write-Host "Verifying environment variables in the deployment:"
kubectl get deployment product-service-final -n ecommerce -o jsonpath="{.spec.template.spec.containers[0].env[*].name}"

# Restart the deployment to apply changes
Write-Host "Restarting the product-service-final deployment to apply changes..."
kubectl rollout restart deployment/product-service-final -n ecommerce

# Wait for the deployment to be ready
Write-Host "Waiting for the deployment to be ready..."
kubectl rollout status deployment/product-service-final -n ecommerce

# Check the pod status
Write-Host "Checking pod status..."
kubectl get pods -n ecommerce | findstr product-service-final

# Check the logs of the new pod to verify the application starts correctly
Write-Host "Checking logs of the new pod..."
$podName = kubectl get pods -n ecommerce | findstr product-service-final | Select-String -Pattern "product-service-final-[a-zA-Z0-9]+-[a-zA-Z0-9]+" | ForEach-Object { $_.Matches.Value } | Select-Object -First 1
if ($podName) {
    kubectl logs $podName -n ecommerce
} else {
    Write-Host "Could not find product-service pod. Please check the deployment status."
}

Write-Host "Kafka configuration fix completed."
