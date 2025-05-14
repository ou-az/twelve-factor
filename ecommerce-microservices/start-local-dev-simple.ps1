# PowerShell script to start the product service in simplified local mode
Write-Host "Starting E-Commerce Product Service in Local Mode (No Docker)" -ForegroundColor Green

# Set Java environment variables
$env:SPRING_PROFILES_ACTIVE = "local-simple"

Write-Host "Building the product service application..." -ForegroundColor Cyan
Set-Location -Path .\product-service
mvn clean package -DskipTests
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to build the application. Check for compilation errors." -ForegroundColor Red
    exit 1
}

Write-Host "Running the product service application in local mode..." -ForegroundColor Cyan
Write-Host "Starting Spring Boot application with profile: $env:SPRING_PROFILES_ACTIVE" -ForegroundColor Yellow
mvn spring-boot:run -Dspring-boot.run.profiles=local-simple

# Script will stay here until the Spring Boot application is stopped
Write-Host "Local development environment stopped" -ForegroundColor Green
