package com.healthcare.appointment;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.web.client.RestTemplate;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;

@SpringBootApplication
public class AppointmentServiceApplication {

    private static final Logger logger = LoggerFactory.getLogger(AppointmentServiceApplication.class);

    @Value("${server.port}")
    private String serverPort;

    public static void main(String[] args) {
        SpringApplication.run(AppointmentServiceApplication.class, args);
    }
    
    @Bean
    public CommandLineRunner logApplicationStartup() {
        return args -> {
            logger.info("Appointment service successfully started on port {}", serverPort);
            logger.info("Healthcare SOA - Appointment Service is ready!");
            logger.info("API Documentation available at: http://localhost:{}/swagger-ui.html", serverPort);
            logger.info("Using databases: PostgreSQL, MongoDB, and Redis for different data needs");
        };
    }
    
    @Bean
    public RestTemplate restTemplate() {
        return new RestTemplate();
    }
    
    @Bean
    @ConditionalOnProperty(name = "springdoc.api-docs.enabled", havingValue = "true", matchIfMissing = true)
    public OpenAPI customOpenAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("Appointment Service API")
                        .version("1.0")
                        .description("API for appointment management in Healthcare SOA"));
    }
}
