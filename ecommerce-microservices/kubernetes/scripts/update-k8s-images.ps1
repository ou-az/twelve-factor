# PowerShell script to update Kubernetes deployment files with ECR repository URLs

# Change to the Terraform directory to get outputs
cd <SOURCE_DIR>\twelve-factor\ecommerce-microservices\terraform\environments\prod

# Get ECR repository URLs
$PRODUCT_ECR = terraform output -raw product_service_ecr_repository_url
$KAFKA_ECR = terraform output -raw kafka_ecr_repository_url
$ZOOKEEPER_ECR = terraform output -raw zookeeper_ecr_repository_url
$KAFKA_UI_ECR = terraform output -raw kafka_ui_ecr_repository_url
$POSTGRES_ECR = terraform output -raw postgres_ecr_repository_url

Write-Host "ECR URLs retrieved:"
Write-Host "Product Service: $PRODUCT_ECR"
Write-Host "Kafka: $KAFKA_ECR"
Write-Host "Zookeeper: $ZOOKEEPER_ECR"
Write-Host "Kafka UI: $KAFKA_UI_ECR"
Write-Host "PostgreSQL: $POSTGRES_ECR"

# Change to the Kubernetes directory
cd <SOURCE_DIR>\twelve-factor\ecommerce-microservices\kubernetes

# Update the deployment files with the correct image URLs
$files = @{
    "zookeeper.yaml" = @{
        searchString = "image: "
        replaceString = "image: $ZOOKEEPER_ECR`:latest"
    }
    "kafka.yaml" = @{
        searchString = "image: "
        replaceString = "image: $KAFKA_ECR`:latest"
    }
    "kafka-ui.yaml" = @{
        searchString = "image: "
        replaceString = "image: $KAFKA_UI_ECR`:latest"
    }
    "product-service.yaml" = @{
        searchString = "image: "
        replaceString = "image: $PRODUCT_ECR`:latest"
    }
    "postgres.yaml" = @{
        searchString = "image: "
        replaceString = "image: $POSTGRES_ECR`:latest"
    }
}

foreach ($file in $files.Keys) {
    if (Test-Path $file) {
        Write-Host "Updating $file..."
        $content = Get-Content $file
        $updated = $content -replace $files[$file].searchString, $files[$file].replaceString
        Set-Content -Path $file -Value $updated
        Write-Host "Updated $file successfully"
    } else {
        Write-Host "File $file not found" -ForegroundColor Yellow
    }
}

Write-Host "All deployment files updated with ECR repository URLs!" -ForegroundColor Green
Write-Host "You can now apply the Kubernetes manifests with: kubectl apply -f <file.yaml>"
