package com.healthcare.patient;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;

@SpringBootApplication
public class PatientServiceApplication {
    
    private static final Logger logger = LoggerFactory.getLogger(PatientServiceApplication.class);

    @Value("${server.port}")
    private String serverPort;

    public static void main(String[] args) {
        SpringApplication.run(PatientServiceApplication.class, args);
    }
    
    @Bean
    public CommandLineRunner logApplicationStartup() {
        return args -> {
            logger.info("Patient service successfully started on port {}", serverPort);
            logger.info("Healthcare SOA - Patient Service is ready!");
            logger.info("API Documentation available at: http://localhost:{}/swagger-ui.html", serverPort);
        };
    }
    
    @Bean
    @ConditionalOnProperty(name = "springdoc.api-docs.enabled", havingValue = "true", matchIfMissing = true)
    public OpenAPI customOpenAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("Patient Service API")
                        .version("1.0")
                        .description("API for patient management in Healthcare SOA"));
    }
}
