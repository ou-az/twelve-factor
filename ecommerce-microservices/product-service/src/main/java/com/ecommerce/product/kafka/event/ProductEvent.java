package com.ecommerce.product.kafka.event;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductEvent implements Serializable {
    
    private static final long serialVersionUID = 1L;
    
    private UUID eventId;
    private String eventType;
    private Long productId;
    private String productName;
    private String description;
    private BigDecimal price;
    private Integer quantityAvailable;
    private String category;
    private String sku;
    
    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime timestamp;
    
    private String userId;
    
    public static ProductEvent created(Long productId, String name, String description, 
                                      BigDecimal price, Integer quantity, String category, 
                                      String sku, String userId) {
        return ProductEvent.builder()
                .eventId(UUID.randomUUID())
                .eventType("PRODUCT_CREATED")
                .productId(productId)
                .productName(name)
                .description(description)
                .price(price)
                .quantityAvailable(quantity)
                .category(category)
                .sku(sku)
                .timestamp(LocalDateTime.now())
                .userId(userId)
                .build();
    }
    
    public static ProductEvent updated(Long productId, String name, String description, 
                                      BigDecimal price, Integer quantity, String category, 
                                      String sku, String userId) {
        return ProductEvent.builder()
                .eventId(UUID.randomUUID())
                .eventType("PRODUCT_UPDATED")
                .productId(productId)
                .productName(name)
                .description(description)
                .price(price)
                .quantityAvailable(quantity)
                .category(category)
                .sku(sku)
                .timestamp(LocalDateTime.now())
                .userId(userId)
                .build();
    }
    
    public static ProductEvent deleted(Long productId, String userId) {
        return ProductEvent.builder()
                .eventId(UUID.randomUUID())
                .eventType("PRODUCT_DELETED")
                .productId(productId)
                .timestamp(LocalDateTime.now())
                .userId(userId)
                .build();
    }
    
    public static ProductEvent inventoryUpdated(Long productId, Integer quantity, String userId) {
        return ProductEvent.builder()
                .eventId(UUID.randomUUID())
                .eventType("PRODUCT_INVENTORY_UPDATED")
                .productId(productId)
                .quantityAvailable(quantity)
                .timestamp(LocalDateTime.now())
                .userId(userId)
                .build();
    }
    
    public static ProductEvent priceChanged(Long productId, BigDecimal price, String userId) {
        return ProductEvent.builder()
                .eventId(UUID.randomUUID())
                .eventType("PRODUCT_PRICE_CHANGED")
                .productId(productId)
                .price(price)
                .timestamp(LocalDateTime.now())
                .userId(userId)
                .build();
    }
}
