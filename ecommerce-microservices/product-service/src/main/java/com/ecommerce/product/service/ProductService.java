package com.ecommerce.product.service;

import com.ecommerce.product.model.Product;
import com.ecommerce.product.event.ProductEvent;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

public interface ProductService {
    
    List<Product> getAllProducts();
    
    Optional<Product> getProductById(Long id);
    
    Product createProduct(Product product);
    
    Product updateProduct(Long id, Product product);
    
    void deleteProduct(Long id);
    
    List<Product> searchProducts(String nameQuery);
    
    List<Product> getProductsByCategory(Long categoryId);
    
    List<Product> getProductsByPriceRange(BigDecimal minPrice, BigDecimal maxPrice);
    
    List<Product> getLowStockProducts(Integer threshold);
    
    boolean updateProductStock(Long productId, Integer quantity);
    
    /**
     * Publishes product events to Kafka topic
     * @param event The product event to publish
     */
    void publishProductEvent(ProductEvent event);
}
