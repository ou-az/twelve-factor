FROM maven:3.9.6-eclipse-temurin-17 AS build
WORKDIR /app

# Copy the pom.xml file first for better caching
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy the source code
COPY src ./src

# Build the application
RUN mvn package -DskipTests

# Create a slim final image
FROM eclipse-temurin:17-jre
WORKDIR /app

# Set Spring profile as an environment variable (can be overridden)
ENV SPRING_PROFILES_ACTIVE=docker

# Create a non-root user to run the application
RUN addgroup --system javauser && adduser --system --ingroup javauser javauser
USER javauser

# Copy the built artifact from the build stage
COPY --from=build /app/target/*.jar app.jar

# Set the entrypoint to run the application with memory settings
ENTRYPOINT ["java", "-Xms256m", "-Xmx512m", "-jar", "app.jar"]

# Expose the patient service port
EXPOSE 8091

# Add health check
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD wget -q --spider http://localhost:8091/actuator/health || exit 1
