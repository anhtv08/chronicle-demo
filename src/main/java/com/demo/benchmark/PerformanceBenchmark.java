package com.demo.benchmark;

import com.demo.model.User;
import com.demo.model.MarketData;
import com.demo.util.DataGenerator;
import lombok.extern.slf4j.Slf4j;
import net.openhft.chronicle.map.ChronicleMap;
import net.openhft.chronicle.queue.ChronicleQueue;
import net.openhft.chronicle.queue.ExcerptAppender;
import net.openhft.chronicle.queue.ExcerptTailer;
import net.openhft.chronicle.queue.impl.single.SingleChronicleQueueBuilder;

import java.io.File;
import java.io.IOException;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.ThreadLocalRandom;

/**
 * Comprehensive performance comparison between Chronicle and standard Java collections
 */
@Slf4j
public class PerformanceBenchmark {
    
    private static final String DATA_DIR = "chronicle-demo-data/benchmark";
    private static final int WARM_UP_ITERATIONS = 10_000;
    private static final int BENCHMARK_ITERATIONS = 100_000;
    
    public static void main(String[] args) {
        log.info("Chronicle vs Standard Java Collections - Performance Benchmark");
        log.info("================================================================");
        
        PerformanceBenchmark benchmark = new PerformanceBenchmark();
        
        try {
            new File(DATA_DIR).mkdirs();
            
            // Run benchmarks
            benchmark.mapPerformanceComparison();
            benchmark.queuePerformanceComparison();
            benchmark.memoryUsageComparison();
            benchmark.persistenceComparison();
            
        } catch (Exception e) {
            log.error("Benchmark failed", e);
        }
        
        log.info("Performance Benchmark completed");
    }
    
    /**
     * Compare Chronicle Map vs ConcurrentHashMap performance
     */
    public void mapPerformanceComparison() throws IOException {
        log.info("\n=== Map Performance Comparison ===");
        
        // Benchmark Chronicle Map
        BenchmarkResult chronicleResult = benchmarkChronicleMap();
        
        // Benchmark ConcurrentHashMap
        BenchmarkResult concurrentHashMapResult = benchmarkConcurrentHashMap();
        
        // Compare results
        log.info("\nMap Performance Comparison Results:");
        log.info("-----------------------------------");
        
        log.info("Chronicle Map:");
        logBenchmarkResult(chronicleResult);
        
        log.info("\nConcurrentHashMap:");
        logBenchmarkResult(concurrentHashMapResult);
        
        log.info("\nPerformance Ratio (Chronicle/Standard):");
        log.info("  Write: {:.2f}x", (double) concurrentHashMapResult.writeOps / chronicleResult.writeOps);
        log.info("  Read: {:.2f}x", (double) concurrentHashMapResult.readOps / chronicleResult.readOps);
        log.info("  Memory: {:.2f}x", (double) concurrentHashMapResult.memoryUsed / chronicleResult.memoryUsed);
    }
    
    private BenchmarkResult benchmarkChronicleMap() throws IOException {
        log.info("Benchmarking Chronicle Map...");
        
        try (ChronicleMap<Long, User> map = ChronicleMap
                .of(Long.class, User.class)
                .entries(BENCHMARK_ITERATIONS * 2)
                .averageValueSize(256)
                .createPersistedTo(new File(DATA_DIR, "chronicle-map-benchmark.dat"))) {
            
            return runMapBenchmark(
                (key, user) -> map.put(key, user),
                key -> map.get(key),
                () -> map.size()
            );
        }
    }
    
    private BenchmarkResult benchmarkConcurrentHashMap() {
        log.info("Benchmarking ConcurrentHashMap...");
        
        ConcurrentHashMap<Long, User> map = new ConcurrentHashMap<>(BENCHMARK_ITERATIONS * 2);
        
        return runMapBenchmark(
            (key, user) -> map.put(key, user),
            key -> map.get(key),
            () -> map.size()
        );
    }
    
