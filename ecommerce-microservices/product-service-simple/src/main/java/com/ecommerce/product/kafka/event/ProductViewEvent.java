package com.ecommerce.product.kafka.event;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class ProductViewEvent {
    private Long productId;
    private String productName;
    private String userId;
    private String userAgent;
    private String ipAddress;
    private LocalDateTime timestamp;
    private String sessionId;
    private Integer viewDurationSeconds;
    private String referrer;
}
