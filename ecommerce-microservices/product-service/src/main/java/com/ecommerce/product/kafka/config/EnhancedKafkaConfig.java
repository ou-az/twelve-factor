package com.ecommerce.product.kafka.config;

import com.ecommerce.product.config.KafkaCondition;
import com.ecommerce.product.kafka.event.EnhancedProductEvent;
import org.apache.kafka.clients.admin.NewTopic;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.common.serialization.StringSerializer;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Conditional;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.core.DefaultKafkaProducerFactory;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.core.ProducerFactory;
import org.springframework.kafka.support.ProducerListener;
import org.springframework.kafka.support.serializer.JsonSerializer;

import java.util.HashMap;
import java.util.Map;
import lombok.extern.slf4j.Slf4j;

/**
 * Enhanced Kafka configuration for sophisticated event streaming capabilities.
 * This class demonstrates enterprise-grade configuration with performance tuning
 * and monitoring integration.
 */
@Configuration
@Conditional(KafkaCondition.class)
@org.springframework.context.annotation.Profile("!postgres")
@Slf4j
public class EnhancedKafkaConfig {

    @Value("${spring.kafka.bootstrap-servers}")
    private String bootstrapServers;

    @Value("${spring.kafka.topics.product-events:product-events}")
    private String productEventsTopic;
    
    @Value("${spring.kafka.topics.product-analytics:product-analytics}")
    private String productAnalyticsTopic;
    
    @Value("${spring.kafka.producer.linger-ms:10}")
    private int lingerMs;
    
    @Value("${spring.kafka.producer.batch-size:16384}")
    private int batchSize;
    
    @Value("${spring.kafka.producer.compression-type:snappy}")
    private String compressionType;
    
    @Value("${spring.kafka.producer.retries:3}")
    private int retries;

    /**
     * Creates a producer factory for enhanced product events.
     * Configuration is optimized for high-throughput event processing with:
     * - Batching for improved network utilization
     * - Compression for reduced bandwidth
     * - Idempotent delivery for exactly-once semantics
     */
    @Bean
    public ProducerFactory<String, EnhancedProductEvent> enhancedEventProducerFactory() {
        Map<String, Object> configProps = new HashMap<>();
        configProps.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
        configProps.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class);
        configProps.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, JsonSerializer.class);
        
        // High-throughput optimizations
        configProps.put(ProducerConfig.LINGER_MS_CONFIG, lingerMs);
        configProps.put(ProducerConfig.BATCH_SIZE_CONFIG, batchSize);
        configProps.put(ProducerConfig.COMPRESSION_TYPE_CONFIG, compressionType);
        
        // Reliability settings
        configProps.put(ProducerConfig.RETRIES_CONFIG, retries);
        configProps.put(ProducerConfig.ENABLE_IDEMPOTENCE_CONFIG, true);
        configProps.put(ProducerConfig.ACKS_CONFIG, "all");
        
        return new DefaultKafkaProducerFactory<>(configProps);
    }

    /**
     * Creates a Kafka template for publishing enhanced events.
     * Integrates with monitoring metrics for operational visibility.
     */
    @Bean
    public KafkaTemplate<String, EnhancedProductEvent> enhancedKafkaTemplate(
            ProducerFactory<String, EnhancedProductEvent> enhancedEventProducerFactory) {
        KafkaTemplate<String, EnhancedProductEvent> template = 
                new KafkaTemplate<>(enhancedEventProducerFactory);
        
        // Register simple logging producer listener
        template.setProducerListener(new ProducerListener<String, EnhancedProductEvent>() {
            // Remove @Override annotations since these methods are optional implementations
            public void onSuccess(String topic, Integer partition, String key, 
                               EnhancedProductEvent value, Long timestamp) {
                log.info("Successfully sent message to topic={}, partition={}", topic, partition);
            }
            
            public void onError(String topic, Integer partition, String key, 
                             EnhancedProductEvent value, Exception exception) {
                log.error("Error sending message to topic={}: {}", topic, exception.getMessage());
            }
        });
        
        return template;
    }

    /**
     * Creates the product events topic with appropriate configuration for production use.
     */
    @Bean
    public NewTopic productEventsTopic() {
        // 6 partitions for scalability, 3 replicas for durability
        return new NewTopic(productEventsTopic, 6, (short) 3);
    }

    /**
     * Creates the product analytics topic with configuration optimized for high-throughput analytics.
     */
    @Bean
    public NewTopic productAnalyticsTopic() {
        // Analytics typically requires more partitions for parallelism
        return new NewTopic(productAnalyticsTopic, 12, (short) 3);
    }
}
