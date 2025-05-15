package com.ecommerce.product.kafka.event;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class ProductPurchaseEvent {
    private Long productId;
    private String productName;
    private String userId;
    private String orderId;
    private Integer quantity;
    private BigDecimal price;
    private BigDecimal totalAmount;
    private LocalDateTime timestamp;
    private String paymentMethod;
    private String shippingCountry;
}
