# PowerShell script to diagnose PostgreSQL connectivity issues

Write-Host "Diagnosing PostgreSQL connectivity issues..." -ForegroundColor Cyan

# Step 1: Check if PostgreSQL pod is running
Write-Host "`nChecking PostgreSQL pod status..." -ForegroundColor Yellow
$POSTGRES_PODS = kubectl get pods -n ecommerce -l app=postgres -o json | ConvertFrom-Json
if ($POSTGRES_PODS.items.Count -eq 0) {
    Write-Host "No PostgreSQL pods found! This is the root issue." -ForegroundColor Red
} else {
    foreach ($pod in $POSTGRES_PODS.items) {
        Write-Host "PostgreSQL pod: $($pod.metadata.name) - Status: $($pod.status.phase)" -ForegroundColor Cyan
    }
}

# Step 2: Check PostgreSQL service configuration
Write-Host "`nChecking PostgreSQL service..." -ForegroundColor Yellow
$POSTGRES_SVC = kubectl get svc postgres-service -n ecommerce -o json | ConvertFrom-Json
Write-Host "PostgreSQL service ClusterIP: $($POSTGRES_SVC.spec.clusterIP)" -ForegroundColor Cyan
Write-Host "PostgreSQL service Port: $($POSTGRES_SVC.spec.ports[0].port)" -ForegroundColor Cyan
Write-Host "PostgreSQL service Target Port: $($POSTGRES_SVC.spec.ports[0].targetPort)" -ForegroundColor Cyan
Write-Host "PostgreSQL service selector: app=$($POSTGRES_SVC.spec.selector.app)" -ForegroundColor Cyan

# Step 3: Check if service selector matches pod labels
Write-Host "`nVerifying service selector matches pod labels..." -ForegroundColor Yellow
$SERVICE_SELECTOR = $POSTGRES_SVC.spec.selector.app
$MATCHING_PODS = kubectl get pods -n ecommerce -l app=$SERVICE_SELECTOR -o json | ConvertFrom-Json
Write-Host "Pods matching service selector 'app=$SERVICE_SELECTOR': $($MATCHING_PODS.items.Count)" -ForegroundColor Cyan

# Step 4: Check database secret configuration
Write-Host "`nChecking database secrets..." -ForegroundColor Yellow
$DB_SECRET = kubectl get secret product-service-secrets -n ecommerce -o json | ConvertFrom-Json
$DB_URL = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($DB_SECRET.data.'SPRING_DATASOURCE_URL'))
$DB_USERNAME = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($DB_SECRET.data.'SPRING_DATASOURCE_USERNAME'))
Write-Host "Database URL: $DB_URL" -ForegroundColor Cyan
Write-Host "Database Username: $DB_USERNAME" -ForegroundColor Cyan

# Step 5: Test network connectivity from a debugging pod
Write-Host "`nDeploying a network diagnostic pod to test connectivity..." -ForegroundColor Yellow
$DEBUG_POD = @"
apiVersion: v1
kind: Pod
metadata:
  name: network-debug
  namespace: ecommerce
spec:
  containers:
  - name: network-debug
    image: nicolaka/netshoot
    command: ["sleep", "3600"]
  restartPolicy: Never
"@

Set-Content -Path "network-debug-pod.yaml" -Value $DEBUG_POD
kubectl apply -f network-debug-pod.yaml

Write-Host "Waiting for debug pod to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Step 6: Extract hostname and port from JDBC URL
if ($DB_URL -match "jdbc:postgresql://([^:]+):(\d+)/(\w+)") {
    $HOSTNAME = $Matches[1]
    $PORT = $Matches[2]
    $DATABASE = $Matches[3]
    
    Write-Host "`nTesting connection to $HOSTNAME on port $PORT..." -ForegroundColor Yellow
    kubectl exec -it network-debug -n ecommerce -- nc -zv $HOSTNAME $PORT
} else {
    Write-Host "Could not parse JDBC URL format" -ForegroundColor Red
}

# Step 7: Check PostgreSQL logs if pod exists
if ($POSTGRES_PODS.items.Count -gt 0) {
    $POD_NAME = $POSTGRES_PODS.items[0].metadata.name
    Write-Host "`nChecking PostgreSQL logs from $POD_NAME..." -ForegroundColor Yellow
    kubectl logs -n ecommerce $POD_NAME
}

# Step 8: Provide recommended fixes
Write-Host "`n========== DIAGNOSTIC SUMMARY AND RECOMMENDATIONS ==========" -ForegroundColor Green
if ($POSTGRES_PODS.items.Count -eq 0) {
    Write-Host "ISSUE: PostgreSQL pod is not running" -ForegroundColor Red
    Write-Host "FIX: Deploy PostgreSQL with the following command:" -ForegroundColor Cyan
    Write-Host "kubectl apply -f postgres-deployment.yaml" -ForegroundColor White
}
elseif ($MATCHING_PODS.items.Count -eq 0) {
    Write-Host "ISSUE: Service selector does not match any pod labels" -ForegroundColor Red
    Write-Host "FIX: Update either pod labels or service selector to match correctly" -ForegroundColor Cyan
}
else {
    Write-Host "ISSUE: Connection problem between Product service and PostgreSQL" -ForegroundColor Red
    Write-Host "FIX: Check SPRING_DATASOURCE_URL configuration and ensure it matches the PostgreSQL service name" -ForegroundColor Cyan
    Write-Host @"
Update the database URL in your secret with:
kubectl create secret generic product-service-secrets -n ecommerce --from-literal=SPRING_DATASOURCE_URL=jdbc:postgresql://postgres-service:5432/product_db --from-literal=SPRING_DATASOURCE_USERNAME=postgres --from-literal=SPRING_DATASOURCE_PASSWORD=yourpassword --dry-run=client -o yaml | kubectl apply -f -
"@ -ForegroundColor White
}

# Clean up
Write-Host "`nCleaning up diagnostic resources..." -ForegroundColor Yellow
kubectl delete pod network-debug -n ecommerce
