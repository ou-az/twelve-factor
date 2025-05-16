package com.ecommerce.product.kafka.config;

import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;
import lombok.extern.slf4j.Slf4j;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.clients.producer.RecordMetadata;
import org.springframework.kafka.support.ProducerListener;

import java.time.Duration;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;
import java.util.concurrent.TimeUnit;

/**
 * Custom Kafka producer listener that integrates with Micrometer metrics
 * for comprehensive monitoring and alerting capabilities.
 * 
 * This demonstrates enterprise-grade observability patterns essential
 * for production microservices deployments.
 *
 * @param <K> Key type
 * @param <V> Value type
 */
@Slf4j
public class MonitoringProducerListener<K, V> implements ProducerListener<K, V> {

    private final MeterRegistry meterRegistry;
    private final ConcurrentMap<String, Timer> sendTimers = new ConcurrentHashMap<>();
    private final Counter totalMessagesSent;
    private final Counter failedMessages;

    public MonitoringProducerListener(MeterRegistry meterRegistry) {
        this.meterRegistry = meterRegistry;
        
        // Register global metrics
        this.totalMessagesSent = Counter.builder("kafka.producer.messages.sent.total")
                .description("Total number of messages sent")
                .register(meterRegistry);
                
        this.failedMessages = Counter.builder("kafka.producer.messages.failed.total")
                .description("Total number of messages that failed to send")
                .register(meterRegistry);
    }

    @Override
    public void onSuccess(ProducerRecord<K, V> record, RecordMetadata recordMetadata) {
        String topic = record.topic();
        
        // Track total successful messages
        totalMessagesSent.increment();
        
        // Track per-topic latency
        getOrCreateTimer(topic).record(
                Duration.ofMillis(System.currentTimeMillis() - record.timestamp())
        );
        
        // Additional per-topic counter
        Counter.builder("kafka.producer.messages.sent")
               .tag("topic", topic)
               .register(meterRegistry)
               .increment();
               
        log.debug("Message sent to topic={}, partition={}, offset={}", 
                 topic, recordMetadata.partition(), recordMetadata.offset());
    }

    @Override
    public void onError(ProducerRecord<K, V> record, RecordMetadata recordMetadata, Exception exception) {
        String topic = record.topic();
        
        // Track failed messages
        failedMessages.increment();
        
        // Track per-topic failures
        Counter.builder("kafka.producer.messages.failed")
               .tag("topic", topic)
               .tag("error_type", exception.getClass().getSimpleName())
               .register(meterRegistry)
               .increment();
               
        log.error("Error sending message to topic={}: {}", topic, exception.getMessage(), exception);
    }

    /**
     * Gets or creates a timer for tracking message send latency per topic.
     * This provides granular performance metrics for different event types.
     */
    private Timer getOrCreateTimer(String topic) {
        return sendTimers.computeIfAbsent(topic, t -> 
            Timer.builder("kafka.producer.message.latency")
                 .tag("topic", t)
                 .description("Latency of sending Kafka messages")
                 .publishPercentiles(0.5, 0.95, 0.99)
                 .publishPercentileHistogram()
                 .register(meterRegistry)
        );
    }
}
