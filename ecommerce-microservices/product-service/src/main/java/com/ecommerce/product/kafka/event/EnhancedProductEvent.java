package com.ecommerce.product.kafka.event;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Enhanced product event that captures detailed user interaction data.
 * This model supports comprehensive real-time analytics and event processing,
 * demonstrating advanced streaming capabilities for enterprise applications.
 */
@Data
@AllArgsConstructor
@NoArgsConstructor
public class EnhancedProductEvent {
    // Event common properties
    private String eventId;
    private String eventType; // VIEW, SEARCH, PURCHASE, REVIEW, ADD_TO_CART, etc.
    private Long productId;
    private String productName;
    private String userId;
    private LocalDateTime timestamp;
    
    // Additional metadata for advanced analytics
    private String userAgent;
    private String ipAddress;
    private String sessionId;
    private String referrer;
    
    // Optional properties for specific event types
    private Integer quantity; // For purchases
    private Double price;     // For purchases
    private Integer rating;   // For reviews
    private String comment;   // For reviews
    private Integer viewDurationSeconds; // For views
    
    /**
     * Converts this enhanced event to the standard product event format
     * to maintain backward compatibility with existing systems.
     * This demonstrates proper enterprise integration patterns.
     */
    public ProductEvent toStandardEvent() {
        ProductEvent standardEvent = new ProductEvent();
        standardEvent.setProductId(this.productId);
        standardEvent.setEventType(this.eventType);
        standardEvent.setTimestamp(this.timestamp);
        return standardEvent;
    }
}