    private BenchmarkResult runMapBenchmark(MapWriter<Long, User> writer, 
                                           MapReader<Long, User> reader,
                                           SizeProvider sizeProvider) {
        Runtime runtime = Runtime.getRuntime();
        
        // Warm up
        for (int i = 0; i < WARM_UP_ITERATIONS; i++) {
            User user = DataGenerator.generateUser((long) i);
            writer.put((long) i, user);
        }
        
        // Clear for accurate memory measurement
        System.gc();
        long memoryBefore = runtime.totalMemory() - runtime.freeMemory();
        
        // Write benchmark
        long writeStart = System.nanoTime();
        for (int i = 0; i < BENCHMARK_ITERATIONS; i++) {
            User user = DataGenerator.generateUser((long) i);
            writer.put((long) i, user);
        }
        long writeEnd = System.nanoTime();
        long writeDuration = writeEnd - writeStart;
        
        // Read benchmark
        long readStart = System.nanoTime();
        for (int i = 0; i < BENCHMARK_ITERATIONS; i++) {
            long key = ThreadLocalRandom.current().nextLong(BENCHMARK_ITERATIONS);
            User user = reader.get(key);
            // Simulate processing
            if (user != null) {
                user.getFullName();
            }
        }
        long readEnd = System.nanoTime();
        long readDuration = readEnd - readStart;
        
        // Memory measurement
        System.gc();
        long memoryAfter = runtime.totalMemory() - runtime.freeMemory();
        long memoryUsed = memoryAfter - memoryBefore;
        
        return BenchmarkResult.builder()
                .writeOps((BENCHMARK_ITERATIONS * 1_000_000_000L) / writeDuration)
                .readOps((BENCHMARK_ITERATIONS * 1_000_000_000L) / readDuration)
                .writeDuration(writeDuration)
                .readDuration(readDuration)
                .memoryUsed(memoryUsed)
                .finalSize(sizeProvider.getSize())
                .build();
    }
    
    /**
     * Compare Chronicle Queue vs LinkedBlockingQueue performance
     */
    public void queuePerformanceComparison() {
        log.info("\n=== Queue Performance Comparison ===");
        
        // Benchmark Chronicle Queue
        BenchmarkResult chronicleResult = benchmarkChronicleQueue();
        
        // Benchmark LinkedBlockingQueue
        BenchmarkResult linkedBlockingQueueResult = benchmarkLinkedBlockingQueue();
        
        // Compare results
        log.info("\nQueue Performance Comparison Results:");
        log.info("------------------------------------");
        
        log.info("Chronicle Queue:");
        logBenchmarkResult(chronicleResult);
        
        log.info("\nLinkedBlockingQueue:");
        logBenchmarkResult(linkedBlockingQueueResult);
        
        log.info("\nPerformance Ratio (Chronicle/Standard):");
        log.info("  Write: {:.2f}x", (double) linkedBlockingQueueResult.writeOps / chronicleResult.writeOps);
        log.info("  Read: {:.2f}x", (double) linkedBlockingQueueResult.readOps / chronicleResult.readOps);
        log.info("  Memory: {:.2f}x", (double) linkedBlockingQueueResult.memoryUsed / chronicleResult.memoryUsed);
    }
    
    private BenchmarkResult benchmarkChronicleQueue() {
        log.info("Benchmarking Chronicle Queue...");
        
        try (ChronicleQueue queue = SingleChronicleQueueBuilder.single(DATA_DIR + "/chronicle-queue-benchmark")
                .build()) {
            
            return runQueueBenchmark(
                marketData -> {
                    try (ExcerptAppender appender = queue.acquireAppender()) {
                        appender.writeDocument(marketData);
                    }
                },
                () -> {
                    try (ExcerptTailer tailer = queue.createTailer("benchmark-consumer")) {
                        MarketData data = new MarketData();
                        return tailer.readDocument(data) ? data : null;
                    }
                }
            );
        }
    }
    
