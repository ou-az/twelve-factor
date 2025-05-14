package com.ecommerce.product.config;

import org.springframework.context.annotation.Condition;
import org.springframework.context.annotation.ConditionContext;
import org.springframework.core.type.AnnotatedTypeMetadata;

/**
 * Condition to determine if Kafka should be enabled
 * This allows us to conditionally enable/disable Kafka components
 */
public class KafkaCondition implements Condition {
    @Override
    public boolean matches(ConditionContext context, AnnotatedTypeMetadata metadata) {
        String kafkaEnabled = context.getEnvironment().getProperty("spring.kafka.enabled");
        // If property is not set, default to true (enable Kafka)
        return kafkaEnabled == null || Boolean.parseBoolean(kafkaEnabled);
    }
}
