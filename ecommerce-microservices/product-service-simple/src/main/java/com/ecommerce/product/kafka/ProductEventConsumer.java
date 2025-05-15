package com.ecommerce.product.kafka;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.KafkaHeaders;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Service;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * Consumes product events from Kafka and processes them.
 * This demonstrates event stream processing capabilities for real-time analytics.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ProductEventConsumer {
    
    // In-memory analytics store (in a real app, would use Redis/Cassandra/etc.)
    private final Map<String, AtomicInteger> eventTypeCounter = new ConcurrentHashMap<>();
    private final Map<Long, AtomicInteger> productViewCounter = new ConcurrentHashMap<>();
    private final Map<String, AtomicInteger> userActivityCounter = new ConcurrentHashMap<>();
    
    /**
     * Listens for product events and processes them in real-time.
     * This demonstrates streaming data processing capabilities.
     */
    @KafkaListener(
            topics = "#{kafkaConfig.PRODUCT_EVENTS_TOPIC}",
            containerFactory = "kafkaListenerContainerFactory"
    )
    public void processProductEvent(
            @Payload ProductEvent event,
            @Header(KafkaHeaders.RECEIVED_PARTITION) int partition,
            @Header(KafkaHeaders.OFFSET) long offset
    ) {
        log.info("Received event: type={}, product={}, user={}, partition={}, offset={}",
                event.getEventType(), event.getProductName(), event.getUserId(), partition, offset);
        
        // Update event type statistics
        eventTypeCounter.computeIfAbsent(event.getEventType(), k -> new AtomicInteger(0))
                .incrementAndGet();
        
        // Update product popularity statistics
        if ("VIEW".equals(event.getEventType())) {
            productViewCounter.computeIfAbsent(event.getProductId(), k -> new AtomicInteger(0))
                    .incrementAndGet();
        }
        
        // Update user activity statistics
        userActivityCounter.computeIfAbsent(event.getUserId(), k -> new AtomicInteger(0))
                .incrementAndGet();
        
        // Perform event-specific processing
        switch (event.getEventType()) {
            case "PURCHASE":
                processPurchaseEvent(event);
                break;
            case "VIEW":
                processViewEvent(event);
                break;
            case "REVIEW":
                processReviewEvent(event);
                break;
            default:
                log.debug("No special processing for event type: {}", event.getEventType());
        }
        
        // Log analytics every 50 events for a specific event type
        int count = eventTypeCounter.get(event.getEventType()).get();
        if (count % 50 == 0) {
            logCurrentStatistics();
        }
    }
    
    private void processPurchaseEvent(ProductEvent event) {
        log.info("PURCHASE: User {} bought {} units of {} for ${} each",
                event.getUserId(), event.getQuantity(), event.getProductName(), event.getPrice());
    }
    
    private void processViewEvent(ProductEvent event) {
        log.info("VIEW: User {} viewed {} for {} seconds, referred from {}",
                event.getUserId(), event.getProductName(), event.getViewDurationSeconds(), event.getReferrer());
    }
    
    private void processReviewEvent(ProductEvent event) {
        log.info("REVIEW: User {} rated {} with {} stars",
                event.getUserId(), event.getProductName(), event.getRating());
    }
    
    /**
     * Logs current analytics data to demonstrate real-time statistics computation.
     */
    private void logCurrentStatistics() {
        log.info("===== REAL-TIME ANALYTICS =====");
        
        log.info("Event Type Counts:");
        eventTypeCounter.forEach((type, count) -> 
                log.info("  {} events: {}", type, count.get()));
        
        log.info("Top 3 Viewed Products:");
        productViewCounter.entrySet().stream()
                .sorted((e1, e2) -> e2.getValue().get() - e1.getValue().get())
                .limit(3)
                .forEach(entry -> log.info("  Product ID {}: {} views", entry.getKey(), entry.getValue().get()));
        
        log.info("Most Active Users:");
        userActivityCounter.entrySet().stream()
                .sorted((e1, e2) -> e2.getValue().get() - e1.getValue().get())
                .limit(3)
                .forEach(entry -> log.info("  User {}: {} activities", entry.getKey(), entry.getValue().get()));
        
        log.info("===============================");
    }
}
