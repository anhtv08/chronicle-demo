package com.demo.queue;

import com.demo.model.Trade;
import com.demo.model.MarketData;
import com.demo.util.DataGenerator;
import lombok.extern.slf4j.Slf4j;
import net.openhft.chronicle.queue.ChronicleQueue;
import net.openhft.chronicle.queue.ExcerptAppender;
import net.openhft.chronicle.queue.ExcerptTailer;
import net.openhft.chronicle.queue.impl.single.SingleChronicleQueueBuilder;

import java.io.File;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.atomic.AtomicLong;

/**
 * Chronicle Queue demonstration showing messaging patterns and performance
 */
@Slf4j
public class ChronicleQueueDemo {
    
    private static final String QUEUE_DIR = "chronicle-demo-data/queues";
    
    public static void main(String[] args) {
        log.info("Starting Chronicle Queue Performance Demo");
        log.info("==========================================");
        
        ChronicleQueueDemo demo = new ChronicleQueueDemo();
        
        try {
            // Create queue directory
            new File(QUEUE_DIR).mkdirs();
            
            // Run different demos
            demo.basicUsageDemo();
            demo.producerConsumerDemo();
            demo.highThroughputDemo();
            demo.persistenceDemo();
            demo.multipleConsumersDemo();
            
        } catch (Exception e) {
            log.error("Demo failed", e);
        }
        
        log.info("Chronicle Queue Demo completed");
    }
    
    /**
     * Basic usage demonstration
     */
    public void basicUsageDemo() {
        log.info("\n--- Basic Usage Demo ---");
        
        try (ChronicleQueue queue = SingleChronicleQueueBuilder.single(QUEUE_DIR + "/basic")
                .build()) {
            
            // Producer - write messages
            ExcerptAppender appender = queue.acquireAppender();
            
            for (int i = 1; i <= 10; i++) {
                Trade trade = DataGenerator.generateTrade((long) i, "DEMO");
                appender.writeDocument(trade);
                log.info("Wrote trade {}: {} {} @ {}", 
                    trade.getTradeId(), 
                    trade.getQuantity(), 
                    trade.getSymbol(), 
                    trade.getPrice());
            }
            
            // Consumer - read messages
            ExcerptTailer tailer = queue.createTailer("demo-consumer");
            
            log.info("Reading trades from queue:");
            Trade trade = new Trade();
            while (tailer.readDocument(trade)) {
                log.info("Read trade {}: {} {} @ {} (Value: {})", 
                    trade.getTradeId(),
                    trade.getQuantity(),
                    trade.getSymbol(),
                    trade.getPrice(),
                    trade.getNotionalValue());
            }
        }
    }
    
