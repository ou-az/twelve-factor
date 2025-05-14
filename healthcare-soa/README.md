# Healthcare Information Exchange System (SOA)

This is a Service Oriented Architecture implementation of a Healthcare Information Exchange System built using the twelve-factor application methodology.

## Architecture Overview

This system implements a SOA approach with the following components:
- Enterprise Service Bus (MuleSoft)
- Patient Service
- Provider Service
- Appointment Service
- Authentication Service
- Audit Service
- Analytics Service

## Twelve-Factor Implementation

This codebase follows the twelve-factor principles:

1. **Codebase**: One codebase tracked in Git, deployed to multiple environments
2. **Dependencies**: Explicitly declared and isolated in Maven/Gradle
3. **Config**: Stored in environment variables
4. **Backing Services**: Treated as attached resources
5. **Build, Release, Run**: Strict separation of build and run stages
6. **Processes**: Executed as stateless processes
7. **Port Binding**: Services export via port binding
8. **Concurrency**: Scale out via the process model
9. **Disposability**: Fast startup and graceful shutdown
10. **Dev/Prod Parity**: Keep environments as similar as possible
11. **Logs**: Treat logs as event streams
12. **Admin Processes**: Run admin tasks as one-off processes

## Development Setup

```bash
# Clone the repository
git clone <repository-url>

# Build the project
./mvnw clean install

# Run locally
./mvnw spring-boot:run -Dspring.profiles.active=local
```

## Deployment

This application can be deployed to:
- Development environment
- Staging environment
- Production environment

Using a consistent CI/CD pipeline that builds from the same codebase.
