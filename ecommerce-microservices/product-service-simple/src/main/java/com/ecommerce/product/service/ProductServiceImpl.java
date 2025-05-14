package com.ecommerce.product.service;

import com.ecommerce.product.model.Product;
import com.ecommerce.product.repository.ProductRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
@Slf4j
@RequiredArgsConstructor
public class ProductServiceImpl implements ProductService {

    private final ProductRepository productRepository;
    
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
        log.info("Created new product: {}", savedProduct);
        
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
                existingProduct.setStockQuantity(product.getStockQuantity());
                existingProduct.setUpdatedAt(LocalDateTime.now());
                
                Product updatedProduct = productRepository.save(existingProduct);
                log.info("Updated product: {}", updatedProduct);
                
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
        log.info("Deleted product with id: {}", id);
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
                productRepository.save(product);
                log.info("Updated stock for product {}: new quantity = {}", productId, quantity);
                return true;
            })
            .orElse(false);
    }
}
