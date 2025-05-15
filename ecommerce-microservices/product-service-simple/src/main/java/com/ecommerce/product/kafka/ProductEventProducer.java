package com.ecommerce.product.kafka;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;
import org.springframework.stereotype.Service;

import java.util.UUID;
import java.util.concurrent.CompletableFuture;

@Service
@RequiredArgsConstructor
@Slf4j
public class ProductEventProducer {

    private final KafkaTemplate<String, Object> kafkaTemplate;

    /**
     * Publishes a product event to Kafka
     * 
     * @param event The product event to publish
     * @return CompletableFuture of the send result
     */
    public CompletableFuture<SendResult<String, Object>> publishProductEvent(ProductEvent event) {
        String key = event.getProductId() != null ? event.getProductId().toString() : UUID.randomUUID().toString();
        
        log.info("Publishing {} event for product {}: {}", 
                event.getEventType(), event.getProductId(), event.getProductName());
        
        return kafkaTemplate.send(KafkaConfig.PRODUCT_EVENTS_TOPIC, key, event)
                .whenComplete((result, ex) -> {
                    if (ex == null) {
                        log.debug("Event sent successfully: {} [partition: {}, offset: {}]", 
                                event.getEventId(), 
                                result.getRecordMetadata().partition(),
                                result.getRecordMetadata().offset());
                    } else {
                        log.error("Failed to send event: " + event.getEventId(), ex);
                    }
                });
    }
}
