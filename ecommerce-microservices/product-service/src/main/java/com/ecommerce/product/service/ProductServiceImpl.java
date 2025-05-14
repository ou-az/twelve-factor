package com.ecommerce.product.service;

import com.ecommerce.product.model.Product;
import com.ecommerce.product.repository.ProductRepository;
import com.ecommerce.product.event.ProductEvent;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
public class ProductServiceImpl implements ProductService {

    private static final Logger logger = LoggerFactory.getLogger(ProductServiceImpl.class);
    
    private final ProductRepository productRepository;
    private final KafkaTemplate<String, ProductEvent> kafkaTemplate;
    
    @Value("${kafka.topics.product-created}")
    private String productCreatedTopic;
    
    @Value("${kafka.topics.product-updated}")
    private String productUpdatedTopic;
    
    @Autowired
    public ProductServiceImpl(ProductRepository productRepository, 
                             KafkaTemplate<String, ProductEvent> kafkaTemplate) {
        this.productRepository = productRepository;
        this.kafkaTemplate = kafkaTemplate;
    }
    
    @Override
    public List<Product> getAllProducts() {
        return productRepository.findAll();
    }
    
    @Override
    public Optional<Product> getProductById(Long id) {
        return productRepository.findById(id);
    }
    
    @Override
    @Transactional
    public Product createProduct(Product product) {
        product.setCreatedAt(LocalDateTime.now());
        product.setUpdatedAt(LocalDateTime.now());
        
        Product savedProduct = productRepository.save(product);
        
        // Publish event for product creation
        ProductEvent event = new ProductEvent(
            savedProduct.getId(), 
            savedProduct.getName(),
            savedProduct.getPrice(),
            savedProduct.getStockQuantity(),
            ProductEvent.EventType.CREATED
        );
        
        publishProductEvent(event);
        
        return savedProduct;
    }
    
    @Override
    @Transactional
    public Product updateProduct(Long id, Product product) {
        return productRepository.findById(id)
            .map(existingProduct -> {
                existingProduct.setName(product.getName());
                existingProduct.setDescription(product.getDescription());
                existingProduct.setPrice(product.getPrice());
                existingProduct.setImageUrl(product.getImageUrl());
                existingProduct.setCategoryId(product.getCategoryId());
                existingProduct.setUpdatedAt(LocalDateTime.now());
                
                Product updatedProduct = productRepository.save(existingProduct);
                
                // Publish event for product update
                ProductEvent event = new ProductEvent(
                    updatedProduct.getId(), 
                    updatedProduct.getName(),
                    updatedProduct.getPrice(),
                    updatedProduct.getStockQuantity(),
                    ProductEvent.EventType.UPDATED
                );
                
                publishProductEvent(event);
                
                return updatedProduct;
            })
            .orElseThrow(() -> new RuntimeException("Product not found with id: " + id));
    }
    
    @Override
    @Transactional
    public void deleteProduct(Long id) {
        Product product = productRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Product not found with id: " + id));
            
        productRepository.deleteById(id);
        
        // Publish event for product deletion
        ProductEvent event = new ProductEvent(
            product.getId(), 
            product.getName(),
            product.getPrice(),
            product.getStockQuantity(),
            ProductEvent.EventType.DELETED
        );
        
        publishProductEvent(event);
    }
    
    @Override
    public List<Product> searchProducts(String nameQuery) {
        return productRepository.findByNameContainingIgnoreCase(nameQuery);
    }
    
    @Override
    public List<Product> getProductsByCategory(Long categoryId) {
        return productRepository.findByCategoryId(categoryId);
    }
    
    @Override
    public List<Product> getProductsByPriceRange(BigDecimal minPrice, BigDecimal maxPrice) {
        return productRepository.findByPriceBetween(minPrice, maxPrice);
    }
    
    @Override
    public List<Product> getLowStockProducts(Integer threshold) {
        return productRepository.findLowStockProducts(threshold);
    }
    
    @Override
    @Transactional
    public boolean updateProductStock(Long productId, Integer quantity) {
        return productRepository.findById(productId)
            .map(product -> {
                product.setStockQuantity(quantity);
                product.setUpdatedAt(LocalDateTime.now());
                
                Product updatedProduct = productRepository.save(product);
                
                // Publish event for stock change
                ProductEvent event = new ProductEvent(
                    updatedProduct.getId(), 
                    updatedProduct.getName(),
                    updatedProduct.getPrice(),
                    updatedProduct.getStockQuantity(),
                    ProductEvent.EventType.STOCK_CHANGED
                );
                
                publishProductEvent(event);
                
                return true;
            })
            .orElse(false);
    }
    
    @Override
    public void publishProductEvent(ProductEvent event) {
        try {
            String topic;
            
            switch (event.getEventType()) {
                case CREATED:
                    topic = productCreatedTopic;
                    break;
                case UPDATED:
                case STOCK_CHANGED:
                case DELETED:
                    topic = productUpdatedTopic;
                    break;
                default:
                    topic = productUpdatedTopic;
            }
            
            logger.info("Publishing product event to topic {}: {}", topic, event);
            kafkaTemplate.send(topic, event.getProductId().toString(), event);
        } catch (Exception e) {
            logger.error("Error publishing product event: {}", e.getMessage(), e);
            // For resilience, we don't want to fail the transaction if event publishing fails
            // In a production system, we might use an outbox pattern or retry mechanism
        }
    }
}
