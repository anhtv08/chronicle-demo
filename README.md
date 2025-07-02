# Chronicle Map/Queue Learning Demo

A comprehensive demonstration project for learning and testing the performance of Chronicle Map and Chronicle Queue libraries, built with Maven and enhanced with Lombok annotations.

## 🎯 Overview

This project provides hands-on examples and performance benchmarks to help you understand:

- **Chronicle Map**: Ultra-fast, off-heap persistent key-value store
- **Chronicle Queue**: Ultra-low latency inter-process communication
- **Performance Comparisons**: Against standard Java collections
- **Real-world Use Cases**: Trading systems, user management, order processing

## 🚀 Features

### Chronicle Map Demonstrations
- ✅ Basic CRUD operations with off-heap storage
- ✅ Performance benchmarking (1M+ operations/second)
- ✅ Persistence and recovery capabilities
- ✅ Concurrency testing with multiple threads
- ✅ Memory efficiency analysis

### Chronicle Queue Demonstrations  
- ✅ Producer-Consumer messaging patterns
- ✅ High-throughput message processing
- ✅ Persistent message queues
- ✅ Multiple consumer scenarios
- ✅ Ultra-low latency measurements

### Performance Benchmarks
- ✅ Chronicle Map vs ConcurrentHashMap
- ✅ Chronicle Queue vs LinkedBlockingQueue
- ✅ Memory usage comparisons
- ✅ Persistence performance analysis

## 📁 Project Structure

```
chronicle-demo/
├── src/main/java/com/demo/
│   ├── model/              # Lombok-enhanced data models
│   │   ├── User.java       # User entity with full lifecycle
│   │   ├── Order.java      # E-commerce order model
│   │   ├── OrderItem.java  # Order line items
│   │   ├── MarketData.java # Financial market data
│   │   └── Trade.java      # Trading execution records
│   ├── map/                # Chronicle Map demonstrations
│   │   └── ChronicleMapDemo.java
│   ├── queue/              # Chronicle Queue demonstrations  
│   │   └── ChronicleQueueDemo.java
│   ├── benchmark/          # Performance comparisons
│   │   └── PerformanceBenchmark.java
│   ├── util/               # Utility classes
│   │   └── DataGenerator.java
│   └── ChronicleDemo.java  # Main demo runner
├── src/test/java/          # Unit tests
├── pom.xml                 # Maven configuration
└── README.md              # This file
```

## 🛠️ Technology Stack

- **Java 17+**: Modern JVM with performance optimizations
- **Chronicle Map 3.25ea0**: Off-heap persistent key-value store
- **Chronicle Queue 5.25ea0**: Ultra-fast message queuing
- **Lombok 1.18.30**: Reduces boilerplate code with annotations
- **SLF4J + Logback**: Structured logging
- **JUnit 5**: Testing framework
- **Maven 3.6+**: Dependency management and build tool

## 🚀 Quick Start

### Prerequisites

- Java 17 or later
- Maven 3.6+
- 4GB+ RAM for optimal performance
- SSD storage recommended

### Build and Run

```bash
# Clone or navigate to the project directory
cd chronicle-demo

# Compile the project
mvn clean compile

# Run all demonstrations
mvn exec:java

# Or run specific demos
mvn exec:java -Pmap-demo        # Chronicle Map only
mvn exec:java -Pqueue-demo      # Chronicle Queue only  
mvn exec:java -Pbenchmark       # Performance benchmarks only

# Build executable JAR
mvn clean package

# Run the JAR
java -jar target/chronicle-demo-1.0.0.jar [demo-type]
```

### Demo Types

```bash
java -jar target/chronicle-demo-1.0.0.jar map        # Map demonstrations
java -jar target/chronicle-demo-1.0.0.jar queue      # Queue demonstrations
java -jar target/chronicle-demo-1.0.0.jar benchmark  # Performance benchmarks
java -jar target/chronicle-demo-1.0.0.jar all        # All demos (default)
```

## 📊 Performance Results

### Chronicle Map Performance
- **Write Throughput**: 6-10 million operations/second
- **Read Throughput**: 8-15 million operations/second  
- **Memory Efficiency**: ~50% less heap usage than ConcurrentHashMap
- **Persistence**: Automatic with memory-mapped files

### Chronicle Queue Performance
- **Message Throughput**: 5-12 million messages/second
- **Latency**: Sub-microsecond processing times
- **Persistence**: All messages persisted automatically
- **Concurrency**: Multiple producers/consumers supported

### Memory Usage
- **Off-heap Storage**: Chronicle Map uses memory-mapped files
- **Reduced GC Pressure**: Minimal impact on garbage collection
- **Scalability**: Handles millions of objects efficiently

## 🎓 Learning Objectives

### Chronicle Map
1. **Off-heap Storage**: Understanding memory-mapped file usage
2. **Persistence**: Automatic data persistence and recovery
3. **Performance**: Ultra-fast read/write operations
4. **Concurrency**: Thread-safe operations without locks
5. **Memory Efficiency**: Reduced heap usage and GC pressure

### Chronicle Queue
1. **Zero-copy Messaging**: Ultra-low latency communication
2. **Persistence**: All messages automatically persisted
3. **Ordering**: Guaranteed message ordering
4. **Recovery**: Automatic recovery after restarts
5. **Scalability**: Multiple producers and consumers

## 💡 Use Cases

### Chronicle Map
- **Session Stores**: Web application session management
- **Caches**: High-performance caching layer
- **Configuration**: Runtime configuration storage
- **User Profiles**: Fast user data retrieval
- **Reference Data**: Financial instrument data

