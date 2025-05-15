# Local Development Setup with Docker

This guide explains how to set up a complete local development environment using Docker containers for a Spring Boot application that connects to PostgreSQL, Kafka, and Zookeeper.

## Architecture Overview

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│                 │     │                 │     │                 │
│  Spring Boot    │────▶│   PostgreSQL    │     │    Zookeeper    │
│  Application    │     │   Database      │     │                 │
│                 │     │                 │     │                 │
└────────┬────────┘     └─────────────────┘     └────────┬────────┘
         │                                               │
         │                                               │
         │                                               ▼
         │                                      ┌─────────────────┐
         │                                      │                 │
         └─────────────────────────────────────▶│     Kafka       │
                                                │                 │
                                                └─────────────────┘
```

## Prerequisites

- Docker and Docker Compose installed
- Java 17 and Maven installed (for local development outside Docker)
- Git to clone the repository

## Step 1: Project Structure

Ensure your project has the following structure:
```
product-service-simple/
├── src/                           # Spring Boot application source code
├── Dockerfile                     # Docker image definition for Spring Boot app
├── docker-compose.yml             # Docker Compose configuration for all services
├── pom.xml                        # Maven dependencies
└── README.md                      # Project documentation
```

## Step 2: Docker Compose Configuration

Create a comprehensive `docker-compose.yml` file in the root directory:

```yaml
version: '3.8'

services:
  # Spring Boot Application
  app:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: product-service-app
    ports:
      - "8080:8080"
    environment:
      - SPRING_PROFILES_ACTIVE=docker
      - SPRING_DATASOURCE_URL=jdbc:postgresql://db:5432/product_db
      - SPRING_DATASOURCE_USERNAME=postgres
      - SPRING_DATASOURCE_PASSWORD=postgres
      - SPRING_KAFKA_BOOTSTRAP_SERVERS=kafka:9092
    depends_on:
      db:
        condition: service_healthy
      kafka:
        condition: service_healthy
    networks:
      - app-network
    healthcheck:
      test: ["CMD", "wget", "-q", "--spider", "http://localhost:8080/actuator/health"]
      interval: 30s
      timeout: 3s
      retries: 5
    restart: unless-stopped
    volumes:
      - ./logs:/app/logs

  # PostgreSQL Database
  db:
    image: postgres:13
    container_name: product-service-db
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_DB=product_db
    volumes:
      - postgres_data:/var/lib/postgresql/data
      # Initialize database with schema/data if needed
      # - ./db/init.sql:/docker-entrypoint-initdb.d/init.sql
    networks:
      - app-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Zookeeper (required for Kafka)
  zookeeper:
    image: confluentinc/cp-zookeeper:7.3.0
    container_name: zookeeper
    ports:
      - "2181:2181"
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: 2000
    networks:
      - app-network
    healthcheck:
      test: echo stat | nc localhost 2181
      interval: 10s
      timeout: 3s
      retries: 10

  # Kafka Message Broker
  kafka:
    image: confluentinc/cp-kafka:7.3.0
    container_name: kafka
    ports:
      - "9092:9092"
      - "29092:29092"  # For external applications
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:9092,PLAINTEXT_HOST://localhost:29092
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT
      KAFKA_INTER_BROKER_LISTENER_NAME: PLAINTEXT
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_AUTO_CREATE_TOPICS_ENABLE: "true"
    depends_on:
      zookeeper:
        condition: service_healthy
    networks:
      - app-network
    healthcheck:
      test: ["CMD", "kafka-topics", "--bootstrap-server", "localhost:9092", "--list"]
      interval: 30s
      timeout: 10s
      retries: 5

  # Kafka UI for monitoring (optional but helpful)
  kafka-ui:
    image: provectuslabs/kafka-ui:latest
    container_name: kafka-ui
    ports:
      - "8090:8080"
    environment:
      - KAFKA_CLUSTERS_0_NAME=local
      - KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS=kafka:9092
      - KAFKA_CLUSTERS_0_ZOOKEEPER=zookeeper:2181
    depends_on:
      - kafka
    networks:
      - app-network

networks:
  app-network:
    driver: bridge

volumes:
  postgres_data:
```

## Step 3: Dockerfile for Spring Boot Application

Create an optimized `Dockerfile` for your Spring Boot application:

```Dockerfile
FROM maven:3.8.6-openjdk-17-slim AS build
WORKDIR /app

# Copy the pom.xml for dependency resolution
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy source code and build the application
COPY src ./src
RUN mvn package -DskipTests

# Create slim runtime image
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

# Set environment variables
ENV SPRING_PROFILES_ACTIVE=docker

# Create non-root user for security
RUN addgroup --system javauser && adduser --system --ingroup javauser javauser
USER javauser

