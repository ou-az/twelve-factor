# Spring Boot Microservice: Local Setup Guide

This guide provides comprehensive instructions for running, testing, and troubleshooting your Spring Boot microservice locally. It demonstrates a twelve-factor approach to application development with a focus on local development workflows.

## Table of Contents

1. [Project Overview](#project-overview)
2. [Prerequisites](#prerequisites)
3. [Running the Application](#running-the-application)
4. [Testing the API](#testing-the-api)
5. [Database Access](#database-access)
6. [Logging and Debugging](#logging-and-debugging)
7. [Troubleshooting](#troubleshooting)
8. [Advanced Configuration](#advanced-configuration)

## Project Overview

The project is a Product Service microservice built with Spring Boot. It provides RESTful API endpoints to manage products in an e-commerce system. Key features include:

- CRUD operations for products
- Search and filtering capabilities
- Category-based product organization
- Stock management
- H2 in-memory database for local development
- Sample data initialization

## Prerequisites

Before running the application, ensure you have the following installed:

- Java 17 or higher
- Maven 3.6.0 or higher
- Your preferred IDE (IntelliJ IDEA, Eclipse, VS Code)

You can verify your installations with:

```bash
java --version
mvn --version
```

## Running the Application

There are several ways to run the application locally:

### Method 1: Using the provided script

Navigate to the project directory and run the provided PowerShell script:

```powershell
cd C:\workspaces\interview\twelve-factor\ecommerce-microservices\product-service-simple
.\run-local.ps1
```

This script will:
1. Build the application with Maven
2. Run it with the default profile
3. Initialize the H2 database with sample data

### Method 2: Using Maven directly

```powershell
cd C:\workspaces\interview\twelve-factor\ecommerce-microservices\product-service-simple
mvn spring-boot:run
```

### Method 3: Running the JAR file

```powershell
cd C:\workspaces\interview\twelve-factor\ecommerce-microservices\product-service-simple
mvn clean package -DskipTests
java -jar target/product-service-simple-0.0.1-SNAPSHOT.jar
```

The application will start on port 8080 by default. You should see output similar to:

```
2025-05-14T13:01:56.631-07:00 INFO  --- [main] c.e.p.config.DataInitializer : Initialized 5 sample products
2025-05-14T13:01:56.656-07:00 DEBUG --- [main] org.hibernate.SQL : ...
...
2025-05-14T13:01:57.631-07:00 INFO  --- [main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat started on port(s): 8080 (http) with context path '/'
```

## Testing the API

Once the application is running, you can test the API using tools like cURL, Postman, or your web browser.

### API Endpoints

| Endpoint | Method | Description | Example |
|----------|--------|-------------|---------|
| `/api/products` | GET | Get all products | `curl http://localhost:8080/api/products` |
| `/api/products/{id}` | GET | Get product by ID | `curl http://localhost:8080/api/products/1` |
| `/api/products` | POST | Create a new product | `curl -X POST -H "Content-Type: application/json" -d '{"name":"New Product", "price":29.99, "stockQuantity":10}' http://localhost:8080/api/products` |
| `/api/products/{id}` | PUT | Update a product | `curl -X PUT -H "Content-Type: application/json" -d '{"name":"Updated Product", "price":39.99, "stockQuantity":20}' http://localhost:8080/api/products/1` |
| `/api/products/{id}` | DELETE | Delete a product | `curl -X DELETE http://localhost:8080/api/products/1` |
| `/api/products/search` | GET | Search products by name | `curl http://localhost:8080/api/products/search?name=Java` |
| `/api/products/category/{categoryId}` | GET | Get products by category | `curl http://localhost:8080/api/products/category/1` |
| `/api/products/price-range` | GET | Get products in price range | `curl http://localhost:8080/api/products/price-range?minPrice=10&maxPrice=100` |
| `/api/products/low-stock` | GET | Get products with low stock | `curl http://localhost:8080/api/products/low-stock?threshold=20` |
| `/api/products/{id}/stock` | PATCH | Update product stock | `curl -X PATCH http://localhost:8080/api/products/1/stock?quantity=25` |

### Example Response

When you call the `/api/products/category/1` endpoint, you'll receive a response like:

```json
[
  {
    "id": 1,
    "name": "Enterprise Java Development Book",
    "description": "Comprehensive guide to Java enterprise development, covering Spring Boot, Microservices, and Cloud deployment",
    "price": 49.99,
    "imageUrl": "https://example.com/images/java-book.jpg",
    "categoryId": 1,
    "stockQuantity": 50,
    "createdAt": "2025-05-14T13:01:56.631879",
    "updatedAt": "2025-05-14T13:01:56.631879"
  },
  {
    "id": 3,
    "name": "Kafka in Action",
    "description": "Practical guide to implementing event streaming with Apache Kafka in enterprise applications",
    "price": 39.99,
    "imageUrl": "https://example.com/images/kafka-book.jpg",
    "categoryId": 1,
    "stockQuantity": 30,
    "createdAt": "2025-05-14T13:01:56.631879",
    "updatedAt": "2025-05-14T13:01:56.631879"
  }
]
```

## Database Access

The application uses an H2 in-memory database for local development. You can access the H2 console to view and modify data directly:

1. Open your browser and navigate to: http://localhost:8080/h2-console
2. Enter the following connection details:
   - JDBC URL: `jdbc:h2:mem:productdb`
   - Username: `sa`
   - Password: (leave blank)
3. Click "Connect"

In the console, you can run SQL queries against the database:

```sql
-- View all products
SELECT * FROM PRODUCTS;

-- View products in a specific category
SELECT * FROM PRODUCTS WHERE CATEGORY_ID = 1;

-- Update a product's stock
UPDATE PRODUCTS SET STOCK_QUANTITY = 75 WHERE ID = 1;
```

## Logging and Debugging

### Viewing Logs

The application uses SLF4J with Logback for logging. Logs are output to the console by default.

Key log levels are configured in `application.yml`:
- `com.ecommerce.product`: DEBUG
- `org.hibernate.SQL`: DEBUG
- `org.hibernate.type.descriptor.sql.BasicBinder`: TRACE

### Debug Mode

To run the application in debug mode, you can:

1. Use the Maven debug option:
   ```powershell
   mvn spring-boot:run -Dspring-boot.run.jvmArguments="-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=8787"
   ```

2. Connect your IDE to the debug port (8787)

## Troubleshooting

### Common Issues and Solutions

#### Application Won't Start

**Issue**: The application fails to start with port binding errors.

**Solution**: 
- Check if another application is using port 8080
- Change the port in `application.yml`:
  ```yaml
  server:
    port: 8081
  ```

#### Database Connection Issues

**Issue**: "Failed to initialize H2 console" errors.

**Solution**:
- Verify H2 dependency in pom.xml
- Check if H2 console is enabled in application.yml
- Try running with an explicit database URL:
  ```
  mvn spring-boot:run -Dspring.datasource.url=jdbc:h2:mem:productdb;DB_CLOSE_DELAY=-1
  ```

#### API Returns 404

**Issue**: API endpoints return 404 Not Found.

**Solution**:
- Verify the context path in application.yml
- Ensure you're using the correct URL (http://localhost:8080/api/products)
- Check controller mappings (@RequestMapping annotations)

#### Hibernate/JPA Issues

**Issue**: Entity mapping errors or SQL exceptions.

**Solution**:
- Enable detailed Hibernate logging:
  ```yaml
  logging:
    level:
      org.hibernate: DEBUG
      org.hibernate.type: TRACE
  ```
- Check entity annotations (@Entity, @Table, etc.)
- Verify database schema using H2 console

### Finding and Analyzing Logs

Spring Boot logs are written to the console by default. For more advanced logging:

1. Add a file appender in `src/main/resources/logback-spring.xml`
2. Use the `logging.file.name` property:
   ```yaml
   logging:
     file:
       name: application.log
   ```
3. Use log analysis tools like Logback listeners or ELK stack (for production)

## Advanced Configuration

### Profiles

The application supports different Spring profiles. To run with a specific profile:

```powershell
mvn spring-boot:run -Dspring-boot.run.profiles=dev
```

### Environment Variables

You can override configuration with environment variables:

```powershell
$env:SERVER_PORT = 8081
mvn spring-boot:run
```

### Additional JVM Arguments

To allocate more memory or set system properties:

```powershell
mvn spring-boot:run -Dspring-boot.run.jvmArguments="-Xmx512m -Dsome.property=value"
```

---

This guide covers the basics of running, testing, and troubleshooting your Spring Boot microservice locally. For additional help, refer to the [Spring Boot documentation](https://docs.spring.io/spring-boot/docs/current/reference/html/) or the project README.