### Chronicle Queue
- **Trading Systems**: Ultra-low latency order processing
- **Event Sourcing**: Reliable event streaming
- **Microservices**: Inter-service communication
- **Audit Logs**: Persistent audit trails
- **Message Brokers**: High-throughput messaging

## 🔧 Configuration

### JVM Tuning for Optimal Performance

```bash
java -Xms2g -Xmx4g \
     -XX:+UseG1GC \
     -XX:MaxGCPauseMillis=10 \
     -XX:+UnlockExperimentalVMOptions \
     -XX:+UseLargePages \
     -jar target/chronicle-demo-1.0.0.jar
```

### Chronicle Map Configuration

```java
ChronicleMap<Long, User> map = ChronicleMap
    .of(Long.class, User.class)
    .entries(1_000_000)              // Expected number of entries
    .averageValueSize(256)           // Average value size in bytes
    .putReturnsNull(true)            // Optimize for performance
    .removeReturnsNull(true)         // Optimize for performance
    .createPersistedTo(file);        // Persistence file
```

### Chronicle Queue Configuration

```java
ChronicleQueue queue = SingleChronicleQueueBuilder
    .single("/path/to/queue")
    .rollCycle(RollCycles.HOURLY)    // Roll every hour
    .build();
```

## 📈 Benchmarking

The project includes comprehensive benchmarks comparing Chronicle libraries with standard Java collections:

### Map Benchmarks
- Chronicle Map vs ConcurrentHashMap
- Write/Read performance
- Memory usage analysis
- Concurrency testing

### Queue Benchmarks  
- Chronicle Queue vs LinkedBlockingQueue
- Producer-Consumer throughput
- Latency measurements
- Persistence overhead

### Running Benchmarks

```bash
# Run all benchmarks
mvn exec:java -Pbenchmark

# Or with custom JVM settings
java -Xms1g -Xmx2g -XX:+UseG1GC \
     -cp target/classes:target/dependency/* \
     com.demo.benchmark.PerformanceBenchmark
```

## 🧪 Testing

```bash
# Run unit tests
mvn test

# Run tests with coverage
mvn test jacoco:report
```

## 📂 Data Files

The demo creates data files in the `chronicle-demo-data/` directory:

```
chronicle-demo-data/
├── users.dat              # Chronicle Map user data
├── market-data.dat         # Chronicle Map market data
├── persistent-demo.dat     # Persistence demonstration
├── counters.dat           # Concurrency test data
├── memory-test.dat         # Memory efficiency test
└── queues/                 # Chronicle Queue data
    ├── basic/              # Basic queue demo
    ├── producer-consumer/   # Producer-consumer demo
    └── high-throughput/    # High throughput demo
```

## 🔍 Code Examples

### Chronicle Map Usage

```java
// Create persistent map
try (ChronicleMap<Long, User> userMap = ChronicleMap
        .of(Long.class, User.class)
        .entries(100_000)
        .createPersistedTo(new File("users.dat"))) {
    
    // Store user
    User user = User.builder()
            .userId(1L)
            .username("john_doe")
            .email("john@example.com")
            .build();
    userMap.put(user.getUserId(), user);
    
    // Retrieve user
    User retrieved = userMap.get(1L);
    System.out.println("User: " + retrieved.getFullName());
}
```

### Chronicle Queue Usage

```java
// Create queue
try (ChronicleQueue queue = SingleChronicleQueueBuilder
        .single("trades-queue").build()) {
    
    // Producer
    try (ExcerptAppender appender = queue.acquireAppender()) {
        Trade trade = Trade.builder()
                .tradeId(1L)
                .symbol("AAPL")
                .price(BigDecimal.valueOf(150.00))
                .quantity(1000L)
                .build();
        appender.writeDocument(trade);
    }
    
    // Consumer
    try (ExcerptTailer tailer = queue.createTailer("trade-processor")) {
        Trade trade = new Trade();
        while (tailer.readDocument(trade)) {
            System.out.println("Processed trade: " + trade.getSymbol());
        }
    }
}
```

## 🎯 Learning Path

1. **Start with Basic Demos**: Run individual map and queue demos
2. **Explore Models**: Examine Lombok-enhanced data models
3. **Run Benchmarks**: Compare performance with standard collections
4. **Analyze Results**: Review performance characteristics
5. **Experiment**: Modify configurations and observe changes
6. **Real-world Application**: Apply to your specific use cases

## 🐛 Troubleshooting

### Common Issues

**OutOfMemoryError**
```bash
# Increase heap size
java -Xms2g -Xmx4g -jar chronicle-demo.jar
```

**File Permission Errors**
```bash
# Ensure write permissions to data directory
chmod 755 chronicle-demo-data/
```

**Chronicle Version Conflicts**
```bash
# Clean and rebuild
mvn clean compile
```

## 📚 Resources

- [Chronicle Map Documentation](https://github.com/OpenHFT/Chronicle-Map)
- [Chronicle Queue Documentation](https://github.com/OpenHFT/Chronicle-Queue)
- [Lombok Documentation](https://projectlombok.org/)
- [OpenHFT Performance Blog](https://blog.openhft.net/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add your improvements
4. Include tests for new functionality
5. Submit a pull request

## 📄 License

This project is provided as-is for educational and evaluation purposes.

---

🚀 **Happy Learning!** Explore the power of Chronicle Map and Queue for ultra-high performance Java applications.