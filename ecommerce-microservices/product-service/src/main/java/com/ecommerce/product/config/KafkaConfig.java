package com.ecommerce.product.config;

import com.ecommerce.product.event.ProductEvent;
import org.apache.kafka.clients.admin.NewTopic;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.common.serialization.StringSerializer;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.config.TopicBuilder;
import org.springframework.kafka.core.DefaultKafkaProducerFactory;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.core.ProducerFactory;
import org.springframework.kafka.support.serializer.JsonSerializer;

import java.util.HashMap;
import java.util.Map;

@Configuration
public class KafkaConfig {

    @Value("${spring.kafka.bootstrap-servers}")
    private String bootstrapServers;

    @Value("${kafka.topics.product-created}")
    private String productCreatedTopic;
    
    @Value("${kafka.topics.product-updated}")
    private String productUpdatedTopic;
    
    @Value("${kafka.topics.inventory-updated}")
    private String inventoryUpdatedTopic;

    @Bean
    public Map<String, Object> producerConfigs() {
        Map<String, Object> props = new HashMap<>();
        props.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
        props.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class);
        props.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, JsonSerializer.class);
        // Enable idempotent producer for exactly-once semantics
        props.put(ProducerConfig.ENABLE_IDEMPOTENCE_CONFIG, true);
        props.put(ProducerConfig.ACKS_CONFIG, "all");
        props.put(ProducerConfig.RETRIES_CONFIG, 3);
        return props;
    }

    @Bean
    public ProducerFactory<String, ProductEvent> producerFactory() {
        return new DefaultKafkaProducerFactory<>(producerConfigs());
    }

    @Bean
    public KafkaTemplate<String, ProductEvent> kafkaTemplate() {
        return new KafkaTemplate<>(producerFactory());
    }

    // Create topics programmatically
    @Bean
    public NewTopic productCreatedTopic() {
        return TopicBuilder.name(productCreatedTopic)
                .partitions(3)
                .replicas(3)
                .compact()
                .build();
    }

    @Bean
    public NewTopic productUpdatedTopic() {
        return TopicBuilder.name(productUpdatedTopic)
                .partitions(3)
                .replicas(3)
                .compact()
                .build();
    }
    
    @Bean
    public NewTopic inventoryUpdatedTopic() {
        return TopicBuilder.name(inventoryUpdatedTopic)
                .partitions(3)
                .replicas(3)
                .compact()
                .build();
    }
}
