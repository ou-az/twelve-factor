# Healthcare SOA with Enterprise Database Adaptation

A Service Oriented Architecture for healthcare systems that demonstrates an enterprise-grade strategy for adapting microservices to work with existing database schemas while maintaining flexibility and scalability.

## Architecture Overview

This system implements a SOA approach with the following components:

- **MuleSoft ESB (3.8.0)**: Central integration hub that provides service orchestration and routing
- **Patient Service**: Manages patient demographics and medical information
- **Appointment Service**: Handles appointment scheduling with multi-database strategy
  - Uses PostgreSQL for core data (enterprise schema adaptation)
  - Uses MongoDB for appointment metadata and history
  - Uses Redis for caching and real-time updates
- **Shared PostgreSQL Database**: Enterprise database with legacy schema that both services adapt to

## Enterprise Database Adaptation Strategy

This project demonstrates a sophisticated approach for adapting Spring Boot microservices to work with existing enterprise database schemas:

1. **Entity ID Adaptation**: Using `@Column(columnDefinition="serial")` to work with existing serial columns
2. **Type Consistency**: Changing from `Long` to `Integer` types in repositories and services
3. **Column Naming**: Explicit column name definitions to match existing schema conventions
4. **Transient Properties**: Using `@Transient` for fields not in the database with custom persistence logic
5. **Custom Repository Implementation**: Creating specialized repository implementations for complex queries
6. **Feature Flags**: Implementing feature flags to control deployment of new capabilities

## Twelve-Factor Implementation

This codebase follows the twelve-factor principles:

1. **Codebase**: One codebase tracked in Git, many deployments
2. **Dependencies**: Explicitly declared in Maven POM files
3. **Config**: Stored in environment variables and application.yml
4. **Backing Services**: PostgreSQL, MongoDB, and Redis as attached resources
5. **Build, Release, Run**: Docker-based build and deployment process
6. **Processes**: Stateless microservices with enterprise database adaptation
7. **Port Binding**: Services export via HTTP ports (8091, 8092, 8081)
8. **Concurrency**: Horizontal scaling of stateless services
9. **Disposability**: Fast startup with Docker containers
10. **Dev/Prod Parity**: Containerized environments for consistency
11. **Logs**: Structured logging with logback
12. **Admin Processes**: One-off processes for database migrations and updates

## Development Setup

```bash
# Clone the repository
git clone https://github.com/your-org/healthcare-soa.git
cd healthcare-soa

# Start infrastructure services
docker-compose up -d postgres mongodb redis

# Start MuleSoft ESB
docker-compose up -d esb

# Build and start Patient Service
cd services/patient-service
./mvnw spring-boot:run -Dspring.profiles.active=local

# Build and start Appointment Service (in another terminal)
cd services/appointment-service
./mvnw spring-boot:run -Dspring.profiles.active=local
```

## Key Features

- **Enterprise Schema Compatibility**: Works with existing database schemas without modifications
- **Multi-Database Strategy**: Leverages different databases for different purposes
- **MuleSoft Integration**: Central ESB for service orchestration and routing
- **Containerized Deployment**: Docker-based deployment for all components
- **Feature Flag Controls**: Granular control over feature enablement
- **Flexible Repository Pattern**: Custom repository implementations for complex scenarios

## Documentation

Detailed documentation is available in the `docs` directory:

- [Architecture Overview](docs/Simple-SOA-Healthcare-Architecture.md)
- [MuleSoft Docker Setup](docs/MuleSoft-Docker-Setup.md)
- [Step-by-Step Setup Guide](docs/Step-By-Step-Setup-SOA-Mule-Project.md)
- [Implementation Plan](docs/Implementation-Plan.md)
- [Getting Started Guide](docs/Getting-Started.md)
- [Building Mule Docker](docs/Build-Own-Mule-Docker.md)
