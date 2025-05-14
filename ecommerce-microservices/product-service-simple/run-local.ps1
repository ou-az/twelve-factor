# PowerShell script to run the simplified product service
Write-Host "Starting Simplified E-Commerce Product Service" -ForegroundColor Green

# Navigate to product service directory
Set-Location -Path $PSScriptRoot

Write-Host "Building the application..." -ForegroundColor Cyan
mvn clean package -DskipTests
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to build the application. Check for compilation errors." -ForegroundColor Red
    exit 1
}

Write-Host "Starting the application..." -ForegroundColor Yellow
Write-Host "Once started, you can access the API at: http://localhost:8080/api/products" -ForegroundColor Cyan
Write-Host "H2 Database console will be available at: http://localhost:8080/h2-console" -ForegroundColor Cyan
Write-Host "JDBC URL: jdbc:h2:mem:productdb | Username: sa | Password: <leave empty>" -ForegroundColor Cyan

mvn spring-boot:run

Write-Host "Application stopped" -ForegroundColor Green
