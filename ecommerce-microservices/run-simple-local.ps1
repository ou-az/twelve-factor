# PowerShell script for running just the product service locally with H2 DB
Write-Host "Starting E-Commerce Product Service in Simplified Local Mode" -ForegroundColor Green

# Set the active profile to local-simple
$env:SPRING_PROFILES_ACTIVE = "local-simple"

# Navigate to product service directory
Set-Location -Path .\product-service

Write-Host "Building the application..." -ForegroundColor Cyan
mvn clean package -DskipTests
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to build the application. Check for compilation errors." -ForegroundColor Red
    exit 1
}

Write-Host "Starting the application with profile: $env:SPRING_PROFILES_ACTIVE" -ForegroundColor Yellow
mvn spring-boot:run -Dspring-boot.run.profiles=local-simple

Write-Host "Application stopped" -ForegroundColor Green
