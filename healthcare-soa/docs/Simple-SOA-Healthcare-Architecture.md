# Simple SOA Healthcare Architecture with MuleSoft ESB and Spring Boot

This document outlines a simplified Service-Oriented Architecture (SOA) for a healthcare system using MuleSoft ESB as the integration hub and Spring Boot microservices as the core components.

## Architecture Overview

```
+----------------------+      +------------------------+      +----------------------+
|                      |      |                        |      |                      |
|   Patient Service    +------+      MuleSoft ESB      +------+  Appointment Service |
|   (Spring Boot)     |      |  (Integration Hub)     |      |    (Spring Boot)     |
|                      |      |                        |      |                      |
+----------+-----------+      +------------------------+      +----------+-----------+
           |                                                              |
           |                                                              |
           v                                                              v
+----------+-----------+                                      +----------+-----------+
|                      |                                      |                      |
|     PostgreSQL       |                                      |        Redis         |
|                      |                                      |                      |
+----------------------+                                      +----------------------+
                                   +------------------------+
                                   |                        |
                                   |        MongoDB         |
                                   |                        |
                                   +------------------------+
```

Our simplified healthcare SOA consists of:

1. **MuleSoft ESB** - Central integration hub
2. **Patient Service** - Spring Boot application for patient management
3. **Appointment Service** - Spring Boot application for scheduling appointments
4. **Supporting Infrastructure** - PostgreSQL, MongoDB, and Redis

## Docker Services Setup

### 1. MuleSoft ESB

The MuleSoft ESB serves as the central integration point, managing API traffic, transformations, and service orchestration.

```yaml
esb:
  image: vromero/mule:3.8.0
  container_name: healthcare-esb
  ports:
    - "8081:8081"  # HTTP
    - "8082:8082"  # HTTPS
  volumes:
    - ./esb/apps/health-check-app:/opt/mule/apps/health-check-app
    - ./esb/domains/default:/opt/mule/domains/default
  environment:
    - MULE_ENV=local
  networks:
    - healthcare-network
  restart: unless-stopped
```

### 2. Spring Boot Microservices

#### Patient Service

```yaml
patient-service:
  build:
    context: ./services/patient-service
    dockerfile: Dockerfile
  container_name: healthcare-patient-service
  ports:
    - "8091:8091"
  environment:
    - SPRING_PROFILES_ACTIVE=docker
    - SPRING_DATASOURCE_URL=jdbc:postgresql://postgres:5432/healthcare_patient
    - SPRING_DATASOURCE_USERNAME=healthcare_user
    - SPRING_DATASOURCE_PASSWORD=healthcare_password
    - MULE_ESB_URL=http://esb:8081
  depends_on:
    - postgres
    - esb
  networks:
    - healthcare-network
```

#### Appointment Service

```yaml
appointment-service:
  build:
    context: ./services/appointment-service
    dockerfile: Dockerfile
  container_name: healthcare-appointment-service
  ports:
    - "8092:8092"
  environment:
    - SPRING_PROFILES_ACTIVE=docker
    - SPRING_DATASOURCE_URL=jdbc:postgresql://postgres:5432/healthcare_appointment
    - SPRING_DATASOURCE_USERNAME=healthcare_user
    - SPRING_DATASOURCE_PASSWORD=healthcare_password
    - SPRING_DATA_MONGODB_URI=mongodb://mongodb:27017/healthcare_appointment
    - SPRING_REDIS_HOST=redis
    - SPRING_REDIS_PORT=6379
    - MULE_ESB_URL=http://esb:8081
  depends_on:
    - postgres
    - mongodb
    - redis
    - esb
  networks:
    - healthcare-network
```

### 3. Supporting Infrastructure

```yaml
postgres:
  image: postgres:13
  container_name: healthcare-postgres
  ports:
    - "5432:5432"
  environment:
    - POSTGRES_USER=healthcare_user
    - POSTGRES_PASSWORD=healthcare_password
    - POSTGRES_MULTIPLE_DATABASES=healthcare_patient,healthcare_appointment
  volumes:
    - ./init-scripts:/docker-entrypoint-initdb.d
    - postgres-data:/var/lib/postgresql/data
  networks:
    - healthcare-network

mongodb:
  image: mongo:5.0
  container_name: healthcare-mongodb
  ports:
    - "27017:27017"
  volumes:
    - mongo-data:/data/db
  networks:
    - healthcare-network

redis:
  image: redis:6.2
  container_name: healthcare-redis
  ports:
    - "6379:6379"
  networks:
    - healthcare-network

volumes:
  postgres-data:
  mongo-data:

networks:
  healthcare-network:
    driver: bridge
```

