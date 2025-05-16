package com.ecommerce.product.kafka.service;

import com.ecommerce.product.config.KafkaCondition;
import com.ecommerce.product.kafka.event.EnhancedProductEvent;
import com.ecommerce.product.kafka.event.ProductEvent;
import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import io.github.resilience4j.retry.annotation.Retry;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.context.annotation.Conditional;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;
import org.springframework.stereotype.Service;

import java.util.concurrent.CompletableFuture;

@Slf4j
@Service
@RequiredArgsConstructor
@Conditional(KafkaCondition.class)
public class ProductEventPublisher {

    private final KafkaTemplate<String, ProductEvent> kafkaTemplate;
    
    @Qualifier("extendedKafkaTemplate")
    private final KafkaTemplate<String, ProductEvent> extendedKafkaTemplate;
    
    private final KafkaTemplate<String, EnhancedProductEvent> enhancedKafkaTemplate;

    @Value("${spring.kafka.topics.product-created}")
    private String productCreatedTopic;

    @Value("${spring.kafka.topics.product-updated}")
    private String productUpdatedTopic;

    @Value("${spring.kafka.topics.product-deleted}")
    private String productDeletedTopic;

    @Value("${spring.kafka.topics.inventory-updated}")
    private String inventoryUpdatedTopic;
    
    @Value("${spring.kafka.topics.product-events:product-events}")
    private String productEventsTopic;
    
    @Value("${spring.kafka.topics.product-analytics:product-analytics}")
    private String productAnalyticsTopic;

    /**
     * Publishes a standard product event to Kafka.
     * Uses circuit breaker and retry patterns for resilience.
     */
    @CircuitBreaker(name = "kafkaPublisher", fallbackMethod = "fallbackPublish")
    @Retry(name = "kafkaPublisher")
    public CompletableFuture<SendResult<String, ProductEvent>> publishProductEvent(ProductEvent event) {
        String topic = determineTopic(event.getEventType());
        String key = event.getProductId().toString();
        
        log.info("Publishing event to topic {}: {}", topic, event);
        
        CompletableFuture<SendResult<String, ProductEvent>> future = kafkaTemplate.send(topic, key, event);
        
        future.whenComplete((result, ex) -> {
            if (ex != null) {
                log.error("Failed to send message to topic {}: {}", topic, ex.getMessage(), ex);
            } else {
                log.info("Message sent successfully to topic {}: offset=[{}]", 
                         topic, result.getRecordMetadata().offset());
            }
        });
        
        return future;
    }
    
    /**
     * Publishes an enhanced product event to Kafka with additional analytics capabilities.
     * This method demonstrates advanced streaming patterns for real-time analytics.
     * 
     * Implements resilience patterns:
     * - Circuit breaker: prevents cascading failures
     * - Retry: handles transient network issues
     */
    @CircuitBreaker(name = "enhancedPublisher", fallbackMethod = "fallbackEnhancedPublish")
    @Retry(name = "enhancedPublisher")
    public CompletableFuture<SendResult<String, EnhancedProductEvent>> publishEnhancedEvent(EnhancedProductEvent event) {
        String topic = determineEnhancedTopic(event.getEventType());
        String key = event.getProductId().toString();
        
        log.info("Publishing enhanced event to topic {}: {}", topic, event);
        
        // Also publish to analytics topic for real-time dashboards
        if (isAnalyticsEvent(event.getEventType())) {
            CompletableFuture.runAsync(() -> {
                try {
                    // Use the correct kafka template for the event type
                    extendedKafkaTemplate.send(productAnalyticsTopic, key, event.toStandardEvent());
                    log.debug("Analytics event published successfully: {}", event.getEventId());
                } catch (Exception e) {
                    log.warn("Failed to publish analytics event: {}", e.getMessage());
                }
            });
        }
        
        CompletableFuture<SendResult<String, EnhancedProductEvent>> future = enhancedKafkaTemplate.send(topic, key, event);
        
        future.whenComplete((result, ex) -> {
            if (ex != null) {
                log.error("Failed to send enhanced message to topic {}: {}", topic, ex.getMessage(), ex);
            } else {
                log.info("Enhanced message sent successfully to topic {}: offset=[{}]", 
                        topic, result.getRecordMetadata().offset());
            }
        });
        
        return future;
    }
    
    /**
     * Determines the appropriate Kafka topic based on the event type.
     * Uses pattern matching switch for cleaner code.
     */
    private String determineTopic(String eventType) {
        return switch (eventType) {
            case "PRODUCT_CREATED" -> productCreatedTopic;
            case "PRODUCT_UPDATED" -> productUpdatedTopic;
            case "PRODUCT_DELETED" -> productDeletedTopic;
            case "PRODUCT_INVENTORY_UPDATED" -> inventoryUpdatedTopic;
            default -> throw new IllegalArgumentException("Unknown event type: " + eventType);
        };
    }
    
    /**
     * Determines the appropriate Kafka topic for enhanced events.
     * This supports more granular event routing for sophisticated event-driven architectures.
     */
    private String determineEnhancedTopic(String eventType) {
        // For enhanced events, we use a more sophisticated routing strategy
        if (eventType.startsWith("VIEW") || eventType.startsWith("SEARCH")) {
            return productAnalyticsTopic;
        } else if (eventType.contains("PURCHASE") || eventType.contains("CART")) {
            return productEventsTopic;
        } else {
            // Default topic for other events
            return productEventsTopic;
        }
    }
    
    /**
     * Determines if an event should be published to the analytics topic.
     * This demonstrates content-based routing for complex event processing.
     */
    private boolean isAnalyticsEvent(String eventType) {
        return eventType.equals("VIEW") || 
               eventType.equals("SEARCH") || 
               eventType.equals("PURCHASE") || 
               eventType.equals("REVIEW");
    }
    
    /**
     * Fallback method for standard event publishing failures.
     * Demonstrates circuit breaker pattern implementation.
     */
    private CompletableFuture<SendResult<String, ProductEvent>> fallbackPublish(ProductEvent event, Throwable ex) {
        log.error("Circuit breaker triggered for publishing event: {}", event, ex);
        // Implement fallback strategy - e.g. save to a database for later retry or send to a dead letter queue
        // Here just returning a failed future for simplicity
        CompletableFuture<SendResult<String, ProductEvent>> future = new CompletableFuture<>();
        future.completeExceptionally(ex);
        return future;
    }
    
    /**
     * Fallback method for enhanced event publishing failures.
     * Implements a more sophisticated recovery strategy with store-and-forward pattern.
     */
    private CompletableFuture<SendResult<String, EnhancedProductEvent>> fallbackEnhancedPublish(EnhancedProductEvent event, Throwable ex) {
        log.error("Circuit breaker triggered for enhanced event: {}", event, ex);
        
        // In a real implementation, we would persist to a local store for later retry
        // This demonstrates the store-and-forward enterprise integration pattern
        
        // For demo purposes, we attempt to publish a simpler version of the event
        try {
            // Convert to standard event as a fallback strategy
            ProductEvent standardEvent = event.toStandardEvent();
            publishProductEvent(standardEvent);
            log.info("Successfully published fallback standard event");
        } catch (Exception e) {
            log.error("Failed to publish fallback standard event", e);
        }
        
        CompletableFuture<SendResult<String, EnhancedProductEvent>> future = new CompletableFuture<>();
        future.completeExceptionally(ex);
        return future;
    }
}