    /**
     * Producer-Consumer pattern demonstration
     */
    public void producerConsumerDemo() throws InterruptedException {
        log.info("\n--- Producer-Consumer Demo ---");
        
        try (ChronicleQueue queue = SingleChronicleQueueBuilder.single(QUEUE_DIR + "/producer-consumer")
                .build()) {
            
            int messageCount = 10_000;
            CountDownLatch producerLatch = new CountDownLatch(1);
            CountDownLatch consumerLatch = new CountDownLatch(1);
            AtomicLong messagesProduced = new AtomicLong();
            AtomicLong messagesConsumed = new AtomicLong();
            
            // Producer thread
            Thread producer = new Thread(() -> {
                try (ExcerptAppender appender = queue.acquireAppender()) {
                    long startTime = System.nanoTime();
                    
                    for (int i = 1; i <= messageCount; i++) {
                        MarketData marketData = DataGenerator.generateMarketData("PROD_" + (i % 100));
                        appender.writeDocument(marketData);
                        messagesProduced.incrementAndGet();
                    }
                    
                    long duration = System.nanoTime() - startTime;
                    log.info("Producer completed:");
                    log.info("  Messages: {}", messageCount);
                    log.info("  Duration: {} ms", duration / 1_000_000);
                    log.info("  Throughput: {} messages/sec", (messageCount * 1_000_000_000L) / duration);
                    
                } finally {
                    producerLatch.countDown();
                }
            });
            
            // Consumer thread
            Thread consumer = new Thread(() -> {
                try (ExcerptTailer tailer = queue.createTailer("demo-consumer")) {
                    long startTime = System.nanoTime();
                    MarketData marketData = new MarketData();
                    
                    while (messagesConsumed.get() < messageCount) {
                        if (tailer.readDocument(marketData)) {
                            messagesConsumed.incrementAndGet();
                            // Simulate processing
                            if (marketData.getBidPrice() != null) {
                                marketData.getMidPrice();
                            }
                        } else {
                            // Small pause if no message available
                            try {
                                Thread.sleep(1);
                            } catch (InterruptedException e) {
                                Thread.currentThread().interrupt();
                                break;
                            }
                        }
                    }
                    
                    long duration = System.nanoTime() - startTime;
                    log.info("Consumer completed:");
                    log.info("  Messages: {}", messagesConsumed.get());
                    log.info("  Duration: {} ms", duration / 1_000_000);
                    log.info("  Throughput: {} messages/sec", (messagesConsumed.get() * 1_000_000_000L) / duration);
                    
                } finally {
                    consumerLatch.countDown();
                }
            });
            
            // Start both threads
            consumer.start();
            Thread.sleep(100); // Give consumer a head start
            producer.start();
            
            // Wait for completion
            producerLatch.await();
            consumerLatch.await();
            
            log.info("Producer-Consumer Results:");
            log.info("  Messages produced: {}", messagesProduced.get());
            log.info("  Messages consumed: {}", messagesConsumed.get());
        }
    }
    
    /**
     * High throughput demonstration
     */
    public void highThroughputDemo() {
        log.info("\n--- High Throughput Demo ---");
        
        try (ChronicleQueue queue = SingleChronicleQueueBuilder.single(QUEUE_DIR + "/high-throughput")
                .build()) {
            
            int messageCount = 1_000_000;
            
            // Write test
            log.info("Testing write throughput...");
            long writeStartTime = System.nanoTime();
            
            try (ExcerptAppender appender = queue.acquireAppender()) {
                for (int i = 1; i <= messageCount; i++) {
                    Trade trade = DataGenerator.generateTrade((long) i, "HFT_" + (i % 1000));
                    appender.writeDocument(trade);
                }
            }
            
            long writeDuration = System.nanoTime() - writeStartTime;
            
            log.info("Write Performance:");
            log.info("  Messages: {}", messageCount);
            log.info("  Duration: {} ms", writeDuration / 1_000_000);
            log.info("  Throughput: {} messages/sec", (messageCount * 1_000_000_000L) / writeDuration);
            log.info("  Average latency: {} nanoseconds", writeDuration / messageCount);
            
            // Read test
            log.info("Testing read throughput...");
            long readStartTime = System.nanoTime();
            int readCount = 0;
            
            try (ExcerptTailer tailer = queue.createTailer("throughput-consumer")) {
                Trade trade = new Trade();
                while (tailer.readDocument(trade)) {
                    readCount++;
                    // Simulate minimal processing
                    if (trade.getPrice() != null) {
                        trade.getNotionalValue();
                    }
                }
            }
            
            long readDuration = System.nanoTime() - readStartTime;
            
            log.info("Read Performance:");
            log.info("  Messages: {}", readCount);
            log.info("  Duration: {} ms", readDuration / 1_000_000);
            log.info("  Throughput: {} messages/sec", (readCount * 1_000_000_000L) / readDuration);
            log.info("  Average latency: {} nanoseconds", readDuration / readCount);
        }
    }
    
