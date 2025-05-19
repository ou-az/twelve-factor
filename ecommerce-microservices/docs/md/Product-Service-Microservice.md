# Product Service Microservice

## Overview
The Product Service is a cloud-native microservice built as part of an event-driven e-commerce platform. This microservice follows the twelve-factor app methodology and is designed to manage product-related operations within the e-commerce ecosystem.

## Key Features
- RESTful API for product management (CRUD operations)
- Event-driven architecture using Kafka for real-time event publishing
- PostgreSQL database for product data persistence
- Circuit breaker patterns for resilience
- Containerized deployment with Docker and Docker Compose
- Environment-specific configuration profiles

## Technology Stack
- **Java 17** - Core programming language
- **Spring Boot** - Application framework
- **Spring Data JPA** - Data access layer
- **PostgreSQL** - Relational database
- **Apache Kafka** - Event streaming platform
- **Docker & Docker Compose** - Containerization and orchestration
- **Maven** - Build and dependency management

## Documentation Index
- [Architecture Overview](Architecture.md) - Detailed architecture diagrams and design patterns
- [Configuration Guide](Configuration.md) - Application configuration details
- [Development Environment](Development.md) - Setting up your development environment
- [Deployment Guide](Deployment.md) - Deployment instructions and considerations
- [API Documentation](API.md) - API endpoints and usage
- [Event Schema](Events.md) - Kafka event schemas and examples

## Getting Started
See the [Development Environment](Development.md) guide for instructions on setting up your development environment and the [Deployment Guide](Deployment.md) for deployment options.

## License
This project is proprietary and confidential.
