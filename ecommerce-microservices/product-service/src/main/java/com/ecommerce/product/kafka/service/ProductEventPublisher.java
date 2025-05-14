package com.ecommerce.product.kafka.service;

import com.ecommerce.product.kafka.event.ProductEvent;
import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import io.github.resilience4j.retry.annotation.Retry;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;
import org.springframework.stereotype.Service;

import java.util.concurrent.CompletableFuture;

@Slf4j
@Service
@RequiredArgsConstructor
public class ProductEventPublisher {

    private final KafkaTemplate<String, ProductEvent> kafkaTemplate;

    @Value("${spring.kafka.topics.product-created}")
    private String productCreatedTopic;

    @Value("${spring.kafka.topics.product-updated}")
    private String productUpdatedTopic;

    @Value("${spring.kafka.topics.product-deleted}")
    private String productDeletedTopic;

    @Value("${spring.kafka.topics.inventory-updated}")
    private String inventoryUpdatedTopic;

    @CircuitBreaker(name = "kafkaPublisher", fallbackMethod = "fallbackPublish")
    @Retry(name = "kafkaPublisher")
    public CompletableFuture<SendResult<String, ProductEvent>> publishProductEvent(ProductEvent event) {
        String topic = determineTopic(event.getEventType());
        String key = event.getProductId().toString();
        
        log.info("Publishing event to topic {}: {}", topic, event);
        
        return kafkaTemplate.send(topic, key, event)
                .completable()
                .whenComplete((result, ex) -> {
                    if (ex != null) {
                        log.error("Failed to send message to topic {}: {}", topic, ex.getMessage(), ex);
                    } else {
                        log.info("Message sent successfully to topic {}: offset=[{}]", 
                                 topic, result.getRecordMetadata().offset());
                    }
                });
    }
    
    private String determineTopic(String eventType) {
        return switch (eventType) {
            case "PRODUCT_CREATED" -> productCreatedTopic;
            case "PRODUCT_UPDATED" -> productUpdatedTopic;
            case "PRODUCT_DELETED" -> productDeletedTopic;
            case "PRODUCT_INVENTORY_UPDATED" -> inventoryUpdatedTopic;
            default -> throw new IllegalArgumentException("Unknown event type: " + eventType);
        };
    }
    
    private CompletableFuture<SendResult<String, ProductEvent>> fallbackPublish(ProductEvent event, Throwable ex) {
        log.error("Circuit breaker triggered for publishing event: {}", event, ex);
        // Implement fallback strategy - e.g. save to a database for later retry or send to a dead letter queue
        // Here just returning a failed future for simplicity
        CompletableFuture<SendResult<String, ProductEvent>> future = new CompletableFuture<>();
        future.completeExceptionally(ex);
        return future;
    }
}
