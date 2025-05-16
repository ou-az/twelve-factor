package com.ecommerce.product.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;

import java.util.concurrent.Executor;

/**
 * Configuration for asynchronous task execution.
 * This demonstrates enterprise-grade thread pool management for high-throughput event processing.
 * 
 * Properly configured thread pools are essential for production-grade applications
 * that need to handle concurrent operations efficiently.
 */
@Configuration
@EnableAsync
public class AsyncConfig {

    /**
     * Creates a dedicated thread pool for handling asynchronous Kafka event publishing.
     * This prevents the main application threads from being blocked during event processing.
     * 
     * The configuration includes:
     * - Core pool size: initial number of threads
     * - Max pool size: maximum threads during high load
     * - Queue capacity: backlog before rejecting tasks
     * - Thread naming: for better monitoring and debugging
     */
    @Bean(name = "asyncTaskExecutor")
    public Executor asyncTaskExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(4);
        executor.setMaxPoolSize(10);
        executor.setQueueCapacity(100);
        executor.setThreadNamePrefix("kafka-async-");
        executor.initialize();
        return executor;
    }
}
