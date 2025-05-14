# PowerShell script to start local development environment
Write-Host "Starting E-Commerce Microservices Development Environment" -ForegroundColor Green

# Ensure Docker is running
$dockerStatus = docker info 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker is not running. Please start Docker Desktop first." -ForegroundColor Red
    exit 1
}

Write-Host "Step 1: Starting infrastructure containers (PostgreSQL, Kafka)..." -ForegroundColor Cyan
docker-compose up -d
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to start containers. Check the docker-compose.yml file." -ForegroundColor Red
    exit 1
}

# Wait for services to be ready
Write-Host "Waiting for services to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Set Spring profile to local
$env:SPRING_PROFILES_ACTIVE = "local"

Write-Host "Step 2: Building the product service application..." -ForegroundColor Cyan
Set-Location -Path .\product-service
mvn clean package -DskipTests
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to build the application. Check for compilation errors." -ForegroundColor Red
    exit 1
}

Write-Host "Step 3: Running the product service application..." -ForegroundColor Cyan
Write-Host "Starting Spring Boot application with profile: $env:SPRING_PROFILES_ACTIVE" -ForegroundColor Yellow
mvn spring-boot:run -Dspring-boot.run.profiles=local

# Script will stay here until the Spring Boot application is stopped
# When the application is stopped, we'll clean up

Write-Host "Stopping containers..." -ForegroundColor Cyan
Set-Location -Path ..
docker-compose down

Write-Host "Local development environment stopped" -ForegroundColor Green
