package com.demo.map;

import com.demo.model.User;
import com.demo.model.MarketData;
import com.demo.util.DataGenerator;
import lombok.extern.slf4j.Slf4j;
import net.openhft.chronicle.map.ChronicleMap;

import java.io.File;
import java.io.IOException;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.concurrent.ThreadLocalRandom;

/**
 * Chronicle Map demonstration showing various features and performance characteristics
 */
@Slf4j
public class ChronicleMapDemo {
    
    private static final String DATA_DIR = "chronicle-demo-data";
    private static final int INITIAL_CAPACITY = 1_000_000;
    
    public static void main(String[] args) {
        log.info("Starting Chronicle Map Performance Demo");
        log.info("==========================================");
        
        ChronicleMapDemo demo = new ChronicleMapDemo();
        
        try {
            // Create data directory
            new File(DATA_DIR).mkdirs();
            
            // Run different demos
            demo.basicUsageDemo();
            demo.performanceDemo();
            demo.persistenceDemo();
            demo.concurrencyDemo();
            demo.memoryEfficiencyDemo();
            
        } catch (Exception e) {
            log.error("Demo failed", e);
        }
        
        log.info("Chronicle Map Demo completed");
    }
    
    /**
     * Basic usage demonstration
     */
    public void basicUsageDemo() throws IOException {
        log.info("\n--- Basic Usage Demo ---");
        
        // Create Chronicle Map for User objects
        try (ChronicleMap<Long, User> userMap = ChronicleMap
                .of(Long.class, User.class)
                .entries(10_000)
                .averageValueSize(256)
                .createPersistedTo(new File(DATA_DIR, "users.dat"))) {
            
            // Create and store users
            for (int i = 1; i <= 1000; i++) {
                User user = DataGenerator.generateUser((long) i);
                userMap.put(user.getUserId(), user);
            }
            
            log.info("Created {} users", userMap.size());
            
            // Retrieve and display some users
            User user1 = userMap.get(1L);
            User user500 = userMap.get(500L);
            
            log.info("User 1: {}", user1.getFullName());
            log.info("User 500: {}", user500.getFullName());
            
            // Update user
            user1.setAccountBalance(user1.getAccountBalance() + 1000.0);
            userMap.put(user1.getUserId(), user1);
            
            log.info("Updated User 1 balance: ${}", user1.getAccountBalance());
            
            // Check existence
            log.info("User 999 exists: {}", userMap.containsKey(999L));
            log.info("User 2000 exists: {}", userMap.containsKey(2000L));
        }
    }
    
    /**
     * Performance benchmarking
     */
    public void performanceDemo() throws IOException {
        log.info("\n--- Performance Demo ---");
        
        try (ChronicleMap<String, MarketData> marketDataMap = ChronicleMap
                .of(String.class, MarketData.class)
                .entries(INITIAL_CAPACITY)
                .averageValueSize(200)
                .createPersistedTo(new File(DATA_DIR, "market-data.dat"))) {
            
            // Warm up
            warmUp(marketDataMap);
            
            // Write performance test
            testWritePerformance(marketDataMap);
            
            // Read performance test
            testReadPerformance(marketDataMap);
            
            // Update performance test
            testUpdatePerformance(marketDataMap);
        }
    }
    
    private void warmUp(ChronicleMap<String, MarketData> marketDataMap) {
        log.info("Warming up JVM...");
        for (int i = 0; i < 10_000; i++) {
            MarketData data = DataGenerator.generateMarketData("WARMUP");
            marketDataMap.put("WARMUP_" + i, data);
        }
        log.info("Warmup completed");
    }
    
    private void testWritePerformance(ChronicleMap<String, MarketData> marketDataMap) {
        log.info("Testing write performance...");
        
        int recordCount = 100_000;
        long startTime = System.nanoTime();
        
        for (int i = 0; i < recordCount; i++) {
            String symbol = "STOCK_" + (i % 1000); // 1000 different symbols
            MarketData data = DataGenerator.generateMarketData(symbol);
            marketDataMap.put(symbol + "_" + i, data);
        }
        
        long duration = System.nanoTime() - startTime;
        
        log.info("Write Performance Results:");
        log.info("  Records: {}", recordCount);
        log.info("  Duration: {} ms", duration / 1_000_000);
        log.info("  Throughput: {} writes/sec", (recordCount * 1_000_000_000L) / duration);
        log.info("  Average latency: {} nanoseconds", duration / recordCount);
        log.info("  Map size: {}", marketDataMap.size());
    }
    
    private void testReadPerformance(ChronicleMap<String, MarketData> marketDataMap) {
        log.info("Testing read performance...");
        
        int readCount = 100_000;
        long startTime = System.nanoTime();
        
        // Random reads
        for (int i = 0; i < readCount; i++) {
            int randomId = ThreadLocalRandom.current().nextInt(100_000);
            String key = "STOCK_" + (randomId % 1000) + "_" + randomId;
            MarketData data = marketDataMap.get(key);
            // Simulate some processing
            if (data != null) {
                BigDecimal midPrice = data.getMidPrice();
            }
        }
        
        long duration = System.nanoTime() - startTime;
        
        log.info("Read Performance Results:");
        log.info("  Reads: {}", readCount);
        log.info("  Duration: {} ms", duration / 1_000_000);
        log.info("  Throughput: {} reads/sec", (readCount * 1_000_000_000L) / duration);
        log.info("  Average latency: {} nanoseconds", duration / readCount);
    }
    
