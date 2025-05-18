# Getting Started with Healthcare SOA Project

This guide will help you set up and run the Healthcare Information Exchange SOA project from scratch.

## Prerequisites

- Java 17+
- Maven 3.8+ or Gradle 7.5+
- Docker and Docker Compose
- Git
- AWS CLI (for deployment)
- MuleSoft Anypoint Platform account
- PostgreSQL, MongoDB, and Redis (local or containerized)

## Initial Setup

1. **Clone the repository**

```bash
git clone https://github.com/your-org/healthcare-soa.git
cd healthcare-soa
```

2. **Set up environment variables**

Create a `.env` file in the project root with the following variables:

```
# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=securepassword
PATIENT_DB_NAME=patient_db
PROVIDER_DB_NAME=provider_db
APPOINTMENT_DB_NAME=appointment_db
AUTH_DB_NAME=auth_db
AUDIT_DB_NAME=audit_db

# MongoDB Configuration
MONGO_HOST=localhost
MONGO_PORT=27017
MONGO_USER=mongouser
MONGO_PASSWORD=mongopassword

# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=redispassword

# Kafka Configuration
KAFKA_BOOTSTRAP_SERVERS=localhost:9092

# MuleSoft ESB Configuration
MULE_CLIENT_ID=your-client-id
MULE_CLIENT_SECRET=your-client-secret
MULE_API_URL=https://anypoint.mulesoft.com/api

# Security
JWT_SECRET=your-jwt-secret-key
JWT_EXPIRATION_MS=86400000
```

3. **Start infrastructure services with Docker Compose**

```bash
docker-compose up -d
```

## Project Structure

The project follows a modular structure with each service in its own directory:

```
healthcare-soa/
├── esb/                    # MuleSoft ESB configuration
├── patient-service/        # Patient management service
├── provider-service/       # Provider management service
├── appointment-service/    # Appointment scheduling service
├── auth-service/           # Authentication service
├── audit-service/          # Audit logging service
├── analytics-service/      # Analytics and reporting service
├── api-gateway/            # API Gateway configuration
├── common/                 # Shared libraries and utilities
├── config/                 # Configuration files
├── deployment/             # Deployment scripts and configurations
│   ├── docker/             # Docker configurations
│   ├── kubernetes/         # K8s manifests
│   └── terraform/          # Infrastructure as Code
└── docs/                   # Project documentation
```

## Building Services

To build all services:

```bash
./mvnw clean install
```

To build a specific service:

```bash
cd patient-service
../mvnw clean install
```

## Running Locally

1. **Start infrastructure services**

```bash
docker-compose up -d mongodb postgres redis kafka
```

2. **Start the ESB**

```bash
cd esb
../mvnw spring-boot:run
```

3. **Start individual services**

In separate terminals:

```bash
# Start Authentication Service
cd auth-service
../mvnw spring-boot:run -Dspring.profiles.active=local

# Start Patient Service
cd patient-service
../mvnw spring-boot:run -Dspring.profiles.active=local

# Repeat for other services
```

## Service Implementation Steps

### 1. Define Service Interface

Each service should define a clear interface in its API module:

```java
// patient-service/patient-api/src/main/java/com/healthcare/patient/api/PatientService.java
package com.healthcare.patient.api;

import java.util.List;
import java.util.Optional;

public interface PatientService {
    Patient createPatient(Patient patient);
    Optional<Patient> getPatientById(String id);
    List<Patient> findPatientsByName(String name);
    Patient updatePatient(String id, Patient patient);
    void deletePatient(String id);
}
```

### 2. Implement Domain Model

Create JPA entities and DTOs:

```java
// patient-service/patient-domain/src/main/java/com/healthcare/patient/domain/PatientEntity.java
@Entity
@Table(name = "patients")
public class PatientEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;
    
    @Column(nullable = false)
    private String firstName;
    
    @Column(nullable = false)
    private String lastName;
    
    @Column(nullable = false, unique = true)
    private String mrn;
    
    @Column
    private LocalDate dateOfBirth;
    
    // Additional fields, getters, setters
}
```

### 3. Implement Repository Layer

Create Spring Data repositories:

```java
// patient-service/patient-data/src/main/java/com/healthcare/patient/data/PatientRepository.java
@Repository
public interface PatientRepository extends JpaRepository<PatientEntity, String> {
    List<PatientEntity> findByLastNameContainingIgnoreCase(String lastName);
    Optional<PatientEntity> findByMrn(String mrn);
}
```

### 4. Implement Service Layer

Implement business logic:

```java
// patient-service/patient-service/src/main/java/com/healthcare/patient/service/PatientServiceImpl.java
@Service
@Transactional
public class PatientServiceImpl implements PatientService {
    private final PatientRepository patientRepository;
    private final PatientMapper patientMapper;
    
    // Constructor injection
    
    @Override
    public Patient createPatient(Patient patient) {
        validatePatient(patient);
        PatientEntity entity = patientMapper.toEntity(patient);
        PatientEntity saved = patientRepository.save(entity);
        return patientMapper.toDto(saved);
    }
    
    // Other methods
}
```

### 5. Implement REST Controllers

Create RESTful endpoints:

```java
// patient-service/patient-web/src/main/java/com/healthcare/patient/web/PatientController.java
@RestController
@RequestMapping("/api/patients")
public class PatientController {
    private final PatientService patientService;
    
    // Constructor injection
    
    @PostMapping
    public ResponseEntity<Patient> createPatient(@Valid @RequestBody Patient patient) {
        Patient created = patientService.createPatient(patient);
        return ResponseEntity
            .created(URI.create("/api/patients/" + created.getId()))
            .body(created);
    }
    
    // Other endpoints
}
```

### 6. Configure Messaging

Implement event publishing with Kafka:

```java
// patient-service/patient-messaging/src/main/java/com/healthcare/patient/messaging/PatientEventPublisher.java
@Component
public class PatientEventPublisher {
    private final KafkaTemplate<String, PatientEvent> kafkaTemplate;
    
    // Constructor injection
    
    public void publishPatientCreated(Patient patient) {
        PatientEvent event = new PatientEvent(
            "PATIENT_CREATED",
            patient.getId(),
            LocalDateTime.now(),
            patient
        );
        
        kafkaTemplate.send("patient-events", patient.getId(), event);
    }
}
```

## Testing

### Unit Testing

```bash
./mvnw test
```

### Integration Testing

```bash
./mvnw verify
```

### End-to-End Testing

```bash
cd e2e-tests
../mvnw test -Pe2e
```

## Deployment

### Local Kubernetes Deployment

```bash
# Apply configuration
kubectl apply -f deployment/kubernetes/config-maps.yaml
kubectl apply -f deployment/kubernetes/secrets.yaml

# Deploy services
kubectl apply -f deployment/kubernetes/services/
```

### AWS Deployment

```bash
# Configure AWS credentials
aws configure

# Deploy with Terraform
cd deployment/terraform
terraform init
terraform apply
```

## Monitoring

- Access Prometheus: http://localhost:9090
- Access Grafana: http://localhost:3000
- Access Kibana: http://localhost:5601

## Documentation

- API documentation: http://localhost:8080/swagger-ui.html
- Admin dashboard: http://localhost:8080/admin

## Next Steps

1. Complete the base Patient Service implementation
2. Set up the Authentication Service
3. Implement the ESB configuration
4. Add integration between services
5. Implement FHIR compliance
6. Set up CI/CD pipeline
