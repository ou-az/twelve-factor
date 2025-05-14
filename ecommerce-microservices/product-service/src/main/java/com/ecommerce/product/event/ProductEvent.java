package com.ecommerce.product.event;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public class ProductEvent {

    public enum EventType {
        CREATED,
        UPDATED,
        DELETED,
        STOCK_CHANGED
    }

    private Long productId;
    private String productName;
    private BigDecimal price;
    private Integer stockQuantity;
    private EventType eventType;
    private LocalDateTime timestamp;

    public ProductEvent() {
        this.timestamp = LocalDateTime.now();
    }
    
    public ProductEvent(Long productId, String productName, BigDecimal price, Integer stockQuantity, EventType eventType) {
        this.productId = productId;
        this.productName = productName;
        this.price = price;
        this.stockQuantity = stockQuantity;
        this.eventType = eventType;
        this.timestamp = LocalDateTime.now();
    }

    // Getters and setters
    public Long getProductId() {
        return productId;
    }

    public void setProductId(Long productId) {
        this.productId = productId;
    }

    public String getProductName() {
        return productName;
    }

    public void setProductName(String productName) {
        this.productName = productName;
    }

    public BigDecimal getPrice() {
        return price;
    }

    public void setPrice(BigDecimal price) {
        this.price = price;
    }

    public Integer getStockQuantity() {
        return stockQuantity;
    }

    public void setStockQuantity(Integer stockQuantity) {
        this.stockQuantity = stockQuantity;
    }

    public EventType getEventType() {
        return eventType;
    }

    public void setEventType(EventType eventType) {
        this.eventType = eventType;
    }

    public LocalDateTime getTimestamp() {
        return timestamp;
    }

    public void setTimestamp(LocalDateTime timestamp) {
        this.timestamp = timestamp;
    }

    @Override
    public String toString() {
        return "ProductEvent{" +
                "productId=" + productId +
                ", productName='" + productName + '\'' +
                ", eventType=" + eventType +
                ", timestamp=" + timestamp +
                '}';
    }
}