    /**
     * Persistence demonstration
     */
    public void persistenceDemo() {
        log.info("\n--- Persistence Demo ---");
        
        File queueDir = new File(QUEUE_DIR + "/persistent");
        
        // First session - write data
        log.info("Writing data to persistent queue...");
        try (ChronicleQueue queue = SingleChronicleQueueBuilder.single(queueDir.getPath())
                .build()) {
            
            try (ExcerptAppender appender = queue.acquireAppender()) {
                for (int i = 1; i <= 1000; i++) {
                    Trade trade = DataGenerator.generateTrade((long) i, "PERSIST_" + i);
                    appender.writeDocument(trade);
                }
            }
            
            log.info("Wrote 1000 trades to persistent queue");
        }
        
        // Second session - read data
        log.info("Reading data from persistent queue...");
        try (ChronicleQueue queue = SingleChronicleQueueBuilder.single(queueDir.getPath())
                .build()) {
            
            int readCount = 0;
            try (ExcerptTailer tailer = queue.createTailer("persistent-consumer")) {
                Trade trade = new Trade();
                while (tailer.readDocument(trade)) {
                    readCount++;
                }
            }
            
            log.info("Read {} trades from persistent queue", readCount);
        }
        
        // Calculate directory size
        long totalSize = calculateDirectorySize(queueDir);
        log.info("Queue directory size: {} KB", totalSize / 1024);
    }
    
    /**
     * Multiple consumers demonstration
     */
    public void multipleConsumersDemo() throws InterruptedException {
        log.info("\n--- Multiple Consumers Demo ---");
        
        try (ChronicleQueue queue = SingleChronicleQueueBuilder.single(QUEUE_DIR + "/multi-consumer")
                .build()) {
            
            int messageCount = 10_000;
            int consumerCount = 3;
            CountDownLatch producerLatch = new CountDownLatch(1);
            CountDownLatch consumerLatch = new CountDownLatch(consumerCount);
            AtomicLong totalMessagesConsumed = new AtomicLong();
            
            // Producer
            Thread producer = new Thread(() -> {
                try (ExcerptAppender appender = queue.acquireAppender()) {
                    for (int i = 1; i <= messageCount; i++) {
                        MarketData data = DataGenerator.generateMarketData("MULTI_" + (i % 50));
                        appender.writeDocument(data);
                    }
                    log.info("Producer wrote {} messages", messageCount);
                } finally {
                    producerLatch.countDown();
                }
            });
            
            // Multiple consumers with different tailer names
            Thread[] consumers = new Thread[consumerCount];
            AtomicLong[] consumerCounts = new AtomicLong[consumerCount];
            
            for (int c = 0; c < consumerCount; c++) {
                consumerCounts[c] = new AtomicLong();
                final int consumerId = c;
                
                consumers[c] = new Thread(() -> {
                    try (ExcerptTailer tailer = queue.createTailer("consumer-" + consumerId)) {
                        MarketData data = new MarketData();
                        long messagesRead = 0;
                        
                        // Each consumer reads until no more messages for a while
                        int emptyReads = 0;
                        while (emptyReads < 100) { // Stop after 100 consecutive empty reads
                            if (tailer.readDocument(data)) {
                                messagesRead++;
                                emptyReads = 0;
                                // Simulate processing
                                if (data.getBidPrice() != null) {
                                    data.getSpread();
                                }
                            } else {
                                emptyReads++;
                                try {
                                    Thread.sleep(1);
                                } catch (InterruptedException e) {
                                    Thread.currentThread().interrupt();
                                    break;
                                }
                            }
                        }
                        
                        consumerCounts[consumerId].set(messagesRead);
                        totalMessagesConsumed.addAndGet(messagesRead);
                        log.info("Consumer {} read {} messages", consumerId, messagesRead);
                        
                    } finally {
                        consumerLatch.countDown();
                    }
                });
            }
            
            // Start producer and consumers
            producer.start();
            for (Thread consumer : consumers) {
                consumer.start();
            }
            
            // Wait for completion
            producerLatch.await();
            consumerLatch.await();
            
            log.info("Multiple Consumers Results:");
            log.info("  Messages produced: {}", messageCount);
            log.info("  Total messages consumed: {}", totalMessagesConsumed.get());
            for (int i = 0; i < consumerCount; i++) {
                log.info("  Consumer {} read: {}", i, consumerCounts[i].get());
            }
        }
    }
    
    private long calculateDirectorySize(File directory) {
        long size = 0;
        if (directory.exists()) {
            File[] files = directory.listFiles();
            if (files != null) {
                for (File file : files) {
                    if (file.isFile()) {
                        size += file.length();
                    } else if (file.isDirectory()) {
                        size += calculateDirectorySize(file);
                    }
                }
            }
        }
        return size;
    }
}