    private BenchmarkResult benchmarkLinkedBlockingQueue() {
        log.info("Benchmarking LinkedBlockingQueue...");
        
        LinkedBlockingQueue<MarketData> queue = new LinkedBlockingQueue<>();
        
        return runQueueBenchmark(
            marketData -> {
                try {
                    queue.put(marketData);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            },
            () -> queue.poll()
        );
    }
    
    private BenchmarkResult runQueueBenchmark(QueueWriter<MarketData> writer,
                                            QueueReader<MarketData> reader) {
        Runtime runtime = Runtime.getRuntime();
        
        // Warm up
        for (int i = 0; i < WARM_UP_ITERATIONS; i++) {
            MarketData data = DataGenerator.generateMarketData("WARMUP");
            writer.write(data);
        }
        
        // Clear for accurate memory measurement
        System.gc();
        long memoryBefore = runtime.totalMemory() - runtime.freeMemory();
        
        // Write benchmark
        long writeStart = System.nanoTime();
        for (int i = 0; i < BENCHMARK_ITERATIONS; i++) {
            MarketData data = DataGenerator.generateMarketData("BENCH_" + (i % 100));
            writer.write(data);
        }
        long writeEnd = System.nanoTime();
        long writeDuration = writeEnd - writeStart;
        
        // Read benchmark
        long readStart = System.nanoTime();
        int readCount = 0;
        while (readCount < BENCHMARK_ITERATIONS) {
            MarketData data = reader.read();
            if (data != null) {
                readCount++;
                // Simulate processing
                data.getMidPrice();
            }
        }
        long readEnd = System.nanoTime();
        long readDuration = readEnd - readStart;
        
        // Memory measurement
        System.gc();
        long memoryAfter = runtime.totalMemory() - runtime.freeMemory();
        long memoryUsed = memoryAfter - memoryBefore;
        
        return BenchmarkResult.builder()
                .writeOps((BENCHMARK_ITERATIONS * 1_000_000_000L) / writeDuration)
                .readOps((readCount * 1_000_000_000L) / readDuration)
                .writeDuration(writeDuration)
                .readDuration(readDuration)
                .memoryUsed(memoryUsed)
                .finalSize(readCount)
                .build();
    }
    
    /**
     * Compare memory usage between Chronicle and standard collections
     */
    public void memoryUsageComparison() throws IOException {
        log.info("\n=== Memory Usage Comparison ===");
        
        int testSize = 100_000;
        Runtime runtime = Runtime.getRuntime();
        
        // Test Chronicle Map memory usage
        System.gc();
        long beforeChronicle = runtime.totalMemory() - runtime.freeMemory();
        long chronicleMemory;
        
        try (ChronicleMap<Long, User> chronicleMap = ChronicleMap
                .of(Long.class, User.class)
                .entries(testSize)
                .averageValueSize(256)
                .createPersistedTo(new File(DATA_DIR, "memory-test-chronicle.dat"))) {
            
            for (int i = 0; i < testSize; i++) {
                chronicleMap.put((long) i, DataGenerator.generateUser((long) i));
            }
            
            System.gc();
            long afterChronicle = runtime.totalMemory() - runtime.freeMemory();
            chronicleMemory = afterChronicle - beforeChronicle;
            
            log.info("Chronicle Map Memory Usage:");
            log.info("  Objects: {}", testSize);
            log.info("  Heap Memory: {} MB", chronicleMemory / 1024 / 1024);
            log.info("  Memory per object: {} bytes", chronicleMemory / testSize);
            log.info("  File size: {} MB", new File(DATA_DIR, "memory-test-chronicle.dat").length() / 1024 / 1024);
        }
        
        // Test ConcurrentHashMap memory usage
        System.gc();
        long beforeConcurrent = runtime.totalMemory() - runtime.freeMemory();
        
        ConcurrentHashMap<Long, User> concurrentMap = new ConcurrentHashMap<>(testSize);
        for (int i = 0; i < testSize; i++) {
            concurrentMap.put((long) i, DataGenerator.generateUser((long) i));
        }
        
        System.gc();
        long afterConcurrent = runtime.totalMemory() - runtime.freeMemory();
        long concurrentMemory = afterConcurrent - beforeConcurrent;
        
        log.info("\nConcurrentHashMap Memory Usage:");
        log.info("  Objects: {}", testSize);
        log.info("  Heap Memory: {} MB", concurrentMemory / 1024 / 1024);
        log.info("  Memory per object: {} bytes", concurrentMemory / testSize);
        
        log.info("\nMemory Efficiency:");
        log.info("  Chronicle uses {:.1f}x {} heap memory than ConcurrentHashMap", 
            concurrentMemory > chronicleMemory ? 
                (double) concurrentMemory / chronicleMemory : 
                (double) chronicleMemory / concurrentMemory,
            concurrentMemory > chronicleMemory ? "less" : "more");
    }
    
    /**
     * Compare persistence capabilities
     */
    public void persistenceComparison() throws IOException {
        log.info("\n=== Persistence Comparison ===");
        
        int testSize = 10_000;
        
        // Chronicle Map persistence test
        File chronicleFile = new File(DATA_DIR, "persistence-chronicle.dat");
        long chronicleWriteTime = System.nanoTime();
        
        // Write data with Chronicle Map
        try (ChronicleMap<Long, User> map = ChronicleMap
                .of(Long.class, User.class)
                .entries(testSize)
                .createPersistedTo(chronicleFile)) {
            
            for (int i = 0; i < testSize; i++) {
                map.put((long) i, DataGenerator.generateUser((long) i));
            }
        }
        chronicleWriteTime = System.nanoTime() - chronicleWriteTime;
        
        // Read data with Chronicle Map
        long chronicleReadTime = System.nanoTime();
        int chronicleReadCount = 0;
        try (ChronicleMap<Long, User> map = ChronicleMap
                .of(Long.class, User.class)
                .entries(testSize)
                .createPersistedTo(chronicleFile)) {
            
            for (long i = 0; i < testSize; i++) {
                User user = map.get(i);
                if (user != null) {
                    chronicleReadCount++;
                }
            }
        }
        chronicleReadTime = System.nanoTime() - chronicleReadTime;
        
        log.info("Chronicle Map Persistence:");
        log.info("  Write time: {} ms", chronicleWriteTime / 1_000_000);
        log.info("  Read time: {} ms", chronicleReadTime / 1_000_000);
        log.info("  Objects read: {}", chronicleReadCount);
        log.info("  File size: {} KB", chronicleFile.length() / 1024);
        log.info("  Automatic persistence: YES");
        log.info("  Memory-mapped: YES");
        
        log.info("\nStandard Collections Persistence:");
        log.info("  Built-in persistence: NO");
        log.info("  Requires serialization: YES");
        log.info("  Memory-mapped files: NO");
        log.info("  Automatic recovery: NO");
    }
    
    private void logBenchmarkResult(BenchmarkResult result) {
        log.info("  Write throughput: {} ops/sec", result.writeOps);
        log.info("  Read throughput: {} ops/sec", result.readOps);
        log.info("  Write duration: {} ms", result.writeDuration / 1_000_000);
        log.info("  Read duration: {} ms", result.readDuration / 1_000_000);
        log.info("  Memory used: {} MB", result.memoryUsed / 1024 / 1024);
        log.info("  Final size: {}", result.finalSize);
    }
    
    // Functional interfaces for benchmarking
    @FunctionalInterface
    interface MapWriter<K, V> {
        void put(K key, V value);
    }
    
    @FunctionalInterface
    interface MapReader<K, V> {
        V get(K key);
    }
    
    @FunctionalInterface
    interface SizeProvider {
        int getSize();
    }
    
    @FunctionalInterface
    interface QueueWriter<T> {
        void write(T item);
    }
    
    @FunctionalInterface
    interface QueueReader<T> {
        T read();
    }
    
    // Result holder
    @lombok.Data
    @lombok.Builder
    private static class BenchmarkResult {
        private long writeOps;
        private long readOps;
        private long writeDuration;
        private long readDuration;
        private long memoryUsed;
        private int finalSize;
    }
}