# Copy built application from build stage
COPY --from=build /app/target/*.jar app.jar

# Configure JVM options for containers
ENTRYPOINT ["java", "-Xms256m", "-Xmx512m", "-jar", "app.jar"]

# Expose the application port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD wget -q --spider http://localhost:8080/actuator/health || exit 1
```

## Step 4: Spring Boot Application Configuration

Create a Docker-specific Spring Boot configuration file:

1. Add a file `src/main/resources/application-docker.yml`:

```yaml
spring:
  # PostgreSQL Configuration
  datasource:
    url: jdbc:postgresql://db:5432/product_db
    username: postgres
    password: postgres
    driver-class-name: org.postgresql.Driver
  jpa:
    hibernate:
      ddl-auto: update
    show-sql: true
    properties:
      hibernate:
        dialect: org.hibernate.dialect.PostgreSQLDialect
        format_sql: true
  
  # Kafka Configuration
  kafka:
    bootstrap-servers: kafka:9092
    producer:
      key-serializer: org.apache.kafka.common.serialization.StringSerializer
      value-serializer: org.springframework.kafka.support.serializer.JsonSerializer
    consumer:
      group-id: product-service-group
      auto-offset-reset: earliest
      key-deserializer: org.apache.kafka.common.serialization.StringDeserializer
      value-deserializer: org.springframework.kafka.support.serializer.JsonDeserializer
      properties:
        spring.json.trusted.packages: com.ecommerce.product.kafka.event

# Actuator for health checks
management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics
  endpoint:
    health:
      show-details: always

# Application-specific configuration
server:
  port: 8080

# Logging configuration
logging:
  level:
    root: INFO
    com.ecommerce: DEBUG
    org.hibernate.SQL: DEBUG
  file:
    name: /app/logs/application.log
```

## Step 5: Maven Dependencies

Ensure your `pom.xml` has the necessary dependencies:

```xml
<!-- PostgreSQL -->
<dependency>
    <groupId>org.postgresql</groupId>
    <artifactId>postgresql</artifactId>
    <scope>runtime</scope>
</dependency>

<!-- Kafka -->
<dependency>
    <groupId>org.springframework.kafka</groupId>
    <artifactId>spring-kafka</artifactId>
</dependency>

<!-- Actuator for health checks -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```

## Step 6: Running the Environment

Follow these steps to start your development environment:

1. **Build and start all services**:
   ```bash
   docker-compose up -d
   ```

2. **Check if all services are running**:
   ```bash
   docker-compose ps
   ```

3. **View application logs**:
   ```bash
   docker logs -f product-service-app
   ```

4. **Verify connectivity**:
   - Spring Boot API: http://localhost:8080/api/products
   - Kafka UI: http://localhost:8090

## Step 7: Testing the API Endpoints

Use these endpoints to verify your application is working properly:

- **List all products**: http://localhost:8080/api/products
- **Get a specific product**: http://localhost:8080/api/products/1
- **Search products by name**: http://localhost:8080/api/products/search?name=Java
- **Get products by category**: http://localhost:8080/api/products/category/1
- **Get products by price range**: http://localhost:8080/api/products/price-range?minPrice=10&maxPrice=100

Using cURL or Postman to create a product:

```bash
curl -X POST http://localhost:8080/api/products \
  -H "Content-Type: application/json" \
  -d '{"name":"Cloud Native Java","description":"Spring Boot and Cloud Native Patterns","price":49.99,"categoryId":1,"stockQuantity":100}'
```

## Step 8: Interacting with the Infrastructure

### PostgreSQL Database

Connect to the database:
```bash
docker exec -it product-service-db psql -U postgres -d product_db
```

Common PostgreSQL commands:
```sql
-- List tables
\dt

-- Query the products table
SELECT * FROM products;

-- Exit the PostgreSQL shell
\q
```

### Kafka

Create a Kafka topic:
```bash
docker exec -it kafka kafka-topics --create --topic product-events --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1
```

List Kafka topics:
```bash
docker exec -it kafka kafka-topics --list --bootstrap-server localhost:9092
```

Consume messages from a topic:
```bash
docker exec -it kafka kafka-console-consumer --topic product-events --bootstrap-server localhost:9092 --from-beginning
```

## Troubleshooting

### Common Issues and Solutions

1. **Connection refused to PostgreSQL**:
   - Check if the PostgreSQL container is running: `docker ps | grep postgres`
   - Verify the correct port mapping: `docker-compose ps db`
   - Ensure the application is using the correct connection details

2. **Kafka connection issues**:
   - Verify Zookeeper is running before Kafka: `docker logs zookeeper`
   - Check Kafka logs: `docker logs kafka`
   - Ensure the bootstrap servers configuration is correct

3. **Application container exits immediately**:
   - Check application logs: `docker logs product-service-app`
   - Verify environment variables are correctly set
   - Ensure the JAR file was built correctly

4. **Database schema issues**:
   - Set `spring.jpa.hibernate.ddl-auto=create-drop` temporarily to recreate schema
   - Consider adding a database initialization script

## Stopping the Environment

To stop all services:
```bash
docker-compose down
```

To stop services and remove volumes (will delete database data):
```bash
docker-compose down -v
```

## Next Steps

1. Add data initialization logic to populate the database
2. Implement Kafka event producers and consumers
3. Add monitoring with Prometheus and Grafana
4. Implement CI/CD for automated testing and deployment

---

This setup provides a solid foundation for developing and testing your Spring Boot application locally with Docker. It mimics a production-like environment while being easy to manage, making it ideal for developing cloud-ready applications.
