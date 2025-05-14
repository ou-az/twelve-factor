package com.ecommerce.product.service;

import com.ecommerce.product.config.KafkaCondition;
import com.ecommerce.product.event.ProductEvent;
import com.ecommerce.product.model.Product;
import com.ecommerce.product.repository.ProductRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Conditional;
import org.springframework.context.annotation.Primary;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * This is a simplified implementation of ProductService that doesn't require Kafka.
 * It will be used in local development when Kafka is disabled.
 */
@Service
@Primary
@Conditional(value = KafkaCondition.class)
public class LocalProductServiceImpl implements ProductService {

    private static final Logger logger = LoggerFactory.getLogger(LocalProductServiceImpl.class);
    
    private final ProductRepository productRepository;
    
    @Autowired
    public LocalProductServiceImpl(ProductRepository productRepository) {
        this.productRepository = productRepository;
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
        
        // Log event instead of publishing to Kafka
        ProductEvent event = new ProductEvent(
            savedProduct.getId(), 
            savedProduct.getName(),
            savedProduct.getPrice(),
            savedProduct.getStockQuantity(),
            ProductEvent.EventType.CREATED
        );
        
        logProductEvent(event);
        
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
                
                // Log event instead of publishing to Kafka
                ProductEvent event = new ProductEvent(
                    updatedProduct.getId(), 
                    updatedProduct.getName(),
                    updatedProduct.getPrice(),
                    updatedProduct.getStockQuantity(),
                    ProductEvent.EventType.UPDATED
                );
                
                logProductEvent(event);
                
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
        
        // Log event instead of publishing to Kafka
        ProductEvent event = new ProductEvent(
            product.getId(), 
            product.getName(),
            product.getPrice(),
            product.getStockQuantity(),
            ProductEvent.EventType.DELETED
        );
        
        logProductEvent(event);
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
                
                // Log event instead of publishing to Kafka
                ProductEvent event = new ProductEvent(
                    updatedProduct.getId(), 
                    updatedProduct.getName(),
                    updatedProduct.getPrice(),
                    updatedProduct.getStockQuantity(),
                    ProductEvent.EventType.STOCK_CHANGED
                );
                
                logProductEvent(event);
                
                return true;
            })
            .orElse(false);
    }
    
    @Override
    public void publishProductEvent(ProductEvent event) {
        // In local mode, we just log the event instead of publishing to Kafka
        logProductEvent(event);
    }
    
    private void logProductEvent(ProductEvent event) {
        logger.info("LOCAL MODE - Product Event (not published to Kafka): {}", event);
    }
}
