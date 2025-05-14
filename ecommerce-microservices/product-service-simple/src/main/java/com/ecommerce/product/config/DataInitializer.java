package com.ecommerce.product.config;

import com.ecommerce.product.model.Product;
import com.ecommerce.product.repository.ProductRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Arrays;

/**
 * This class initializes sample data for the product service
 * to demonstrate functionality without requiring external services.
 */
@Configuration
@RequiredArgsConstructor
@Slf4j
public class DataInitializer {

    private final ProductRepository productRepository;

    @Bean
    public CommandLineRunner initData() {
        return args -> {
            // Only initialize if the repository is empty
            if (productRepository.count() == 0) {
                log.info("Initializing sample product data");
                
                LocalDateTime now = LocalDateTime.now();
                
                Product[] products = {
                    Product.builder()
                        .name("Enterprise Java Development Book")
                        .description("Comprehensive guide to Java enterprise development, covering Spring Boot, Microservices, and Cloud deployment")
                        .price(new BigDecimal("49.99"))
                        .imageUrl("https://example.com/images/java-book.jpg")
                        .categoryId(1L)
                        .stockQuantity(50)
                        .createdAt(now)
                        .updatedAt(now)
                        .build(),
                        
                    Product.builder()
                        .name("Microservices Architecture Course")
                        .description("Online course covering microservices patterns, event-driven architecture, and implementation with Spring Boot")
                        .price(new BigDecimal("199.99"))
                        .imageUrl("https://example.com/images/microservices-course.jpg")
                        .categoryId(2L)
                        .stockQuantity(100)
                        .createdAt(now)
                        .updatedAt(now)
                        .build(),
                        
                    Product.builder()
                        .name("Kafka in Action")
                        .description("Practical guide to implementing event streaming with Apache Kafka in enterprise applications")
                        .price(new BigDecimal("39.99"))
                        .imageUrl("https://example.com/images/kafka-book.jpg")
                        .categoryId(1L)
                        .stockQuantity(30)
                        .createdAt(now)
                        .updatedAt(now)
                        .build(),
                        
                    Product.builder()
                        .name("Cloud Engineering Certification")
                        .description("Certification program for AWS/Azure cloud platforms with focus on containerization and infrastructure-as-code")
                        .price(new BigDecimal("299.99"))
                        .imageUrl("https://example.com/images/cloud-cert.jpg")
                        .categoryId(3L)
                        .stockQuantity(15)
                        .createdAt(now)
                        .updatedAt(now)
                        .build(),
                        
                    Product.builder()
                        .name("DevOps Toolkit")
                        .description("Comprehensive set of tools and guides for implementing CI/CD pipelines and DevOps practices")
                        .price(new BigDecimal("149.99"))
                        .imageUrl("https://example.com/images/devops-toolkit.jpg")
                        .categoryId(4L)
                        .stockQuantity(25)
                        .createdAt(now)
                        .updatedAt(now)
                        .build(),
                };
                
                productRepository.saveAll(Arrays.asList(products));
                log.info("Initialized {} sample products", products.length);
            }
        };
    }
}
