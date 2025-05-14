package com.ecommerce.product.controller;

import com.ecommerce.product.model.Product;
import com.ecommerce.product.service.ProductService;

import io.micrometer.core.annotation.Timed;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/products")
@Validated
public class ProductController {

    private static final Logger logger = LoggerFactory.getLogger(ProductController.class);

    private final ProductService productService;

    @Autowired
    public ProductController(ProductService productService) {
        this.productService = productService;
    }

    @GetMapping
    @Timed(value = "get.all.products", description = "Time taken to return all products")
    public ResponseEntity<List<Product>> getAllProducts() {
        logger.info("Fetching all products");
        return ResponseEntity.ok(productService.getAllProducts());
    }

    @GetMapping("/{id}")
    @Timed(value = "get.product.by.id", description = "Time taken to return a product by ID")
    public ResponseEntity<Product> getProductById(@PathVariable @Min(1) Long id) {
        logger.info("Fetching product with ID: {}", id);
        return productService.getProductById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    @Timed(value = "create.product", description = "Time taken to create a product")
    public ResponseEntity<Product> createProduct(@Valid @RequestBody Product product) {
        logger.info("Creating new product: {}", product.getName());
        Product createdProduct = productService.createProduct(product);
        return ResponseEntity.status(HttpStatus.CREATED).body(createdProduct);
    }

    @PutMapping("/{id}")
    @Timed(value = "update.product", description = "Time taken to update a product")
    public ResponseEntity<Product> updateProduct(
            @PathVariable @Min(1) Long id,
            @Valid @RequestBody Product product) {
        logger.info("Updating product with ID: {}", id);
        try {
            Product updatedProduct = productService.updateProduct(id, product);
            return ResponseEntity.ok(updatedProduct);
        } catch (RuntimeException e) {
            logger.error("Failed to update product: {}", e.getMessage());
            return ResponseEntity.notFound().build();
        }
    }

    @DeleteMapping("/{id}")
    @Timed(value = "delete.product", description = "Time taken to delete a product")
    public ResponseEntity<Void> deleteProduct(@PathVariable @Min(1) Long id) {
        logger.info("Deleting product with ID: {}", id);
        try {
            productService.deleteProduct(id);
            return ResponseEntity.noContent().build();
        } catch (RuntimeException e) {
            logger.error("Failed to delete product: {}", e.getMessage());
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping("/search")
    @Timed(value = "search.products", description = "Time taken to search products")
    public ResponseEntity<List<Product>> searchProducts(@RequestParam String name) {
        logger.info("Searching products by name: {}", name);
        return ResponseEntity.ok(productService.searchProducts(name));
    }

    @GetMapping("/category/{categoryId}")
    @Timed(value = "get.products.by.category", description = "Time taken to get products by category")
    public ResponseEntity<List<Product>> getProductsByCategory(@PathVariable Long categoryId) {
        logger.info("Fetching products by category ID: {}", categoryId);
        return ResponseEntity.ok(productService.getProductsByCategory(categoryId));
    }

    @GetMapping("/price-range")
    @Timed(value = "get.products.by.price.range", description = "Time taken to get products by price range")
    public ResponseEntity<List<Product>> getProductsByPriceRange(
            @RequestParam @NotNull BigDecimal min,
            @RequestParam @NotNull BigDecimal max) {
        logger.info("Fetching products in price range: {} - {}", min, max);
        return ResponseEntity.ok(productService.getProductsByPriceRange(min, max));
    }

    @GetMapping("/low-stock")
    @Timed(value = "get.low.stock.products", description = "Time taken to get low stock products")
    public ResponseEntity<List<Product>> getLowStockProducts(
            @RequestParam(defaultValue = "10") Integer threshold) {
        logger.info("Fetching products with stock below threshold: {}", threshold);
        return ResponseEntity.ok(productService.getLowStockProducts(threshold));
    }

    @PatchMapping("/{id}/stock")
    @Timed(value = "update.product.stock", description = "Time taken to update product stock")
    public ResponseEntity<Void> updateProductStock(
            @PathVariable @Min(1) Long id,
            @RequestBody Map<String, Integer> stockUpdate) {
        
        Integer quantity = stockUpdate.get("quantity");
        if (quantity == null) {
            return ResponseEntity.badRequest().build();
        }
        
        logger.info("Updating stock for product ID: {} to {}", id, quantity);
        boolean updated = productService.updateProductStock(id, quantity);
        
        if (updated) {
            return ResponseEntity.noContent().build();
        } else {
            return ResponseEntity.notFound().build();
        }
    }
}
