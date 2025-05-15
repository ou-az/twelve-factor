package com.ecommerce.product.kafka;

import com.ecommerce.product.model.Product;
import com.ecommerce.product.service.ProductService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Random;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicLong;

/**
 * Simulates real user activity with products by generating continuous Kafka events.
 * This demonstrates streaming capabilities using Kafka for real-time event processing.
 */
@Component
@EnableScheduling
@RequiredArgsConstructor
@Slf4j
public class ProductActivitySimulator {
    
    private final ProductService productService;
    private final ProductEventProducer eventProducer;
    private final Random random = new Random();
    private final AtomicLong eventCounter = new AtomicLong(0);
    
    private static final String[] EVENT_TYPES = {
            "VIEW", "SEARCH", "ADD_TO_CART", "PURCHASE", "REVIEW", "WISHLIST_ADD"
    };
    
    private static final String[] USER_IDS = {
            "user123", "customer456", "shopper789", "client321", "buyer654", 
            "visitor987", "member741", "guest852", "consumer963", "patron159"
    };
    
    private static final String[] USER_AGENTS = {
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15",
            "Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15",
            "Mozilla/5.0 (iPad; CPU OS 14_0 like Mac OS X) AppleWebKit/605.1.15",
            "Mozilla/5.0 (Android 10; Mobile) AppleWebKit/537.36"
    };
    
    private static final String[] IP_ADDRESSES = {
            "192.168.1.100", "172.16.0.50", "10.0.0.25", "8.8.8.8", "203.0.113.42", 
            "198.51.100.23", "172.217.20.142", "151.101.1.195", "104.244.42.1"
    };
    
    private static final String[] REFERRERS = {
            "https://www.google.com", "https://www.bing.com", "https://www.facebook.com",
            "https://www.instagram.com", "https://www.twitter.com", "https://www.linkedin.com",
            "https://www.youtube.com", "Direct", "Email", "Mobile App"
    };
    
    /**
     * Generates product events at a fixed rate to simulate continuous real-time activity.
     * This demonstrates Kafka streaming capabilities.
     */
    @Scheduled(fixedRate = 2000) // Generate events every 2 seconds
    public void generateProductEvents() {
        List<Product> products = productService.getAllProducts();
        
        if (products.isEmpty()) {
            log.warn("No products available for event simulation");
            return;
        }
        
        try {
            // Generate 1-3 events per cycle
            int eventsToGenerate = random.nextInt(3) + 1;
            
            for (int i = 0; i < eventsToGenerate; i++) {
                Product randomProduct = products.get(random.nextInt(products.size()));
                ProductEvent event = createRandomEvent(randomProduct);
                
                eventProducer.publishProductEvent(event);
                
                long count = eventCounter.incrementAndGet();
                if (count % 100 == 0) {
                    log.info("Milestone: {} product events generated", count);
                }
            }
        } catch (Exception e) {
            log.error("Error generating product events", e);
        }
    }
    
    private ProductEvent createRandomEvent(Product product) {
        String eventType = EVENT_TYPES[random.nextInt(EVENT_TYPES.length)];
        String userId = USER_IDS[random.nextInt(USER_IDS.length)];
        String userAgent = USER_AGENTS[random.nextInt(USER_AGENTS.length)];
        String ipAddress = IP_ADDRESSES[random.nextInt(IP_ADDRESSES.length)];
        String sessionId = "session-" + UUID.randomUUID().toString().substring(0, 8);
        String referrer = REFERRERS[random.nextInt(REFERRERS.length)];
        
        ProductEvent event = new ProductEvent();
        event.setEventId(UUID.randomUUID().toString());
        event.setEventType(eventType);
        event.setProductId(product.getId());
        event.setProductName(product.getName());
        event.setUserId(userId);
        event.setTimestamp(LocalDateTime.now());
        event.setUserAgent(userAgent);
        event.setIpAddress(ipAddress);
        event.setSessionId(sessionId);
        event.setReferrer(referrer);
        
        // Set event-specific properties
        switch (eventType) {
            case "VIEW":
                event.setViewDurationSeconds(random.nextInt(300) + 5); // 5-305 seconds
                break;
            case "PURCHASE":
                event.setQuantity(random.nextInt(3) + 1); // 1-3 items
                event.setPrice(product.getPrice().doubleValue());
                break;
            case "REVIEW":
                event.setRating(random.nextInt(5) + 1); // 1-5 stars
                event.setComment("Sample review comment for " + product.getName());
                break;
        }
        
        return event;
    }
}
