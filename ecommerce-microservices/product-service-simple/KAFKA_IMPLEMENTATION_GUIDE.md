# Kafka Integration Guide for Spring Boot Microservices

This document outlines practical implementations of Kafka within a Spring Boot microservice architecture, demonstrating event-driven patterns and advanced streaming capabilities. These implementations are particularly relevant for positions requiring Kafka and event streaming expertise.

## Table of Contents

1. [Business Use Cases for Kafka](#business-use-cases-for-kafka)
2. [Implementation Patterns](#implementation-patterns)
3. [Code Examples](#code-examples)
4. [Testing Strategies](#testing-strategies)
5. [Performance Considerations](#performance-considerations)
6. [Demonstration Scripts](#demonstration-scripts)
7. [Relevance to Job Applications](#relevance-to-job-applications)

## Business Use Cases for Kafka

### 1. Product Inventory Events

**Scenario**: When product inventory changes, emit events to notify other services.

**Benefits**:
- Real-time inventory updates
- Decoupled services
- Scalable processing of inventory changes

**Event Types**:
- `ProductCreated`
- `ProductUpdated`
- `ProductDeleted`
- `InventoryChanged`

### 2. Order Processing Pipeline

**Scenario**: Process orders through a series of steps using Kafka as the backbone.

**Flow**:
1. Order Placed → `order-placed` topic
2. Payment Processing → `payment-processed` topic
3. Inventory Reserved → `inventory-reserved` topic
4. Order Fulfilled → `order-fulfilled` topic

**Benefits**:
- Service isolation
- Failure resilience
- Event replay capability
- System back-pressure handling

### 3. Real-time Analytics

**Scenario**: Stream product interaction data for analytics and monitoring.

**Event Types**:
- `ProductViewed`
- `ProductAddedToCart`
- `ProductPurchased`
- `CategoryBrowsed`

**Benefits**:
- Real-time dashboards
- Trend analysis
- Personalization data
- A/B testing metrics

## Implementation Patterns

### 1. Event Sourcing with Kafka

Store all state changes as a sequence of events in Kafka topics, allowing for:
- System state reconstruction
- Temporal querying (state at any point in time)
- Audit capabilities
- Event replay for new services

**Implementation Components**:
- Event Store (Kafka)
- Command Handlers (validate and publish events)
- Event Handlers (update read models)
- Projections (materialized views)

### 2. CQRS (Command Query Responsibility Segregation)

Separate write (command) and read (query) models, using Kafka as the event bus:
- Commands modify state and emit events
- Events update read models
- Queries read from optimized view models

**Benefits**:
- Optimized read and write models
- Scalability advantages
- Better query performance
- Independent scaling of read and write services

### 3. Kafka Streams for Data Processing

Use Kafka Streams API for stateful data processing:
- Filtering
- Aggregation
- Windowing operations
- Joining data streams

**Applications**:
- Real-time product recommendations
- Inventory analytics
- Customer behavior analysis
- Dynamic pricing updates

## Code Examples

### 1. Kafka Producer Configuration

```java
@Configuration
public class KafkaProducerConfig {
    
    @Value("${spring.kafka.bootstrap-servers}")
    private String bootstrapServers;
    
    @Bean
    public ProducerFactory<String, Object> producerFactory() {
        Map<String, Object> configProps = new HashMap<>();
        configProps.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
        configProps.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class);
        configProps.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, JsonSerializer.class);
        // Enable idempotent producer for exactly-once semantics
        configProps.put(ProducerConfig.ENABLE_IDEMPOTENCE_CONFIG, true);
        configProps.put(ProducerConfig.ACKS_CONFIG, "all");
        configProps.put(ProducerConfig.RETRIES_CONFIG, Integer.toString(Integer.MAX_VALUE));
        
        return new DefaultKafkaProducerFactory<>(configProps);
    }
    
    @Bean
    public KafkaTemplate<String, Object> kafkaTemplate() {
        return new KafkaTemplate<>(producerFactory());
    }
}
```

### 2. Kafka Consumer Configuration

```java
@Configuration
public class KafkaConsumerConfig {
    
    @Value("${spring.kafka.bootstrap-servers}")
    private String bootstrapServers;
    
    @Value("${spring.kafka.consumer.group-id}")
    private String groupId;
    
    @Bean
    public ConsumerFactory<String, Object> consumerFactory() {
        Map<String, Object> props = new HashMap<>();
        props.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
        props.put(ConsumerConfig.GROUP_ID_CONFIG, groupId);
        props.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class);
        props.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, JsonDeserializer.class);
        props.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest");
        props.put(JsonDeserializer.TRUSTED_PACKAGES, "com.ecommerce.product.kafka.event");
        props.put(ConsumerConfig.ENABLE_AUTO_COMMIT_CONFIG, false); // For better control
        
        return new DefaultKafkaConsumerFactory<>(props);
    }
    
    @Bean
    public ConcurrentKafkaListenerContainerFactory<String, Object> kafkaListenerContainerFactory() {
        ConcurrentKafkaListenerContainerFactory<String, Object> factory = 
            new ConcurrentKafkaListenerContainerFactory<>();
        factory.setConsumerFactory(consumerFactory());
        factory.getContainerProperties().setAckMode(AckMode.MANUAL_IMMEDIATE);
        factory.setConcurrency(3); // Multiple consumers for parallelism
        
        return factory;
    }
}
```

### 3. Event Model Classes

```java
@Data
@AllArgsConstructor
@NoArgsConstructor
public class ProductEvent {
    private String eventId;
    private String eventType;
    private Long productId;
    private LocalDateTime timestamp;
    private Object data;
}

@Data
@AllArgsConstructor
@NoArgsConstructor
public class InventoryChangeEvent {
    private Long productId;
    private Integer previousQuantity;
    private Integer newQuantity;
    private String changeReason;
    private LocalDateTime timestamp;
}
```

### 4. Event Publisher Service

```java
@Service
@RequiredArgsConstructor
public class ProductEventPublisher {
    
    private final KafkaTemplate<String, Object> kafkaTemplate;
    
    @Value("${kafka.topic.product-events}")
    private String productEventsTopic;
    
    public void publishProductCreated(Product product) {
        String eventId = UUID.randomUUID().toString();
        ProductEvent event = new ProductEvent(
            eventId,
            "PRODUCT_CREATED",
            product.getId(),
            LocalDateTime.now(),
            product
        );
        
        kafkaTemplate.send(productEventsTopic, product.getId().toString(), event)
            .addCallback(
                result -> log.info("Product created event published: {}", eventId),
                ex -> log.error("Failed to publish product created event", ex)
            );
    }
    
    public void publishInventoryChanged(Long productId, Integer oldQuantity, Integer newQuantity) {
        InventoryChangeEvent event = new InventoryChangeEvent(
            productId,
            oldQuantity,
            newQuantity,
            "STOCK_UPDATE",
            LocalDateTime.now()
        );
        
        kafkaTemplate.send(productEventsTopic, productId.toString(), event)
            .addCallback(
                result -> log.info("Inventory changed event published for product: {}", productId),
                ex -> log.error("Failed to publish inventory change event", ex)
            );
    }
}
```

### 5. Event Consumer

```java
@Service
@RequiredArgsConstructor
@Slf4j
public class ProductEventConsumer {
    
    private final AnalyticsService analyticsService;
    
    @KafkaListener(
        topics = "${kafka.topic.product-events}",
        groupId = "${spring.kafka.consumer.group-id}",
        containerFactory = "kafkaListenerContainerFactory"
    )
    public void consume(
        @Payload ProductEvent event,
        @Header(KafkaHeaders.RECEIVED_PARTITION_ID) int partition,
        @Header(KafkaHeaders.OFFSET) long offset,
        Acknowledgment acknowledgment
    ) {
        log.info("Received event: type={}, id={}, partition={}, offset={}", 
                 event.getEventType(), event.getEventId(), partition, offset);
        
        try {
            switch (event.getEventType()) {
                case "PRODUCT_CREATED":
                    analyticsService.processNewProduct(event);
                    break;
                case "PRODUCT_UPDATED":
                    analyticsService.processProductUpdate(event);
                    break;
                case "INVENTORY_CHANGED":
                    analyticsService.processInventoryChange(event);
                    break;
                default:
                    log.warn("Unknown event type: {}", event.getEventType());
            }
            
            // Manually acknowledge the message
            acknowledgment.acknowledge();
            
        } catch (Exception e) {
            log.error("Error processing event", e);
            // Don't acknowledge - message will be redelivered
        }
    }
}
```

### 6. Kafka Streams Example for Real-time Analytics

```java
@Configuration
@EnableKafkaStreams
public class KafkaStreamsConfig {
    
    @Bean
    public KStream<String, ProductEvent> productEventStream(StreamsBuilder streamsBuilder) {
        KStream<String, ProductEvent> stream = streamsBuilder
            .stream("product-events", Consumed.with(Serdes.String(), 
                                                  JsonSerde.of(ProductEvent.class)));
        
        // Filter for inventory changes
        KStream<String, InventoryChangeEvent> inventoryStream = stream
            .filter((key, event) -> "INVENTORY_CHANGED".equals(event.getEventType()))
            .mapValues(event -> (InventoryChangeEvent) event.getData());
        
        // Aggregate inventory changes by product ID within 1-minute windows
        inventoryStream
            .groupByKey()
            .windowedBy(TimeWindows.of(Duration.ofMinutes(1)))
            .aggregate(
                () -> new ProductInventoryStats(),
                (key, value, aggregate) -> {
                    aggregate.setProductId(Long.parseLong(key));
                    aggregate.setTotalChangeCount(aggregate.getTotalChangeCount() + 1);
                    aggregate.setLatestQuantity(value.getNewQuantity());
                    aggregate.setLastUpdated(value.getTimestamp());
                    return aggregate;
                },
                Materialized.with(Serdes.String(), JsonSerde.of(ProductInventoryStats.class))
            )
            .toStream()
            .peek((key, value) -> log.info("Inventory stats: {}", value))
            .to("product-inventory-stats", Produced.with(
                    WindowedSerdes.timeWindowedSerdeFrom(String.class),
                    JsonSerde.of(ProductInventoryStats.class)
                )
            );
        
        return stream;
    }
}
```

## Testing Strategies

### 1. Unit Testing with Embedded Kafka

```java
@SpringBootTest
@EmbeddedKafka(partitions = 1, topics = {"product-events"})
class ProductEventPublisherTest {
    
    @Autowired
    private ProductEventPublisher publisher;
    
    @Autowired
    private KafkaTemplate<String, Object> kafkaTemplate;
    
    @Value("${kafka.topic.product-events}")
    private String productEventsTopic;
    
    @SpyBean
    private ProductEventConsumer consumer;
    
    @Test
    void testPublishProductCreated() throws InterruptedException {
        // Arrange
        Product product = new Product();
        product.setId(1L);
        product.setName("Test Product");
        product.setPrice(BigDecimal.valueOf(100));
        
        CountDownLatch latch = new CountDownLatch(1);
        doAnswer(invocation -> {
            latch.countDown();
            return null;
        }).when(consumer).consume(any(), anyInt(), anyLong(), any());
        
        // Act
        publisher.publishProductCreated(product);
        
        // Assert
        boolean messageReceived = latch.await(10, TimeUnit.SECONDS);
        assertTrue(messageReceived);
        verify(consumer, times(1)).consume(any(), anyInt(), anyLong(), any());
    }
}
```

### 2. Integration Testing with TestContainers

```java
@SpringBootTest
@Testcontainers
@ActiveProfiles("test")
class KafkaIntegrationTest {
    
    @Container
    static KafkaContainer kafkaContainer = new KafkaContainer(DockerImageName.parse("confluentinc/cp-kafka:7.3.0"));
    
    @DynamicPropertySource
    static void kafkaProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.kafka.bootstrap-servers", kafkaContainer::getBootstrapServers);
    }
    
    @Autowired
    private ProductEventPublisher publisher;
    
    @Autowired
    private ProductService productService;
    
    @MockBean
    private AnalyticsService analyticsService;
    
    @Test
    void testEndToEndEventProcessing() throws InterruptedException {
        // Arrange
        Product product = new Product();
        product.setName("Test Product");
        product.setPrice(BigDecimal.valueOf(100));
        product.setCategoryId(1L);
        product.setStockQuantity(10);
        
        // Act
        Product savedProduct = productService.createProduct(product);
        
        // Assert
        verify(analyticsService, timeout(5000).times(1))
            .processNewProduct(argThat(event -> 
                "PRODUCT_CREATED".equals(event.getEventType()) && 
                savedProduct.getId().equals(event.getProductId())
            ));
    }
}
```

### 3. Performance Testing with Kafka Stress Tool

```bash
# Create test data file
cat > product-events.json << EOF
{"eventId":"1","eventType":"PRODUCT_CREATED","productId":1,"data":{"name":"Product 1","price":10.99}}
{"eventId":"2","eventType":"PRODUCT_CREATED","productId":2,"data":{"name":"Product 2","price":20.99}}
EOF

# Send 100,000 messages at 1000 messages per second
kafka-producer-perf-test \
  --topic product-events \
  --num-records 100000 \
  --record-size 256 \
  --throughput 1000 \
  --producer-props bootstrap.servers=localhost:29092 \
  --payload-file product-events.json
```

## Performance Considerations

### 1. Producer Performance Optimization

- **Batching**: Set `batch.size` and `linger.ms` for efficient batching of messages
- **Compression**: Use Snappy or LZ4 compression for reduced network bandwidth usage
- **Idempotence**: Enable idempotent producers to prevent message duplication
- **Asynchronous Processing**: Use non-blocking operations with callbacks

### 2. Consumer Performance Optimization

- **Concurrency**: Multiple consumer instances with concurrent Kafka listener
- **Batch Processing**: Process messages in batches when possible
- **Manual Acknowledgement**: Control when messages are considered processed
- **Consumer Partitioning**: Assign specific partitions to specific consumers

### 3. Kafka Streams Optimization

- **State Store Caching**: Configure caching for state stores
- **Parallelism**: Specify number of threads for parallel processing
- **Record Caching**: Adjust caching parameters to reduce disk I/O
- **Commit Interval**: Tune commit interval for state stores

## Demonstration Scripts

### 1. Product Event Publishing Demo

```bash
# Create a product using the API
curl -X POST http://localhost:8080/api/products \
  -H "Content-Type: application/json" \
  -d '{
    "name":"Enterprise Java Architecture",
    "description":"Advanced patterns for building scalable applications",
    "price":49.99,
    "categoryId":1,
    "stockQuantity":100
  }'

# View the generated event in Kafka UI
# Navigate to http://localhost:8090
# Click on "Topics" -> "product-events" -> "Messages"

# Update the stock quantity
curl -X PUT http://localhost:8080/api/products/1/stock \
  -H "Content-Type: application/json" \
  -d '{
    "stockQuantity": 75
  }'

# View the inventory changed event
# Watch the Kafka UI for the new event
```

### 2. Multi-Service Integration Demo

```bash
# Simulate an order placement (would typically come from another service)
kafka-console-producer --bootstrap-server localhost:29092 --topic order-events << EOF
{"orderId":"1001","customerId":"C5001","items":[{"productId":1,"quantity":2,"price":49.99}],"status":"PLACED"}
EOF

# Watch product service process the order and update inventory
# Observe inventory events published back to Kafka
# Navigate to http://localhost:8090 to see all events
```

### 3. Kafka Streams Demo

```bash
# Generate product view events
for i in {1..100}; do
  PRODUCT_ID=$((RANDOM % 5 + 1))
  USER_ID="user$((RANDOM % 20 + 1))"
  
  kafka-console-producer --bootstrap-server localhost:29092 --topic product-views << EOF
{"productId":$PRODUCT_ID,"userId":"$USER_ID","timestamp":"$(date -u +"%Y-%m-%dT%H:%M:%SZ")"}
EOF
  sleep 0.1
done

# View aggregated results in real-time
kafka-console-consumer --bootstrap-server localhost:29092 \
  --topic product-view-counts \
  --from-beginning
```

## Relevance to Job Applications

### Java Developer - Process Streaming (Intellibus)

This Kafka implementation directly demonstrates:
- Expertise with Kafka message processing
- Java Stream API implementation experience
- Multithreading/concurrency patterns
- Spring Boot application development
- Real-time data processing capabilities
- Microservices architecture knowledge

### Staff Software Engineer (Plexus Worldwide)

These examples showcase:
- Architectural expertise with event-driven microservices
- Knowledge of Kafka for modern message-driven applications
- Implementation of twelve-factor app principles
- Experience with Spring Boot and Java
- System optimization capabilities
- Modern design patterns for enterprise applications

### Lead Java Software Engineer (Wells Fargo)

The implementation demonstrates:
- Core Java with modern Java features
- Spring framework expertise
- Event-driven architecture knowledge
- Microservices implementation
- Understanding of distributed systems
- Production-ready code with proper testing

### DevOps/Cloud Engineer (Cyber-Infomax)

The containerization and infrastructure aspects highlight:
- Docker implementation skills
- Infrastructure as Code experience
- Understanding of application deployment
- Cloud-native application architecture
- Monitoring and observability patterns
- Performance testing and optimization

---

This implementation guide provides a comprehensive foundation for demonstrating advanced Kafka integration in a Spring Boot microservice, which directly supports the requirements for multiple target job positions, particularly the Java Developer role at Intellibus focusing on Process Streaming.