    private void testUpdatePerformance(ChronicleMap<String, MarketData> marketDataMap) {
        log.info("Testing update performance...");
        
        int updateCount = 50_000;
        long startTime = System.nanoTime();
        
        for (int i = 0; i < updateCount; i++) {
            int randomId = ThreadLocalRandom.current().nextInt(100_000);
            String key = "STOCK_" + (randomId % 1000) + "_" + randomId;
            MarketData data = marketDataMap.get(key);
            
            if (data != null) {
                // Update prices
                data.setBidPrice(data.getBidPrice().add(BigDecimal.valueOf(0.01)));
                data.setAskPrice(data.getAskPrice().add(BigDecimal.valueOf(0.01)));
                data.setTimestamp(LocalDateTime.now());
                
                marketDataMap.put(key, data);
            }
        }
        
        long duration = System.nanoTime() - startTime;
        
        log.info("Update Performance Results:");
        log.info("  Updates: {}", updateCount);
        log.info("  Duration: {} ms", duration / 1_000_000);
        log.info("  Throughput: {} updates/sec", (updateCount * 1_000_000_000L) / duration);
        log.info("  Average latency: {} nanoseconds", duration / updateCount);
    }
    
    /**
     * Persistence demonstration
     */
    public void persistenceDemo() throws IOException {
        log.info("\n--- Persistence Demo ---");
        
        File persistentFile = new File(DATA_DIR, "persistent-demo.dat");
        
        // First session - write data
        log.info("Creating persistent map and writing data...");
        try (ChronicleMap<Long, User> userMap = ChronicleMap
                .of(Long.class, User.class)
                .entries(1000)
                .createPersistedTo(persistentFile)) {
            
            for (int i = 1; i <= 100; i++) {
                User user = DataGenerator.generateUser((long) i);
                userMap.put(user.getUserId(), user);
            }
            
            log.info("Wrote {} users to persistent storage", userMap.size());
        }
        
        // Second session - read data
        log.info("Reading data from persistent storage...");
        try (ChronicleMap<Long, User> userMap = ChronicleMap
                .of(Long.class, User.class)
                .entries(1000)
                .createPersistedTo(persistentFile)) {
            
            log.info("Read {} users from persistent storage", userMap.size());
            
            // Verify data integrity
            User user50 = userMap.get(50L);
            log.info("User 50: {} - Balance: ${}", user50.getFullName(), user50.getAccountBalance());
        }
        
        log.info("File size: {} KB", persistentFile.length() / 1024);
    }
    
    /**
     * Concurrency demonstration
     */
    public void concurrencyDemo() throws IOException, InterruptedException {
        log.info("\n--- Concurrency Demo ---");
        
        try (ChronicleMap<String, Long> counterMap = ChronicleMap
                .of(String.class, Long.class)
                .entries(1000)
                .createPersistedTo(new File(DATA_DIR, "counters.dat"))) {
            
            // Initialize counters
            for (int i = 0; i < 10; i++) {
                counterMap.put("counter_" + i, 0L);
            }
            
            int threadCount = 10;
            int incrementsPerThread = 10_000;
            Thread[] threads = new Thread[threadCount];
            
            long startTime = System.nanoTime();
            
            // Create threads that increment counters concurrently
            for (int t = 0; t < threadCount; t++) {
                final int threadId = t;
                threads[t] = new Thread(() -> {
                    for (int i = 0; i < incrementsPerThread; i++) {
                        String key = "counter_" + (i % 10);
                        counterMap.compute(key, (k, v) -> v + 1);
                    }
                });
                threads[t].start();
            }
            
            // Wait for all threads to complete
            for (Thread thread : threads) {
                thread.join();
            }
            
            long duration = System.nanoTime() - startTime;
            
            // Verify results
            long totalIncrements = 0;
            for (int i = 0; i < 10; i++) {
                Long count = counterMap.get("counter_" + i);
                totalIncrements += count;
                log.info("Counter {}: {}", i, count);
            }
            
            log.info("Concurrency Results:");
            log.info("  Threads: {}", threadCount);
            log.info("  Total increments: {}", totalIncrements);
            log.info("  Expected: {}", threadCount * incrementsPerThread);
            log.info("  Duration: {} ms", duration / 1_000_000);
            log.info("  Throughput: {} operations/sec", (totalIncrements * 1_000_000_000L) / duration);
        }
    }
    
    /**
     * Memory efficiency demonstration
     */
    public void memoryEfficiencyDemo() throws IOException {
        log.info("\n--- Memory Efficiency Demo ---");
        
        Runtime runtime = Runtime.getRuntime();
        long memoryBefore = runtime.totalMemory() - runtime.freeMemory();
        
        try (ChronicleMap<Long, User> userMap = ChronicleMap
                .of(Long.class, User.class)
                .entries(100_000)
                .averageValueSize(256)
                .createPersistedTo(new File(DATA_DIR, "memory-test.dat"))) {
            
            // Add 50,000 users
            int userCount = 50_000;
            for (int i = 1; i <= userCount; i++) {
                User user = DataGenerator.generateUser((long) i);
                userMap.put(user.getUserId(), user);
            }
            
            long memoryAfter = runtime.totalMemory() - runtime.freeMemory();
            long memoryUsed = memoryAfter - memoryBefore;
            
            log.info("Memory Efficiency Results:");
            log.info("  Users stored: {}", userCount);
            log.info("  Heap memory used: {} MB", memoryUsed / 1024 / 1024);
            log.info("  Memory per user: {} bytes", memoryUsed / userCount);
            log.info("  File size: {} MB", new File(DATA_DIR, "memory-test.dat").length() / 1024 / 1024);
            
            // Force GC and measure again
            System.gc();
            Thread.sleep(100);
            long memoryAfterGc = runtime.totalMemory() - runtime.freeMemory();
            
            log.info("  Memory after GC: {} MB", (memoryAfterGc - memoryBefore) / 1024 / 1024);
            log.info("  Off-heap storage: Chronicle Map uses memory-mapped files");
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}