# Strategic Kubernetes deployment patch for enterprise environments
# This script applies Hibernate configuration to an existing deployment without modifying immutable fields

Write-Host "Applying Enterprise-Grade Hibernate Configuration..." -ForegroundColor Cyan

# 1. Apply the ConfigMap separately
Write-Host "`nCreating Hibernate configuration ConfigMap..." -ForegroundColor Yellow
$HIBERNATE_CONFIG = @"
apiVersion: v1
kind: ConfigMap
metadata:
  name: product-service-hibernate-config
  namespace: ecommerce
data:
  SPRING_JPA_HIBERNATE_DDL-AUTO: "update"
  SPRING_JPA_GENERATE-DDL: "true"
  SPRING_JPA_DATABASE-PLATFORM: "org.hibernate.dialect.PostgreSQLDialect"
  SPRING_JPA_PROPERTIES_HIBERNATE_FORMAT_SQL: "true"
  SPRING_JPA_SHOW-SQL: "true"
  SPRING_JPA_PROPERTIES_HIBERNATE_JDBC_BATCH_SIZE: "10"
  LOGGING_LEVEL_ORG_HIBERNATE_SQL: "DEBUG"
  LOGGING_LEVEL_ORG_HIBERNATE_TYPE_DESCRIPTOR_SQL_BASIC_BINDER: "TRACE"
"@

Set-Content -Path "hibernate-config.yaml" -Value $HIBERNATE_CONFIG
kubectl apply -f hibernate-config.yaml

# 2. Update the deployment with the new ConfigMap using a strategic patch
Write-Host "`nPatching deployment with ConfigMap reference..." -ForegroundColor Yellow
$PATCH_JSON = @"
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
                  "name": "product-service-hibernate-config"
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

Set-Content -Path "deployment-patch.json" -Value $PATCH_JSON
kubectl patch deployment product-service -n ecommerce --patch-file deployment-patch.json

# 3. Restart the deployment to apply changes
Write-Host "`nRestarting deployment to apply changes..." -ForegroundColor Yellow
kubectl rollout restart deployment product-service -n ecommerce

# 4. Monitor rollout status
Write-Host "`nMonitoring deployment rollout..." -ForegroundColor Green
Start-Sleep -Seconds 5
kubectl rollout status deployment/product-service -n ecommerce

# 5. Verify the pod configuration
Write-Host "`nVerifying pod configuration includes Hibernate environment variables..." -ForegroundColor Cyan
$POD_NAME = kubectl get pods -n ecommerce -l app=product-service -o jsonpath='{.items[0].metadata.name}'
kubectl describe pod $POD_NAME -n ecommerce | Select-String -Pattern "Environment"

Write-Host @"

===========================================================
ENTERPRISE DEPLOYMENT SUCCESS

The Hibernate configuration has been applied using a strategic merge patch
that maintains the immutable fields of the Kubernetes Deployment.

Next step: Test your product service API again with:
http://aee62280f41e04181bf13ba432fd2092-001b4178947505be.elb.us-west-2.amazonaws.com/api/products
===========================================================
"@ -ForegroundColor Green