## Spring Boot Service Implementation

### Patient Service

The Patient Service manages patient information and provides APIs for patient registration, updates, and retrieval.

#### Key Features:
- Patient registration and profile management
- Medical history tracking
- Patient search functionality
- Insurance information management

#### Dependencies:
```xml
<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-data-jpa</artifactId>
    </dependency>
    <dependency>
        <groupId>org.postgresql</groupId>
        <artifactId>postgresql</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-validation</artifactId>
    </dependency>
    <dependency>
        <groupId>org.projectlombok</groupId>
        <artifactId>lombok</artifactId>
    </dependency>
</dependencies>
```

#### Sample Controller:
```java
@RestController
@RequestMapping("/api/patients")
public class PatientController {

    private final PatientService patientService;

    @Autowired
    public PatientController(PatientService patientService) {
        this.patientService = patientService;
    }

    @GetMapping("/{id}")
    public ResponseEntity<PatientDTO> getPatient(@PathVariable Long id) {
        return ResponseEntity.ok(patientService.getPatientById(id));
    }

    @PostMapping
    public ResponseEntity<PatientDTO> createPatient(@Valid @RequestBody PatientDTO patientDTO) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(patientService.createPatient(patientDTO));
    }

    @PutMapping("/{id}")
    public ResponseEntity<PatientDTO> updatePatient(
            @PathVariable Long id, 
            @Valid @RequestBody PatientDTO patientDTO) {
        return ResponseEntity.ok(patientService.updatePatient(id, patientDTO));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deletePatient(@PathVariable Long id) {
        patientService.deletePatient(id);
        return ResponseEntity.noContent().build();
    }
}
```

### Appointment Service

The Appointment Service handles scheduling, managing, and tracking patient appointments.

#### Key Features:
- Appointment scheduling and management
- Calendar integration
- Notifications for appointments
- Check-in/check-out tracking

#### Dependencies:
```xml
<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-data-jpa</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-data-mongodb</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-data-redis</artifactId>
    </dependency>
    <dependency>
        <groupId>org.postgresql</groupId>
        <artifactId>postgresql</artifactId>
    </dependency>
    <dependency>
        <groupId>org.projectlombok</groupId>
        <artifactId>lombok</artifactId>
    </dependency>
</dependencies>
```

#### Sample Controller:
```java
@RestController
@RequestMapping("/api/appointments")
public class AppointmentController {

    private final AppointmentService appointmentService;

    @Autowired
    public AppointmentController(AppointmentService appointmentService) {
        this.appointmentService = appointmentService;
    }

    @GetMapping("/{id}")
    public ResponseEntity<AppointmentDTO> getAppointment(@PathVariable String id) {
        return ResponseEntity.ok(appointmentService.getAppointmentById(id));
    }

    @GetMapping("/patient/{patientId}")
    public ResponseEntity<List<AppointmentDTO>> getPatientAppointments(@PathVariable Long patientId) {
        return ResponseEntity.ok(appointmentService.getAppointmentsByPatientId(patientId));
    }

    @PostMapping
    public ResponseEntity<AppointmentDTO> scheduleAppointment(@Valid @RequestBody AppointmentDTO appointmentDTO) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(appointmentService.scheduleAppointment(appointmentDTO));
    }

    @PutMapping("/{id}")
    public ResponseEntity<AppointmentDTO> updateAppointment(
            @PathVariable String id, 
            @Valid @RequestBody AppointmentDTO appointmentDTO) {
        return ResponseEntity.ok(appointmentService.updateAppointment(id, appointmentDTO));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> cancelAppointment(@PathVariable String id) {
        appointmentService.cancelAppointment(id);
        return ResponseEntity.noContent().build();
    }
}
```

## MuleSoft ESB Integration

MuleSoft ESB acts as the central integration hub, providing:

1. **API Gateway** - Exposing a unified API to external clients
2. **Service Orchestration** - Coordinating workflows that span multiple services
3. **Data Transformation** - Converting data formats between services
4. **Security** - Providing authentication and authorization

### MuleSoft API Gateway Flow

