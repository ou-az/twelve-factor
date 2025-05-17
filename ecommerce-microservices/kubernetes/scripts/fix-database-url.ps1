# Enterprise Spring Boot Database Configuration Fix
# Ensures JDBC URL is properly configured for PostgreSQL connectivity

Write-Host "Fixing Spring Boot Database Configuration..." -ForegroundColor Cyan

# 1. Check current database secret configuration
Write-Host "`nChecking current database secret..." -ForegroundColor Yellow
kubectl get secret product-service-secrets -n ecommerce -o json | ConvertFrom-Json | ForEach-Object {
    $_ | Add-Member -NotePropertyName "decodedData" -NotePropertyValue @{} -Force
    foreach ($key in $_.data.PSObject.Properties.Name) {
        $decodedValue = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_.data.$key))
        $_.decodedData[$key] = $decodedValue
        Write-Host "$key = $decodedValue" -ForegroundColor Gray
    }
}

# 2. Create a new secret with proper JDBC URL format
Write-Host "`nCreating updated database secret with proper JDBC URL..." -ForegroundColor Yellow
$POSTGRES_SERVICE_HOST = "postgres-service"
$POSTGRES_PORT = "5432"
$POSTGRES_DB = "product_db"
$POSTGRES_USER = "postgres"
$POSTGRES_PASSWORD = "postgres"  # In production, retrieve this from a secure vault

# Create temporary file with credentials for kubectl create secret
$CREDENTIALS_FILE = "db-credentials.txt"
"SPRING_DATASOURCE_URL=jdbc:postgresql://${POSTGRES_SERVICE_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}" | Out-File -FilePath $CREDENTIALS_FILE -Encoding utf8 -Append
"SPRING_DATASOURCE_USERNAME=${POSTGRES_USER}" | Out-File -FilePath $CREDENTIALS_FILE -Encoding utf8 -Append 
"SPRING_DATASOURCE_PASSWORD=${POSTGRES_PASSWORD}" | Out-File -FilePath $CREDENTIALS_FILE -Encoding utf8 -Append

# Delete existing secret and create new one
kubectl delete secret product-service-secrets -n ecommerce
kubectl create secret generic product-service-secrets -n ecommerce --from-env-file=$CREDENTIALS_FILE
Remove-Item $CREDENTIALS_FILE

# 3. Update application configuration with additional database settings
Write-Host "`nUpdating Spring Boot configuration with database settings..." -ForegroundColor Yellow
$SPRING_CONFIG = @"
apiVersion: v1
kind: ConfigMap
metadata:
  name: product-service-spring-config
  namespace: ecommerce
data:
  SPRING_MAIN_ALLOW-BEAN-DEFINITION-OVERRIDING: "true"
  SPRING_JPA_HIBERNATE_DDL-AUTO: "update"
  SPRING_JPA_GENERATE-DDL: "true"
  SPRING_JPA_DATABASE-PLATFORM: "org.hibernate.dialect.PostgreSQLDialect"
  SPRING_JPA_PROPERTIES_HIBERNATE_JDBC_LOB_NON-CONTEXTUAL-CREATION: "true"
  SPRING_JPA_PROPERTIES_HIBERNATE_FORMAT_SQL: "true"
  SPRING_JPA_SHOW-SQL: "true"
  SPRING_FLYWAY_ENABLED: "false"
"@

Set-Content -Path "spring-config.yaml" -Value $SPRING_CONFIG
kubectl apply -f spring-config.yaml

# 4. Ensure the Pod has access to both ConfigMap and Secret
Write-Host "`nPatching deployment to use both ConfigMap and Secret..." -ForegroundColor Yellow
$PATCH_ENV_JSON = @"
{
  "spec": {
    "template": {
      "spec": {
        "containers": [
          {
            "name": "product-service",
            "envFrom": [
              {
                "configMapRef": {
                  "name": "product-service-spring-config"
                }
              },
              {
                "secretRef": {
                  "name": "product-service-secrets"
                }
              }
            ]
          }
        ]
      }
    }
  }
}
"@

Set-Content -Path "deployment-env-patch.json" -Value $PATCH_ENV_JSON
kubectl patch deployment product-service -n ecommerce --patch-file deployment-env-patch.json

# 5. Force a clean restart
Write-Host "`nRestarting the deployment..." -ForegroundColor Yellow
kubectl rollout restart deployment product-service -n ecommerce

# 6. Wait for deployment to stabilize
Write-Host "`nWaiting for deployment to stabilize..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

# 7. Check pod status
Write-Host "`nVerifying pod status..." -ForegroundColor Cyan
kubectl get pods -n ecommerce -l app=product-service

# 8. Check logs for confirmation
Write-Host "`nChecking logs for database connectivity..." -ForegroundColor Yellow
Start-Sleep -Seconds 5
$POD_NAME = kubectl get pods -n ecommerce -l app=product-service -o jsonpath='{.items[0].metadata.name}'
kubectl logs $POD_NAME -n ecommerce

Write-Host @"

===========================================================
ENTERPRISE DATABASE CONFIGURATION UPDATED

The Spring Boot application should now connect properly to PostgreSQL.
The JDBC URL has been formatted correctly and Flyway has been disabled
to prevent migration conflicts with Hibernate auto-DDL.

Try accessing your API at:
http://aee62280f41e04181bf13ba432fd2092-001b4178947505be.elb.us-west-2.amazonaws.com/api/products
===========================================================
"@ -ForegroundColor Green
