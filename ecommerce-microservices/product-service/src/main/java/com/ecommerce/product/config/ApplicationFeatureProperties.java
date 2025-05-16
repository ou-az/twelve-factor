package com.ecommerce.product.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

/**
 * Centralized configuration properties following twelve-factor app principles.
 * This class demonstrates proper external configuration management for enterprise applications.
 * 
 * By externalizing all configuration, we support:
 * 1. Environment-specific deployment (dev/staging/prod)
 * 2. Feature toggles for controlled rollouts
 * 3. Runtime tuning without code changes
 */
@Data
@Configuration
@ConfigurationProperties(prefix = "application.features")
public class ApplicationFeatureProperties {

    /**
     * Configuration properties for the event simulator.
     */
    private final SimulatorProperties simulator = new SimulatorProperties();
    
    /**
     * Configuration properties for analytics capabilities.
     */
    private final AnalyticsProperties analytics = new AnalyticsProperties();
    
    /**
     * Nested properties for the product activity simulator.
     * This demonstrates proper hierarchical configuration management.
     */
    @Data
    public static class SimulatorProperties {
        /**
         * Whether the simulator is enabled. Defaults to false for production safety.
         */
        private boolean enabled = false;
        
        /**
         * Rate at which events are generated in milliseconds.
         */
        private int rate = 2000;
        
        /**
         * Maximum number of events to generate in each batch.
         */
        private int batchSize = 3;
        
        /**
         * Types of events to simulate.
         */
        private String[] eventTypes = {
                "VIEW", "SEARCH", "ADD_TO_CART", "PURCHASE", "REVIEW", "WISHLIST_ADD"
        };
    }
    
    /**
     * Nested properties for analytics configuration.
     */
    @Data
    public static class AnalyticsProperties {
        /**
         * Whether real-time analytics is enabled.
         */
        private boolean realTimeEnabled = true;
        
        /**
         * Maximum number of events to buffer before flushing.
         */
        private int bufferSize = 100;
        
        /**
         * Maximum time to buffer events before flushing in milliseconds.
         */
        private int flushIntervalMs = 5000;
    }
}
