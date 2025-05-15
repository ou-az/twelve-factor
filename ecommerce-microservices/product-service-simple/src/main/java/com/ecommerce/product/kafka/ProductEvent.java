package com.ecommerce.product.kafka;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class ProductEvent {
    // Event common properties
    private String eventId;
    private String eventType; // VIEW, SEARCH, PURCHASE, REVIEW, ADD_TO_CART, etc.
    private Long productId;
    private String productName;
    private String userId;
    private LocalDateTime timestamp;
    
    // Additional metadata
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
}
