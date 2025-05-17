# Enterprise Spring Boot Configuration Fix
# Enables bean definition overriding to resolve Kafka topic bean collision

Write-Host "Implementing Spring Bean Configuration Fix..." -ForegroundColor Cyan

# 1. Create or update ConfigMap with bean overriding enabled
Write-Host "`nUpdating Spring configuration..." -ForegroundColor Yellow
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
  SPRING_JPA_SHOW-SQL: "true"
"@

Set-Content -Path "spring-config.yaml" -Value $SPRING_CONFIG
kubectl apply -f spring-config.yaml

# 2. Patch the deployment to use the updated ConfigMap
Write-Host "`nPatching deployment to use updated configuration..." -ForegroundColor Yellow
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
                  "name": "product-service-spring-config"
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

Set-Content -Path "deployment-spring-patch.json" -Value $PATCH_JSON
kubectl patch deployment product-service -n ecommerce --patch-file deployment-spring-patch.json

# 3. Force a clean restart with Recreate strategy to ensure clean application context
Write-Host "`nSetting deployment strategy to Recreate for clean restart..." -ForegroundColor Yellow
$STRATEGY_PATCH = @"
{
  "spec": {
    "strategy": {
      "type": "Recreate"
    }
  }
}
"@

Set-Content -Path "strategy-patch.json" -Value $STRATEGY_PATCH
kubectl patch deployment product-service -n ecommerce --patch-file strategy-patch.json

# 4. Scale down to ensure clean restart
Write-Host "`nScaling down deployment..." -ForegroundColor Yellow
kubectl scale deployment product-service -n ecommerce --replicas=0
Start-Sleep -Seconds 5

# 5. Scale back up
Write-Host "`nScaling up deployment..." -ForegroundColor Green
kubectl scale deployment product-service -n ecommerce --replicas=1

# 6. Wait for deployment to stabilize
Write-Host "`nWaiting for deployment to stabilize..." -ForegroundColor Yellow
Start-Sleep -Seconds 20

# 7. Check pod status
Write-Host "`nVerifying pod status..." -ForegroundColor Cyan
kubectl get pods -n ecommerce -l app=product-service

# 8. Check logs for confirmation
Write-Host "`nChecking logs for spring configuration..." -ForegroundColor Yellow
$POD_NAME = kubectl get pods -n ecommerce -l app=product-service -o jsonpath='{.items[0].metadata.name}'
kubectl logs $POD_NAME -n ecommerce

Write-Host @"

===========================================================
ENTERPRISE JAVA CONFIGURATION APPLIED

The Spring application should now start with bean overriding enabled.
This resolves the conflict between Kafka topic bean definitions.

Try accessing your API at:
http://aee62280f41e04181bf13ba432fd2092-001b4178947505be.elb.us-west-2.amazonaws.com/api/products
===========================================================
"@ -ForegroundColor Green
