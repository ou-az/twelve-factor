FROM eclipse-temurin:17-jdk-alpine as build
WORKDIR /workspace/app

# Copy gradle configuration
COPY gradlew .
COPY gradle gradle
COPY build.gradle .
COPY settings.gradle .

# Make gradlew executable
RUN chmod +x gradlew

# Copy source code
COPY src src

# Build the application
RUN ./gradlew build -x test
RUN mkdir -p build/dependency && (cd build/dependency; jar -xf ../libs/*.jar)

# Create a minimal image for running the application
FROM eclipse-temurin:17-jre-alpine
VOLUME /tmp

ARG DEPENDENCY=/workspace/app/build/dependency
COPY --from=build ${DEPENDENCY}/BOOT-INF/lib /app/lib
COPY --from=build ${DEPENDENCY}/META-INF /app/META-INF
COPY --from=build ${DEPENDENCY}/BOOT-INF/classes /app

# Set environment variables from the Kubernetes/ECS configuration
ENV SPRING_PROFILES_ACTIVE=prod
ENV SERVER_PORT=8080

# Expose the application port
EXPOSE 8080

# Set the entry point
ENTRYPOINT ["java","-cp","app:app/lib/*","com.ecommerce.product.ProductServiceApplication"]

# Health check
HEALTHCHECK --interval=30s --timeout=3s --retries=3 CMD wget -q --spider http://localhost:8080/actuator/health || exit 1
