# Twelve-Factor Application Demonstration

This repository contains a comprehensive demonstration of the twelve-factor application methodology implemented across different architectural approaches. It serves as a practical example for modern cloud-native application development practices.

## Project Overview

This project implements the same core business capabilities using two different architectural approaches:

1. **Service Oriented Architecture (SOA)** - Healthcare Information Exchange System
2. **Microservices Architecture** - E-Commerce Platform

Both implementations adhere to the twelve-factor principles while highlighting the differences and trade-offs between architectural styles. A unified monitoring dashboard provides observability across both systems.

## Repository Structure

```
twelve-factor/
├── healthcare-soa/              # SOA Implementation
│   ├── config/                  # Configuration for different environments
│   ├── scripts/                 # Deployment and operational scripts
│   └── src/                     # Application source code
│
├── ecommerce-microservices/     # Microservices Implementation
│   ├── api-gateway/             # API Gateway service
│   ├── product-service/         # Product catalog service
│   ├── order-service/           # Order management service
│   ├── payment-service/         # Payment processing service
│   ├── inventory-service/       # Inventory management service
│   ├── notification-service/    # Notification service
│   └── kubernetes/              # Kubernetes deployment manifests
│
└── monitoring-dashboard/        # Unified monitoring React application
    ├── public/                  # Static assets
    └── src/                     # React application code
```

## Twelve-Factor Implementation

Both architectural approaches in this project implement the twelve-factor principles:

1. **Codebase**: One codebase per application tracked in version control, deployed to multiple environments
2. **Dependencies**: Dependencies explicitly declared and isolated
3. **Config**: Configuration stored in the environment
4. **Backing Services**: Backing services treated as attached resources
5. **Build, Release, Run**: Strict separation of build and run stages
6. **Processes**: Applications executed as stateless processes
7. **Port Binding**: Services self-contained with exported HTTP endpoints
8. **Concurrency**: Applications scale horizontally via the process model
9. **Disposability**: Fast startup and graceful shutdown
10. **Dev/Prod Parity**: Development, staging, and production environments kept as similar as possible
11. **Logs**: Logs treated as event streams written to stdout
12. **Admin Processes**: Administrative tasks run as one-off processes

## Technology Stack

### Common Technologies
- Java 17
- Spring Boot 3.x
- Apache Kafka
- Docker & Kubernetes
- AWS Cloud Platform
- ReactJS (Monitoring Dashboard)

### SOA Implementation
- MuleSoft Anypoint Platform (ESB)
- PostgreSQL
- Redis
- Spring Integration

### Microservices Implementation
- Spring Cloud
- Resilience4j
- Kafka Streams
- Multiple databases (PostgreSQL, MongoDB, Redis)
- Kubernetes for orchestration

## Getting Started

### Prerequisites
- JDK 17+
- Docker and Docker Compose
- Kubernetes (local or cloud)
- Node.js 16+ (for monitoring dashboard)

### Local Development

1. Clone the repository:
   ```bash
   git clone https://github.com/ou-az/twelve-factor.git
   cd twelve-factor
   ```

2. Start the SOA Healthcare application:
   ```bash
   cd healthcare-soa
   ./mvnw spring-boot:run -Dspring.profiles.active=dev
   ```

3. Start the E-Commerce Microservices:
   ```bash
   cd ecommerce-microservices
   docker-compose up -d    # Starts infrastructure services
   cd product-service
   ../gradlew bootRun      # Start individual services
   ```

4. Start the monitoring dashboard:
   ```bash
   cd monitoring-dashboard
   npm install
   npm start
   ```

## Deployment

### AWS Deployment

Both applications can be deployed to AWS using:
- AWS ECS/EKS for container orchestration
- Amazon RDS for databases
- Amazon MSK for Kafka
- Amazon ElastiCache for Redis
- Amazon S3 and CloudFront for static assets
- AWS CloudWatch for monitoring and logging

Deployment scripts and infrastructure-as-code templates are provided in the respective project directories.

## CI/CD Pipeline

This project uses GitHub Actions for continuous integration and deployment:
- Automated testing
- Docker image building
- Infrastructure provisioning
- Multiple environment deployments (dev, staging, production)

## Key Architectural Differences

| Aspect | SOA (Healthcare) | Microservices (E-Commerce) |
|--------|------------------|----------------------------|
| Integration | Enterprise Service Bus (MuleSoft) | Direct API calls and events |
| Data Management | Shared databases with schema isolation | Database per service |
| Communication | Synchronous and asynchronous | Primarily event-driven |
| Deployment | Service-level deployment | Independent service deployment |
| Scalability | Vertical and horizontal | Primarily horizontal |
| Governance | Centralized governance | Decentralized governance |

## Project Extensions

This project can be extended in several ways:
- Implementing additional services
- Enhancing monitoring and observability
- Adding automated testing
- Implementing security features
- Enhancing deployment automation

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- [Twelve-Factor App Methodology](https://12factor.net/)
- [Spring Boot](https://spring.io/projects/spring-boot)
- [AWS Documentation](https://aws.amazon.com/documentation/)