```xml
<mule xmlns="http://www.mulesoft.org/schema/mule/core"
      xmlns:http="http://www.mulesoft.org/schema/mule/http"
      xmlns:ee="http://www.mulesoft.org/schema/mule/ee/core"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:schemaLocation="
        http://www.mulesoft.org/schema/mule/core http://www.mulesoft.org/schema/mule/core/current/mule.xsd
        http://www.mulesoft.org/schema/mule/http http://www.mulesoft.org/schema/mule/http/current/mule-http.xsd
        http://www.mulesoft.org/schema/mule/ee/core http://www.mulesoft.org/schema/mule/ee/core/current/mule-ee.xsd">

    <http:listener-config name="HTTP_Listener_config" host="0.0.0.0" port="8081" />
    <http:request-config name="Patient_Service_Request_config" host="patient-service" port="8091" />
    <http:request-config name="Appointment_Service_Request_config" host="appointment-service" port="8092" />

    <!-- Patient API Gateway -->
    <flow name="patient-api-flow">
        <http:listener config-ref="HTTP_Listener_config" path="/api/v1/patients/*" />
        <http:request config-ref="Patient_Service_Request_config" path="/api/patients/{path}" method="#[attributes.method]">
            <http:uri-params>
                <![CDATA[#[output application/java
                ---
                {
                    "path": attributes.uriParams.path
                }]]]>
            </http:uri-params>
            <http:headers>
                <![CDATA[#[output application/java
                ---
                attributes.headers]]]>
            </http:headers>
            <http:query-params>
                <![CDATA[#[output application/java
                ---
                attributes.queryParams]]]>
            </http:query-params>
        </http:request>
    </flow>

    <!-- Appointment API Gateway -->
    <flow name="appointment-api-flow">
        <http:listener config-ref="HTTP_Listener_config" path="/api/v1/appointments/*" />
        <http:request config-ref="Appointment_Service_Request_config" path="/api/appointments/{path}" method="#[attributes.method]">
            <http:uri-params>
                <![CDATA[#[output application/java
                ---
                {
                    "path": attributes.uriParams.path
                }]]]>
            </http:uri-params>
            <http:headers>
                <![CDATA[#[output application/java
                ---
                attributes.headers]]]>
            </http:headers>
            <http:query-params>
                <![CDATA[#[output application/java
                ---
                attributes.queryParams]]]>
            </http:query-params>
        </http:request>
    </flow>

    <!-- Combined Service Orchestration -->
    <flow name="schedule-patient-appointment-flow">
        <http:listener config-ref="HTTP_Listener_config" path="/api/v1/patient-appointments" method="POST" />
        
        <!-- Extract Patient ID from request -->
        <set-variable variableName="patientId" value="#[payload.patientId]" />
        
        <!-- Verify patient exists -->
        <http:request config-ref="Patient_Service_Request_config" 
                      path="/api/patients/#[vars.patientId]" 
                      method="GET" />
        
        <!-- Schedule appointment -->
        <http:request config-ref="Appointment_Service_Request_config" 
                      path="/api/appointments" 
                      method="POST" />
                      
        <!-- Return response -->
        <ee:transform>
            <ee:message>
                <ee:set-payload><![CDATA[%dw 2.0
                output application/json
                ---
                {
                    "status": "SUCCESS",
                    "message": "Appointment scheduled successfully",
                    "appointmentDetails": payload
                }]]></ee:set-payload>
            </ee:message>
        </ee:transform>
    </flow>
</mule>
```

## Deployment Steps

1. **Clone the project repository**
   ```bash
   git clone https://github.com/healthcare-org/healthcare-soa.git
   cd healthcare-soa
   ```

2. **Build the Spring Boot microservices**
   ```bash
   cd services/patient-service
   ./mvnw clean package
   cd ../appointment-service
   ./mvnw clean package
   cd ../..
   ```

3. **Start the Docker containers**
   ```bash
   docker-compose up -d
   ```

4. **Verify the deployment**
   ```bash
   # Check running containers
   docker ps
   
   # Test MuleSoft health check
   curl http://localhost:8081/api/health
   
   # Test Patient Service (via MuleSoft ESB)
   curl http://localhost:8081/api/v1/patients
   
   # Test Appointment Service (via MuleSoft ESB)
   curl http://localhost:8081/api/v1/appointments
   ```

## Conclusion

This simplified SOA architecture demonstrates how MuleSoft ESB can serve as an integration hub for Spring Boot microservices in a healthcare context. The architecture is containerized using Docker, making it easy to deploy and scale.

By implementing this architecture, healthcare organizations can achieve:

1. **Modularity** - Services are developed and deployed independently
2. **Interoperability** - MuleSoft ESB facilitates seamless communication
3. **Scalability** - Docker containers allow for flexible scaling
4. **Maintainability** - Clear separation of concerns simplifies maintenance

This architecture can be extended by adding more specialized microservices as needed for a complete healthcare information system.
