# Spring Boot Microservice Testing Guide

This document provides comprehensive testing information for the Product Service microservice, demonstrating enterprise-ready capabilities and production-grade implementation patterns.

## Table of Contents

1. [Infrastructure Overview](#infrastructure-overview)
2. [Environment Setup](#environment-setup)
3. [API Endpoints Testing](#api-endpoints-testing)
4. [Monitoring and Health Checks](#monitoring-and-health-checks)
5. [Database Operations](#database-operations)
6. [Kubernetes/AWS Readiness](#kubernetesaws-readiness)
7. [Performance Considerations](#performance-considerations)
8. [Troubleshooting Guide](#troubleshooting-guide)

## Infrastructure Overview

The microservice is deployed as Docker containers with the following components:

| Service | Container Name | Base Image | Purpose |
|---------|---------------|------------|---------|
| Spring Boot API | product-service-app | eclipse-temurin:17-jre | Application server |
| PostgreSQL | product-service-db | postgres:13 | Database server |

Architecture diagram:
```
┌─────────────────┐     ┌─────────────────┐
│                 │     │                 │
│  Spring Boot    │────▶│   PostgreSQL    │
│  Application    │     │   Database      │
│                 │     │                 │
└─────────────────┘     └─────────────────┘
```

## Environment Setup

### Starting the Environment

```bash
# Build and start all containers
docker-compose up -d --build

# View running containers
docker ps

# Check logs of the Spring Boot application
docker logs -f product-service-app
```

### Stopping the Environment

```bash
# Stop and remove all containers
docker-compose down

# Stop and remove containers and volumes (database data will be lost)
docker-compose down -v
```

## API Endpoints Testing

### Core Business Functionality

| Endpoint | HTTP Method | Description | Example |
|----------|------------|-------------|---------|
| `/api/products` | GET | List all products | http://localhost:8080/api/products |
| `/api/products/{id}` | GET | Get specific product | http://localhost:8080/api/products/1 |
| `/api/products/search` | GET | Search products by name | http://localhost:8080/api/products/search?name=Kafka |
| `/api/products/category/{id}` | GET | Get products by category | http://localhost:8080/api/products/category/1 |
| `/api/products/price-range` | GET | Get products by price | http://localhost:8080/api/products/price-range?minPrice=10&maxPrice=100 |
| `/api/products` | POST | Create new product | See below |

#### Creating a New Product

Using cURL:
```bash
curl -X POST http://localhost:8080/api/products \
  -H "Content-Type: application/json" \
  -d '{
    "name": "AWS Cloud Architecture",
    "description": "Comprehensive guide to AWS infrastructure design",
    "price": 79.99,
    "categoryId": 1,
    "stockQuantity": 30
  }'
```

Using Postman:
1. Set method to POST
2. Set URL to http://localhost:8080/api/products
3. Set Headers: Content-Type: application/json
4. Set Body to raw JSON:
```json
{
  "name": "AWS Cloud Architecture",
  "description": "Comprehensive guide to AWS infrastructure design",
  "price": 79.99,
  "categoryId": 1,
  "stockQuantity": 30
}
```

### Expected Response Format

```json
{
  "id": 6,
  "name": "AWS Cloud Architecture",
  "description": "Comprehensive guide to AWS infrastructure design",
  "price": 79.99,
  "categoryId": 1,
  "stockQuantity": 30,
  "createdAt": "2025-05-15T00:35:10.453247",
  "updatedAt": "2025-05-15T00:35:10.453247"
}
```

## Monitoring and Health Checks

### Spring Boot Actuator Endpoints

| Endpoint | Description | Example |
|----------|-------------|---------|
| `/actuator` | List of available actuator endpoints | http://localhost:8080/actuator |
| `/actuator/health` | Overall health information | http://localhost:8080/actuator/health |
| `/actuator/health/liveness` | Kubernetes liveness probe | http://localhost:8080/actuator/health/liveness |
| `/actuator/health/readiness` | Kubernetes readiness probe | http://localhost:8080/actuator/health/readiness |
| `/actuator/info` | Application information | http://localhost:8080/actuator/info |
| `/actuator/metrics` | Available metrics | http://localhost:8080/actuator/metrics |
| `/actuator/metrics/{metric}` | Specific metric details | http://localhost:8080/actuator/metrics/http.server.requests |

### Sample Health Check Response

```json
{
  "status": "UP",
  "components": {
    "db": {
      "status": "UP",
      "details": {
        "database": "PostgreSQL",
        "validationQuery": "isValid()"
      }
    },
    "diskSpace": {
      "status": "UP",
      "details": {
        "total": 1081101176832,
        "free": 1016299687936,
        "threshold": 10485760,
        "path": "/app/.",
        "exists": true
      }
    },
    "livenessState": {
      "status": "UP"
    },
    "ping": {
      "status": "UP"
    },
    "readinessState": {
      "status": "UP"
    }
  },
  "groups": [
    "liveness",
    "readiness"
  ]
}
```

### Key Metrics to Monitor

- JVM Memory Usage: `/actuator/metrics/jvm.memory.used`
- HTTP Request Statistics: `/actuator/metrics/http.server.requests`
- Database Connection Pool: `/actuator/metrics/hikaricp.connections`
- Garbage Collection: `/actuator/metrics/jvm.gc.pause`
- Thread Utilization: `/actuator/metrics/jvm.threads.live`

## Database Operations

### Accessing PostgreSQL Database

```bash
# Connect to PostgreSQL database
docker exec -it product-service-db psql -U postgres -d product_db

# List tables
\dt

# View products data
SELECT * FROM products;

# Exit PostgreSQL console
\q
```

### Data Model

The Products table schema:

```sql
CREATE TABLE products (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  price DECIMAL(10,2) NOT NULL,
  image_url VARCHAR(255),
  category_id INTEGER NOT NULL,
  stock_quantity INTEGER NOT NULL,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
```

## Kubernetes/AWS Readiness

This application is designed with cloud-native principles, making it ready for deployment to Kubernetes/AWS ECS:

### Key Production-Ready Features

1. **Health Probes**: Liveness and readiness probes used by Kubernetes for restart decisions
2. **Metrics Exposure**: Prometheus-compatible metrics for cloud monitoring
3. **Database Connectivity**: Externalized configuration for different environments
4. **Docker Optimization**: Multi-stage build with minimal final image
5. **Non-Root Execution**: Container runs as non-root user for security
6. **Configurable Resources**: Memory limits defined in Docker Compose

### AWS Deployment Readiness

For AWS deployment, the following patterns are implemented:

1. **Configuration via Environment Variables**: Following twelve-factor app principles
2. **Health Check Integration**: Works with ECS/EKS health checks
3. **Container Registry Ready**: Image can be pushed to ECR
4. **RDS Compatible**: Can connect to AWS RDS PostgreSQL instances
5. **CloudWatch Compatible**: Structured logging for CloudWatch integration

## Performance Considerations

### JVM Settings

The application is configured with the following JVM settings:

```
-Xms256m -Xmx512m
```

These settings provide:
- 256MB minimum heap size
- 512MB maximum heap size

This balance is suitable for a microservice with moderate load. For higher throughput systems, consider increasing these values to:

```
-Xms512m -Xmx1024m
```

### Connection Pooling

The application uses HikariCP for connection pooling with these settings:

- Maximum pool size: 10 connections
- Connection timeout: 30 seconds
- Idle timeout: 600 seconds

### Caching

Consider implementing Redis caching for:
- Product catalog data
- Category information
- Frequently accessed reference data

## Troubleshooting Guide

### Common Issues and Solutions

1. **Application Container Fails to Start**
   - Check logs: `docker logs product-service-app`
   - Verify PostgreSQL connection details
   - Ensure PostgreSQL container is running
   - Check for port conflicts

2. **Database Connection Issues**
   - Verify database credentials in application-docker.yml
   - Ensure PostgreSQL container is healthy: `docker ps`
   - Check network connectivity between containers

3. **404 Errors on API Endpoints**
   - Verify application context path
   - Check if controller mappings are correct
   - Ensure API base path is correctly specified

4. **Performance Degradation**
   - Check database query performance
   - Monitor JVM memory usage: `/actuator/metrics/jvm.memory.used`
   - Check for slow queries in PostgreSQL logs
   - Consider enabling debug logging temporarily

### Debug Mode

To enable debug mode, update environment variables in docker-compose.yml:

```yaml
environment:
  - SPRING_PROFILES_ACTIVE=docker
  - LOGGING_LEVEL_ROOT=INFO
  - LOGGING_LEVEL_COM_ECOMMERCE=DEBUG
```

---

## Relevance to Job Applications

This microservice implementation demonstrates several skills relevant to specific job positions:

### Java Developer - Process Streaming (Intellibus)
- Spring Boot REST API development
- Database integration with JPA/Hibernate
- Ready for Kafka integration via messaging endpoints
- Structured for high-throughput processing

### Staff Software Engineer (Plexus Worldwide)
- Twelve-factor application design
- Microservices architecture
- Modern Spring Boot implementation
- Production-ready containerization

### DevOps/Cloud Engineer (Cyber-Infomax)
- Docker containerization with multi-stage builds
- Infrastructure as Code via docker-compose
- Monitoring capabilities with metrics
- Container health and lifecycle management

### Lead Java Software Engineer (Wells Fargo)
- Enterprise-grade Spring application
- Production-ready health monitoring
- JVM optimization for performance
- Secure configuration management

---

*This documentation is intended to support job applications by demonstrating comprehensive understanding of enterprise application development, deployment, and monitoring.*
